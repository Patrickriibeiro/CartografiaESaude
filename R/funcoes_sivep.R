# Funções do SIVEP-Gripe: download, preparo e classificação por agente.

# Os 34 campos documentados em docs/dicionario-sivep.md, com os nomes REAIS dos
# bancos PARQUET (conferidos em 2026-09-25 nos 4 anos: 194 colunas, mesmos nomes).
COLUNAS_SIVEP <- c(
  # tempo
  "DT_NOTIFIC", "SEM_NOT", "DT_SIN_PRI", "SEM_PRI", "DT_ENCERRA", "DT_DIGITA",
  # lugar
  "SG_UF_NOT", "CO_MUN_NOT", "SG_UF", "CO_MUN_RES", "CO_MU_INTE",
  # pessoa e internação
  "CS_SEXO", "NU_IDADE_N", "TP_IDADE", "HOSPITAL", "DT_INTERNA",
  # antígeno
  "TP_TES_AN", "RES_AN", "POS_AN_FLU", "TP_FLU_AN", "POS_AN_OUT", "AN_SARS2", "AN_VSR",
  # RT-PCR
  "PCR_RESUL", "POS_PCRFLU", "TP_FLU_PCR", "POS_PCROUT", "PCR_SARS2", "PCR_VSR",
  # classificação e desfecho
  "CO_DETEC", "CLASSI_FIN", "CRITERIO", "EVOLUCAO", "DT_EVOLUCA"
)

# Datas vêm como timestamp à meia-noite UTC. Lidas no fuso de Brasília, caem às
# 21h do dia anterior: por isso a conversão é sempre com tz = "UTC".
COLUNAS_DATA_SIVEP <- c("DT_NOTIFIC", "DT_SIN_PRI", "DT_ENCERRA", "DT_DIGITA",
                        "DT_INTERNA", "DT_EVOLUCA")

# Campos de código numérico (1, 2, 9...). Vazio ou NA vira NA; o significado do
# vazio (não marcado × não encerrado) é decidido na classificação (ADR-0002).
COLUNAS_CODIGO_SIVEP <- c(
  "NU_IDADE_N", "TP_IDADE", "HOSPITAL", "TP_TES_AN", "RES_AN", "POS_AN_FLU",
  "TP_FLU_AN", "POS_AN_OUT", "AN_SARS2", "AN_VSR", "PCR_RESUL", "POS_PCRFLU",
  "TP_FLU_PCR", "POS_PCROUT", "PCR_SARS2", "PCR_VSR", "CO_DETEC", "CLASSI_FIN",
  "CRITERIO", "EVOLUCAO"
)

#' Baixa o dicionário de dados oficial do SIVEP-Gripe (CS-004) e o registra no
#' manifesto. Segunda chamada não rebaixa: confere o hash e sai.
obter_dicionario_sivep <- function(fontes = ler_fontes()) {
  d <- fontes$sivep$dicionario
  baixar_e_registrar(d$url, d$destino, descricao = d$descricao, versao = d$versao)
}

#' Tabela dos bancos anuais configurados em config/fontes.yml, com o caminho
#' local de cada um (dados/brutos/<nome original do arquivo>).
bancos_sivep <- function(anos = NULL, fontes = ler_fontes()) {
  b <- do.call(rbind, lapply(fontes$sivep$bancos, function(x) {
    data.frame(ano = as.integer(x$ano), url = x$url, versao = x$versao,
               stringsAsFactors = FALSE)
  }))
  b$destino <- file.path("dados", "brutos", basename(b$url))
  if (!is.null(anos)) {
    faltam <- setdiff(anos, b$ano)
    if (length(faltam) > 0) {
      stop("Ano sem banco em config/fontes.yml: ", paste(faltam, collapse = ", "),
           call. = FALSE)
    }
    b <- b[b$ano %in% anos, , drop = FALSE]
  }
  b[order(b$ano), , drop = FALSE]
}

#' Baixa os bancos anuais do SIVEP-Gripe (CS-005) e registra cada um no manifesto.
#'
#' Download HTTP direto do Portal de Dados Abertos do SUS. NÃO usa `microdatasus`,
#' que não cobre o SIVEP-Gripe (ADR-0001). Arquivo já baixado e conferido não é
#' baixado de novo.
baixar_sivep <- function(anos = ANOS_ESTUDO, fontes = ler_fontes()) {
  b <- bancos_sivep(anos, fontes)
  for (i in seq_len(nrow(b))) {
    message(sprintf("SIVEP %d (versão %s)", b$ano[i], b$versao[i]))
    baixar_e_registrar(
      b$url[i], b$destino[i],
      descricao = sprintf("SIVEP-Gripe, SRAG hospitalizado, banco %d (PARQUET)", b$ano[i]),
      versao = b$versao[i]
    )
  }
  invisible(b$destino)
}

#' Converte um campo de código para inteiro, falhando se algum valor não for
#' número. Sem isso, um "X" inesperado viraria NA em silêncio e se confundiria
#' com "não preenchido".
para_inteiro <- function(x, nome) {
  if (is.numeric(x)) {
    if (any(!is.na(x) & x != round(x))) stop("Valor não inteiro em ", nome, call. = FALSE)
    return(as.integer(x))
  }
  x <- trimws(as.character(x))
  x[x == ""] <- NA_character_
  y <- suppressWarnings(as.integer(x))
  ruins <- unique(x[!is.na(x) & is.na(y)])
  if (length(ruins) > 0) {
    stop("Valores não numéricos em ", nome, ": ",
         paste(utils::head(ruins, 5), collapse = ", "), call. = FALSE)
  }
  y
}

