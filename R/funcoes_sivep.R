# Funções do SIVEP-Gripe: download, preparo e classificação por agente.

# Os 37 campos documentados em docs/dicionario-sivep.md, com os nomes REAIS dos
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
  # sorologia para SARS-CoV-2 (só para medir evidência laboratorial, ADR-0002)
  "RES_IGG", "RES_IGM", "RES_IGA",
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
  "TP_FLU_PCR", "POS_PCROUT", "PCR_SARS2", "PCR_VSR", "RES_IGG", "RES_IGM", "RES_IGA",
  "CO_DETEC", "CLASSI_FIN", "CRITERIO", "EVOLUCAO"
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
#' `recorte` escolhe quais fichas (CS-031):
#'   "residencia"          — residentes do RJ (o recorte do estudo);
#'   "notificacao_de_fora" — notificadas no RJ, de quem NÃO mora no RJ (ou sem
#'                           residência). É o complemento que falta para contar
#'                           por município de notificação sem perder quem vem
#'                           de outro estado. A condição is.na() é explícita:
#'                           substr(NA) != "33" dá NA, e o filtro descartaria a ficha.
ler_banco_sivep_rj <- function(caminho, ano_banco, prefixo_uf = PREFIXO_UF_RJ,
                               recorte = c("residencia", "notificacao_de_fora")) {
  recorte <- match.arg(recorte)
  verificar_manifesto(caminho)

  ds <- arrow::open_dataset(caminho)
  validar_variaveis(names(ds), COLUNAS_SIVEP, basename(caminho))   # CS-009
  ds <- if (recorte == "residencia") {
    dplyr::filter(ds, substr(CO_MUN_RES, 1, 2) == prefixo_uf)
  } else {
    dplyr::filter(ds, substr(CO_MUN_NOT, 1, 2) == prefixo_uf &
                    (is.na(CO_MUN_RES) | substr(CO_MUN_RES, 1, 2) != prefixo_uf))
  }
  d <- ds |>
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

  validar_datas(d$DT_SIN_PRI, d$ano_banco)             # CS-009: vazia ou fora do ano epidemiológico
  validar_codigos_ibge(d$CO_MUN_RES, "CO_MUN_RES")       # CS-009
  if (any(d$SG_UF != "RJ", na.rm = TRUE)) {
    stop(sum(d$SG_UF != "RJ", na.rm = TRUE), " fichas com CO_MUN_RES 33 e SG_UF != RJ",
         call. = FALSE)
  }
  d
}

#' Fichas notificadas em município do RJ por quem mora fora do RJ (CS-031).
#' Mesmas invariantes de preparar_sivep() que valem para elas: DT_SIN_PRI
#' presente, CO_MUN_NOT no padrão do RJ e ano epidemiológico = ano do banco.
preparar_sivep_notificados_de_fora <- function(anos = ANOS_ESTUDO, fontes = ler_fontes()) {
  b <- bancos_sivep(anos, fontes)
  d <- do.call(rbind, lapply(seq_len(nrow(b)), function(i) {
    ler_banco_sivep_rj(b$destino[i], b$ano[i], recorte = "notificacao_de_fora")
  }))
  validar_datas(d$DT_SIN_PRI, d$ano_banco)             # CS-009
  validar_codigos_ibge(d$CO_MUN_NOT, "CO_MUN_NOT")       # CS-009
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
      # teste com resultado conclusivo (1 positivo/detectável, 2 negativo, 3 inconclusivo),
      # por RT-PCR ou antígeno: mede cobertura de testagem, que muda entre anos
      com_resultado_de_teste = sum(x$PCR_RESUL %in% 1:3 | x$RES_AN %in% 1:3),
      nao_internado = sum(x$HOSPITAL == 2L, na.rm = TRUE),
      internacao_ignorada_ou_vazia = sum(is.na(x$HOSPITAL) | x$HOSPITAL == 9L),
      residencia_diferente_notificacao = sum(x$CO_MUN_RES != x$CO_MUN_NOT, na.rm = TRUE)
    )
  }))
}

