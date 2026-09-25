# Funções de indicadores epidemiológicos: população (denominador) e taxas.

# ---------------------------------------------------------------------------
# População (CS-011, ADR-0003)
# ---------------------------------------------------------------------------

#' Baixa as tabelas de população do SIDRA listadas em config/fontes.yml e as
#' registra no manifesto. A resposta JSON da API é guardada como veio.
obter_populacao <- function(fontes = ler_fontes()) {
  for (p in fontes$ibge$populacao) {
    baixar_e_registrar(p$url, p$destino, descricao = p$descricao,
                       versao = paste0("SIDRA tabela ", p$tabela))
  }
  invisible(TRUE)
}

#' Lê uma resposta da API SIDRA (formato "values"): a 1ª linha traz os rótulos
#' das colunas, as demais os dados. D1 = município, D3 = ano, V = valor.
ler_sidra_json <- function(caminho) {
  verificar_manifesto(caminho)
  j <- jsonlite::fromJSON(caminho)
  if (!is.data.frame(j) || nrow(j) < 2 || !all(c("D1C", "D1N", "D3N", "V") %in% names(j))) {
    stop("Resposta SIDRA em formato inesperado: ", caminho, call. = FALSE)
  }
  corpo <- j[-1, , drop = FALSE]
  # O SIDRA usa "-", "..." e "X" para zero, não disponível e sigilo: nada disso
  # pode virar número em silêncio.
  if (any(!grepl("^[0-9]+$", corpo$V))) {
    stop("Valor não numérico em ", caminho, ": ",
         paste(utils::head(unique(corpo$V[!grepl("^[0-9]+$", corpo$V)]), 3), collapse = ", "),
         call. = FALSE)
  }
  data.frame(
    cod7 = corpo$D1C,
    cod6 = substr(corpo$D1C, 1, 6),
    nome = corpo$D1N,
    ano_ref = as.integer(corpo$D3N),
    populacao = as.numeric(corpo$V),
    stringsAsFactors = FALSE
  )
}

#' Monta o denominador populacional: uma linha por município e ano do estudo.
#'
#' - Ano com tabela própria em config/fontes.yml: usa o valor do IBGE.
#' - Ano sem tabela (2023: o IBGE não publicou estimativa municipal): depende de
#'   `metodo_ausente` (D-05, ADR-0003):
#'     "interpolacao" — linha reta entre o ano disponível anterior e o seguinte,
#'                      nas datas de referência reais (Censo em 01/08/2022,
#'                      estimativas em 1º de julho), avaliada em 1º de julho;
#'     "anterior"     — repete o ano disponível anterior.
#' - Tabelas marcadas como pré-Censo (ano 2021) nunca entram no denominador.
#'
#' Devolve cod6 (texto), ano, populacao (inteiro), fonte.
montar_populacao <- function(anos = ANOS_ESTUDO,
                             metodo_ausente = c("interpolacao", "anterior"),
                             fontes = ler_fontes()) {
  metodo_ausente <- match.arg(metodo_ausente)
  cfg <- Filter(function(p) !grepl("pré-Censo", p$descricao), fontes$ibge$populacao)
  tabelas <- lapply(cfg, function(p) {
    x <- ler_sidra_json(p$destino)
    x$data_ref <- as.Date(p$data_referencia)
    x$fonte <- p$descricao
    x
  })
  names(tabelas) <- vapply(cfg, function(p) as.character(p$ano), character(1))
  disponiveis <- sort(as.integer(names(tabelas)))

  por_ano <- lapply(anos, function(a) {
    if (a %in% disponiveis) {
      x <- tabelas[[as.character(a)]]
      return(data.frame(cod6 = x$cod6, ano = as.integer(a), populacao = x$populacao,
                        fonte = x$fonte, stringsAsFactors = FALSE))
    }
    antes <- disponiveis[disponiveis < a]
    depois <- disponiveis[disponiveis > a]
    if (length(antes) == 0) stop("Sem população para ", a, " nem ano anterior", call. = FALSE)
    x0 <- tabelas[[as.character(max(antes))]]

    if (metodo_ausente == "anterior") {
      return(data.frame(cod6 = x0$cod6, ano = as.integer(a), populacao = x0$populacao,
                        fonte = paste0("repetição de: ", x0$fonte[1]), stringsAsFactors = FALSE))
    }
    if (length(depois) == 0) stop("Sem ano posterior para interpolar ", a, call. = FALSE)
    x1 <- tabelas[[as.character(min(depois))]]
    if (!setequal(x0$cod6, x1$cod6)) stop("Municípios diferentes entre as tabelas", call. = FALSE)
    x1 <- x1[match(x0$cod6, x1$cod6), ]
    alvo <- as.Date(sprintf("%d-07-01", a))
    peso <- as.numeric(alvo - x0$data_ref[1]) / as.numeric(x1$data_ref[1] - x0$data_ref[1])
    data.frame(
      cod6 = x0$cod6, ano = as.integer(a),
      populacao = x0$populacao + peso * (x1$populacao - x0$populacao),
      fonte = sprintf("interpolação linear (peso %.4f) entre %s e %s", peso,
                      format(x0$data_ref[1]), format(x1$data_ref[1])),
      stringsAsFactors = FALSE
    )
  })
  pop <- do.call(rbind, por_ano)
  pop$populacao <- as.integer(round(pop$populacao))

  if (anyNA(pop$populacao) || any(pop$populacao <= 0)) {
    stop("População ausente ou não positiva", call. = FALSE)
  }
  contagem <- table(pop$ano)
  if (length(unique(contagem)) != 1) stop("Número de municípios difere entre anos", call. = FALSE)
  if (anyDuplicated(pop[, c("cod6", "ano")])) stop("Município repetido no mesmo ano", call. = FALSE)
  pop[order(pop$ano, pop$cod6), ]
}

#' Mede a descontinuidade entre o Censo 2022 e as estimativas (ADR-0003):
#' razão estimativa / Censo por município.
diagnosticar_populacao <- function(fontes = ler_fontes()) {
  lidos <- lapply(fontes$ibge$populacao, function(p) {
    x <- ler_sidra_json(p$destino); x$ano <- p$ano; x
  })
  largo <- Reduce(function(a, b) merge(a, b, by = c("cod6", "nome")),
                  lapply(lidos, function(x) {
                    y <- x[, c("cod6", "nome", "populacao")]
                    names(y)[3] <- paste0("pop_", x$ano[1]); y
                  }))
  largo$razao_2021_censo <- largo$pop_2021 / largo$pop_2022
  largo$razao_2024_censo <- largo$pop_2024 / largo$pop_2022
  largo[order(-largo$razao_2024_censo), ]
}

# A implementar:
# calcular_casos()        — CS-012
# calcular_incidencia()   — CS-012
# completar_municipios()  — CS-012 (grade 92 × 3 × 4 com zero explícito)