#' Lê um banco anual, fica só com residentes do RJ e tipa as colunas (CS-006).
#'
#' - Confere o arquivo contra o manifesto ANTES de ler.
#' - Lê só as 34 colunas usadas, e o filtro do RJ é feito pelo arrow no disco,
#'   antes de trazer para a memória.
#' - Datas: timestamp UTC -> Date (tz = "UTC").
#' - Acrescenta ano_banco, ano_epi e semana_epi calculados de DT_SIN_PRI. O
#'   SEM_PRI original é mantido para conferência.
ler_banco_sivep_rj <- function(caminho, ano_banco, prefixo_uf = PREFIXO_UF_RJ) {
  verificar_manifesto(caminho)

  d <- arrow::open_dataset(caminho) |>
    dplyr::filter(substr(CO_MUN_RES, 1, 2) == prefixo_uf) |>
    dplyr::select(dplyr::all_of(COLUNAS_SIVEP)) |>
    dplyr::collect() |>
    as.data.frame()

  for (col in COLUNAS_DATA_SIVEP) d[[col]] <- as.Date(d[[col]], tz = "UTC")
  for (col in COLUNAS_CODIGO_SIVEP) d[[col]] <- para_inteiro(d[[col]], col)
  for (col in c("CO_MUN_RES", "CO_MUN_NOT", "CO_MU_INTE")) {
    d[[col]] <- as.character(d[[col]])
  }

  se <- semana_epidemiologica(d$DT_SIN_PRI)
  d$ano_banco <- as.integer(ano_banco)
  d$ano_epi <- se$ano_epi
  d$semana_epi <- se$semana_epi
  d$arquivo_origem <- basename(caminho)
  d
}

#' Lê os bancos configurados e devolve as fichas de SRAG de residentes do RJ.
#'
#' Para com erro se uma invariante do banco falhar (não há correção silenciosa):
#' - DT_SIN_PRI ausente;
#' - CO_MUN_RES fora do padrão de 6 dígitos com o prefixo da UF;
#' - SG_UF de residência diferente de RJ;
#' - ano epidemiológico do início dos sintomas diferente do ano do banco.
preparar_sivep <- function(anos = ANOS_ESTUDO, fontes = ler_fontes()) {
  b <- bancos_sivep(anos, fontes)
  partes <- vector("list", nrow(b))
  for (i in seq_len(nrow(b))) {
    t0 <- Sys.time()
    partes[[i]] <- ler_banco_sivep_rj(b$destino[i], b$ano[i])
    message(sprintf("SIVEP %d: %d fichas do RJ em %.1f s", b$ano[i],
                    nrow(partes[[i]]), as.numeric(Sys.time() - t0, units = "secs")))
  }
  d <- do.call(rbind, partes)

  if (anyNA(d$DT_SIN_PRI)) {
    stop(sum(is.na(d$DT_SIN_PRI)), " fichas sem DT_SIN_PRI", call. = FALSE)
  }
  padrao <- paste0("^", PREFIXO_UF_RJ, "[0-9]{4}$")
  if (!all(grepl(padrao, d$CO_MUN_RES))) {
    stop("CO_MUN_RES fora do padrão ", padrao, ": ",
         paste(utils::head(unique(d$CO_MUN_RES[!grepl(padrao, d$CO_MUN_RES)]), 5),
               collapse = ", "), call. = FALSE)
  }
  if (any(d$SG_UF != "RJ", na.rm = TRUE)) {
    stop(sum(d$SG_UF != "RJ", na.rm = TRUE), " fichas com CO_MUN_RES 33 e SG_UF != RJ",
         call. = FALSE)
  }
  fora <- d$ano_epi != d$ano_banco
  if (any(fora)) {
    stop(sum(fora), " fichas com ano epidemiológico diferente do ano do banco",
         call. = FALSE)
  }
  d
}

#' Conta, por ano, as anomalias que o preparo NÃO corrige, só registra.
diagnosticar_sivep <- function(d) {
  por_ano <- split(d, d$ano_banco)
  do.call(rbind, lapply(names(por_ano), function(a) {
    x <- por_ano[[a]]
    data.frame(
      ano = as.integer(a),
      fichas_rj = nrow(x),
      municipios_com_ficha = length(unique(x$CO_MUN_RES)),
      sem_pri_diverge = sum(as.integer(x$SEM_PRI) != x$semana_epi, na.rm = TRUE),
      sintomas_apos_digitacao = sum(x$DT_SIN_PRI > x$DT_DIGITA, na.rm = TRUE),
      classi_fin_vazio = sum(is.na(x$CLASSI_FIN)),
      residencia_diferente_notificacao = sum(x$CO_MUN_RES != x$CO_MUN_NOT, na.rm = TRUE)
    )
  }))
}

# A implementar:
# classificar_agente()         — CS-008
# aplicar_criterios_inclusao() — CS-008 (regra do ADR-0002)