# ---------------------------------------------------------------------------
# Critério de caso por agente (CS-007 / ADR-0002)
#
# As regras candidatas ficam AQUI, como código, para que a tabela comparativa
# do ADR-0002 saia do pipeline e a regra escolhida (CS-008) seja a mesma função
# que gerou os números da decisão.
# ---------------------------------------------------------------------------

AGENTES <- c("sarscov2", "influenza", "vsr")

#' Sinais laboratoriais e de classificação de cada ficha, como colunas lógicas.
#' NA em campo de código conta como FALSE (não marcado / não informado).
sinais_caso <- function(d) {
  um <- function(col) !is.na(d[[col]]) & d[[col]] == 1L
  cf <- function(k) !is.na(d$CLASSI_FIN) & d$CLASSI_FIN == k
  data.frame(
    # campo específico do agente ("qual vírus"), por RT-PCR ou antígeno
    esp_sarscov2 = um("PCR_SARS2") | um("AN_SARS2"),
    esp_influenza = um("POS_PCRFLU") | um("POS_AN_FLU"),
    esp_vsr = um("PCR_VSR") | um("AN_VSR"),
    # resultado positivo sem dizer o vírus: RT-PCR "detectável" ou antígeno "positivo"
    generico = um("PCR_RESUL") | um("RES_AN"),
    # sorologia para SARS-CoV-2 reagente
    sorologia = um("RES_IGG") | um("RES_IGM") | um("RES_IGA"),
    # a vigilância declarou encerramento por critério laboratorial
    criterio_lab = um("CRITERIO"),
    # classificação final da vigilância
    cf_covid = cf(5L), cf_influenza = cf(1L), cf_outro_virus = cf(2L),
    cf_vazio = is.na(d$CLASSI_FIN)
  )
}

#' Regras candidatas. Cada uma recebe os sinais e devolve, por agente, um vetor
#' lógico "é caso deste agente". VSR só é identificável pelo campo específico
#' (CLASSI_FIN = 2 cobre qualquer "outro vírus respiratório"), então ele é
#' igual em todas as regras ancoradas na classificação.
REGRAS_CASO <- list(
  R1_estrita_pdf = list(
    descricao = "Classificação final do agente E campo específico do vírus marcado (leitura literal do PDF v1)",
    fn = function(s) list(
      sarscov2 = s$cf_covid & s$esp_sarscov2,
      influenza = s$cf_influenza & s$esp_influenza,
      vsr = s$cf_outro_virus & s$esp_vsr)),
  R2_vigilancia = list(
    descricao = "Classificação final do agente E (critério de encerramento laboratorial OU campo específico marcado)",
    fn = function(s) list(
      sarscov2 = s$cf_covid & (s$criterio_lab | s$esp_sarscov2),
      influenza = s$cf_influenza & (s$criterio_lab | s$esp_influenza),
      vsr = s$cf_outro_virus & s$esp_vsr)),
  R3_qualquer_evidencia_lab = list(
    descricao = "Classificação final do agente E qualquer evidência laboratorial (específico, resultado genérico positivo, sorologia ou critério laboratorial)",
    fn = function(s) list(
      sarscov2 = s$cf_covid & (s$esp_sarscov2 | s$generico | s$sorologia | s$criterio_lab),
      influenza = s$cf_influenza & (s$esp_influenza | s$generico | s$criterio_lab),
      vsr = s$cf_outro_virus & s$esp_vsr)),
  R4_classificacao = list(
    descricao = "Só a classificação final da vigilância, inclusive encerramentos clínicos",
    fn = function(s) list(
      sarscov2 = s$cf_covid,
      influenza = s$cf_influenza,
      vsr = s$cf_outro_virus & s$esp_vsr)),
  R5_laboratorial = list(
    descricao = "Só o campo específico do vírus, ignorando a classificação final (inclui fichas não encerradas e co-detecções em cada agente)",
    fn = function(s) list(
      sarscov2 = s$esp_sarscov2,
      influenza = s$esp_influenza,
      vsr = s$esp_vsr))
)

#' Aplica uma regra e devolve data.frame lógico com uma coluna por agente.
aplicar_regra_caso <- function(d, regra) {
  if (!regra %in% names(REGRAS_CASO)) {
    stop("Regra desconhecida: ", regra, ". Opções: ", paste(names(REGRAS_CASO), collapse = ", "),
         call. = FALSE)
  }
  r <- REGRAS_CASO[[regra]]$fn(sinais_caso(d))
  as.data.frame(r[AGENTES])
}

#' Casos por regra × agente × ano, mais quantas fichas cada regra conta em dois
#' ou mais agentes (só possível na R5: nas outras, cada ficha tem uma única
#' classificação final).
comparar_regras_caso <- function(d) {
  anos <- sort(unique(d$ano_banco))
  linhas <- list()
  for (regra in names(REGRAS_CASO)) {
    m <- aplicar_regra_caso(d, regra)
    for (ag in AGENTES) {
      for (a in anos) {
        linhas[[length(linhas) + 1]] <- data.frame(
          regra = regra, agente = ag, ano = a,
          casos = sum(m[[ag]] & d$ano_banco == a), stringsAsFactors = FALSE)
      }
    }
    for (a in anos) {
      linhas[[length(linhas) + 1]] <- data.frame(
        regra = regra, agente = "fichas_em_2_ou_mais_agentes", ano = a,
        casos = sum(rowSums(m) >= 2 & d$ano_banco == a), stringsAsFactors = FALSE)
    }
  }
  do.call(rbind, linhas)
}

#' Decompõe, por ano, as fichas com classificação final de COVID ou Influenza
#' que NÃO têm o campo específico marcado: onde está (ou não está) o laboratório
#' delas. É a evidência central do ADR-0002.
decompor_sem_campo_especifico <- function(d) {
  s <- sinais_caso(d)
  anos <- sort(unique(d$ano_banco))
  cr <- d$CRITERIO
  blocos <- list(
    list(agente = "sarscov2", cf = s$cf_covid, esp = s$esp_sarscov2, lab_extra = s$generico | s$sorologia),
    list(agente = "influenza", cf = s$cf_influenza, esp = s$esp_influenza, lab_extra = s$generico)
  )
  do.call(rbind, lapply(blocos, function(b) {
    alvo <- b$cf & !b$esp
    do.call(rbind, lapply(anos, function(a) {
      x <- alvo & d$ano_banco == a
      data.frame(
        agente = b$agente, ano = a,
        classificados = sum(b$cf & d$ano_banco == a),
        com_campo_especifico = sum(b$cf & b$esp & d$ano_banco == a),
        sem_campo_especifico = sum(x),
        resultado_positivo_generico_ou_sorologia = sum(x & b$lab_extra),
        so_criterio_laboratorial_declarado = sum(x & !b$lab_extra & s$criterio_lab),
        criterio_clinico_epidemiologico = sum(x & !b$lab_extra & !is.na(cr) & cr == 2L),
        criterio_clinico_ou_imagem = sum(x & !b$lab_extra & !is.na(cr) & cr %in% c(3L, 4L)),
        criterio_vazio = sum(x & !b$lab_extra & is.na(cr)),
        stringsAsFactors = FALSE
      )
    }))
  }))
}

#' Entre as fichas que a regra conta em um agente, quantas também têm o campo
#' específico de OUTRO agente marcado (co-detecção laboratorial), por ano.
resumir_codeteccao <- function(d, regra) {
  s <- sinais_caso(d)
  m <- aplicar_regra_caso(d, regra)
  anos <- sort(unique(d$ano_banco))
  outros <- list(sarscov2 = s$esp_influenza | s$esp_vsr,
                 influenza = s$esp_sarscov2 | s$esp_vsr,
                 vsr = s$esp_sarscov2 | s$esp_influenza)
  do.call(rbind, lapply(AGENTES, function(ag) do.call(rbind, lapply(anos, function(a) {
    x <- m[[ag]] & d$ano_banco == a
    data.frame(regra = regra, agente = ag, ano = a, casos = sum(x),
               com_outro_agente_detectado = sum(x & outros[[ag]]), stringsAsFactors = FALSE)
  }))))
}

# ---------------------------------------------------------------------------
# Classificação por agente (CS-008), com a regra aceita no ADR-0002
# ---------------------------------------------------------------------------

#' Acrescenta a coluna `agente` (fator sarscov2/influenza/vsr; NA = não é caso).
#'
#' Atribuição única (ADR-0002, decisão 2): se a regra marcar a mesma ficha em dois
#' agentes, a função PARA. Com a R2 isso não acontece, porque cada ficha tem um só
#' CLASSI_FIN; a trava existe para o dia em que alguém trocar a regra por outra
#' que conte co-detecção duas vezes (a R5, por exemplo).
classificar_agente <- function(d, regra = REGRA_CASO) {
  m <- aplicar_regra_caso(d, regra)
  multiplos <- rowSums(m) > 1
  if (any(multiplos)) {
    stop(sum(multiplos), " ficha(s) classificada(s) em mais de um agente pela regra ", regra,
         "; a atribuição única do ADR-0002 exige um agente por ficha", call. = FALSE)
  }
  agente <- rep(NA_character_, nrow(d))
  for (ag in AGENTES) agente[m[[ag]]] <- ag
  d$agente <- factor(agente, levels = AGENTES)
  d
}

#' Fica só com os casos e acrescenta as colunas derivadas:
#' - codeteccao: o campo específico de OUTRO dos três agentes está marcado
#'   (reportada, não contada duas vezes; ADR-0002 §3.3);
#' - subtipo_influenza: "A" ou "B" para casos de influenza, pelo RT-PCR quando
#'   positivo, senão pelo antígeno; NA se o caso entrou só pelo critério declarado.
aplicar_criterios_inclusao <- function(d) {
  if (!"agente" %in% names(d)) stop("Rode classificar_agente() antes", call. = FALSE)
  s <- sinais_caso(d)
  outros <- cbind(
    sarscov2 = s$esp_influenza | s$esp_vsr,
    influenza = s$esp_sarscov2 | s$esp_vsr,
    vsr = s$esp_sarscov2 | s$esp_influenza
  )
  ag <- as.character(d$agente)
  d$codeteccao <- FALSE
  for (a in AGENTES) d$codeteccao[!is.na(ag) & ag == a] <- outros[!is.na(ag) & ag == a, a]

  tipo <- ifelse(!is.na(d$POS_PCRFLU) & d$POS_PCRFLU == 1L, d$TP_FLU_PCR,
                 ifelse(!is.na(d$POS_AN_FLU) & d$POS_AN_FLU == 1L, d$TP_FLU_AN, NA_integer_))
  d$subtipo_influenza <- ifelse(!is.na(ag) & ag == "influenza",
                                c("A", "B")[match(tipo, 1:2)], NA_character_)
  d[!is.na(d$agente), , drop = FALSE]
}

#' Casos por agente e ano: a tabela que tem de bater com a linha da regra em
#' comparacao_regras_caso.csv (aceite do CS-008).
contar_casos_agente <- function(casos) {
  t <- as.data.frame(table(agente = casos$agente, ano = casos$ano_banco), stringsAsFactors = FALSE)
  names(t)[3] <- "casos"
  t$ano <- as.integer(t$ano)
  t[order(t$agente, t$ano), ]
}
