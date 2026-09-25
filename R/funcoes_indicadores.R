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

# ---------------------------------------------------------------------------
# Casos e incidência (CS-012)
# ---------------------------------------------------------------------------

ANO_DENOMINADOR_UNICO <- 2024L  # D-05: comparações entre anos usam a estimativa 2024

#' Quadrimestre epidemiológico a partir da semana epidemiológica.
#' O ano do estudo é epidemiológico (CS-036), então o quadrimestre também é:
#' semanas 1–17, 18–34 e 35–52/53. Pelo mês de DT_SIN_PRI, uma ficha de
#' 29/12/2024 do banco de 2025 cairia no 3º quadrimestre em vez do 1º.
quadrimestre_epi <- function(semana_epi) {
  if (any(!is.na(semana_epi) & (semana_epi < 1 | semana_epi > 53))) {
    stop("Semana epidemiológica fora de 1–53", call. = FALSE)
  }
  as.integer(cut(semana_epi, breaks = c(0, 17, 34, 53), labels = FALSE))
}

#' Conta casos por município × agente × ano (e quadrimestre, se pedido).
#' Só conta o que existe: municípios sem caso NÃO aparecem aqui (ver
#' completar_municipios).
calcular_casos <- function(casos, por_quadrimestre = FALSE) {
  chave <- data.frame(cod6 = casos$CO_MUN_RES, agente = as.character(casos$agente),
                      ano = as.integer(casos$ano_banco), stringsAsFactors = FALSE)
  if (por_quadrimestre) chave$quadrimestre <- quadrimestre_epi(casos$semana_epi)
  chave$casos <- 1L
  stats::aggregate(casos ~ ., data = chave, FUN = sum)
}

#' Completa a grade: TODA combinação município × agente × ano (× quadrimestre)
#' aparece, com casos = 0 onde não houve caso. Uma junção que descartasse o zero
#' tiraria municípios do Moran e do mapa.
completar_municipios <- function(contagem, cod6, anos = ANOS_ESTUDO, agentes = AGENTES,
                                 quadrimestres = NULL) {
  fora <- setdiff(unique(contagem$cod6), cod6)
  if (length(fora) > 0) {
    stop("Município com caso fora da lista de municípios: ", paste(fora, collapse = ", "),
         call. = FALSE)
  }
  eixos <- list(cod6 = sort(unique(cod6)), agente = agentes, ano = as.integer(anos))
  if (!is.null(quadrimestres)) eixos$quadrimestre <- as.integer(quadrimestres)
  grade <- expand.grid(eixos, stringsAsFactors = FALSE, KEEP.OUT.ATTRS = FALSE)
  chaves <- names(eixos)
  g <- merge(grade, contagem, by = chaves, all.x = TRUE, sort = FALSE)
  g$casos[is.na(g$casos)] <- 0L
  g$casos <- as.integer(g$casos)
  g[do.call(order, g[chaves]), c(chaves, "casos")]
}

#' Taxas por 100 mil habitantes, com os dois denominadores da D-05 (ADR-0003):
#' - incid_100k: população oficial do mesmo ano (mapa e LISA de cada ano);
#' - incid_100k_pop2024: estimativa 2024 em todos os anos (comparar anos).
#' No quadrimestre, a taxa é do período (não anualizada).
#' Para se faltar população para alguma linha da grade.
calcular_incidencia <- function(grade, populacao, ano_unico = ANO_DENOMINADOR_UNICO) {
  pop_ano <- populacao[, c("cod6", "ano", "populacao", "fonte")]
  names(pop_ano)[3:4] <- c("populacao", "fonte_populacao")
  pop_unica <- populacao[populacao$ano == ano_unico, c("cod6", "populacao")]
  if (nrow(pop_unica) == 0) stop("Sem população de ", ano_unico, call. = FALSE)
  names(pop_unica)[2] <- "populacao_unica"

  g <- merge(grade, pop_ano, by = c("cod6", "ano"), all.x = TRUE, sort = FALSE)
  g <- merge(g, pop_unica, by = "cod6", all.x = TRUE, sort = FALSE)
  faltam <- is.na(g$populacao) | is.na(g$populacao_unica)
  if (any(faltam)) {
    stop(sum(faltam), " linha(s) da grade sem população (ex.: ",
         paste(utils::head(unique(g$cod6[faltam]), 3), collapse = ", "), ")", call. = FALSE)
  }
  g$incid_100k <- g$casos / g$populacao * 1e5
  g$incid_100k_pop2024 <- g$casos / g$populacao_unica * 1e5
  chaves <- intersect(c("cod6", "agente", "ano", "quadrimestre"), names(g))
  g[do.call(order, g[chaves]), ]
}

#' Totais do estado por agente e ano com os dois denominadores: mostra o tamanho
#' do degrau Censo × estimativa na série estadual (ADR-0003).
resumir_incidencia_estado <- function(ind) {
  por <- stats::aggregate(cbind(casos, populacao, populacao_unica) ~ agente + ano,
                          data = ind, FUN = sum)
  por$incid_100k <- por$casos / por$populacao * 1e5
  por$incid_100k_pop2024 <- por$casos / por$populacao_unica * 1e5
  por[order(por$agente, por$ano), ]
}

# ---------------------------------------------------------------------------
# Suavização empírica de Bayes (CS-013, D-09)
# ---------------------------------------------------------------------------

#' Taxa suavizada por Bayes empírico global (Marshall, 1991), por agente × ano.
#'
#' Cada município tem a taxa "puxada" para a média do estado com força
#' proporcional à incerteza: município pequeno é puxado muito, grande quase nada.
#'   b   = soma(casos) / soma(população)            média do estado
#'   s2  = variância das taxas, ponderada pela população
#'   a   = s2 - b / (população média)               variância "real" entre municípios
#'   eb  = b + a (taxa - b) / (a + b / população)
#' Usa a população oficial do ano (a mesma do mapa e do LISA; ADR-0003).
#' Agente × ano sem nenhum caso no estado fica com taxa suavizada 0: o spdep
#' devolveria NaN (0/0).
#' Acrescenta incid_eb_100k e guarda os parâmetros a e b por agente × ano.
suavizar_bayes_empirico <- function(ind) {
  ind$incid_eb_100k <- NA_real_
  parametros <- list()
  for (ag in unique(ind$agente)) for (a in unique(ind$ano)) {
    i <- which(ind$agente == ag & ind$ano == a)
    if (sum(ind$casos[i]) == 0) {
      ind$incid_eb_100k[i] <- 0
      par <- list(a = NA_real_, b = 0)
    } else {
      eb <- spdep::EBest(ind$casos[i], ind$populacao[i], family = "poisson")
      ind$incid_eb_100k[i] <- eb$estmm * 1e5
      par <- attr(eb, "parameters")
    }
    parametros[[length(parametros) + 1]] <- data.frame(
      agente = ag, ano = a, media_estado_100k = par$b * 1e5, variancia_a = par$a,
      encolhimento_total = isTRUE(par$a == 0), stringsAsFactors = FALSE)
  }
  if (anyNA(ind$incid_eb_100k)) stop("Taxa suavizada com NA", call. = FALSE)
  attr(ind, "parametros_eb") <- do.call(rbind, parametros)
  ind
}

#' Resumo da suavização por agente × ano, para a nota metodológica: quanto os
#' extremos encolhem e se a ordem dos municípios muda.
resumir_suavizacao <- function(ind) {
  par <- attr(ind, "parametros_eb")
  out <- do.call(rbind, lapply(split(ind, list(ind$agente, ind$ano), drop = TRUE), function(x) {
    data.frame(
      agente = x$agente[1], ano = x$ano[1],
      municipios_sem_caso = sum(x$casos == 0),
      bruta_max_100k = max(x$incid_100k), eb_max_100k = max(x$incid_eb_100k),
      bruta_min_100k = min(x$incid_100k), eb_min_100k = min(x$incid_eb_100k),
      spearman_bruta_eb = suppressWarnings(stats::cor(x$incid_100k, x$incid_eb_100k, method = "spearman")),
      mudanca_mediana_pct = stats::median(ifelse(x$incid_100k > 0,
        100 * abs(x$incid_eb_100k - x$incid_100k) / x$incid_100k, NA), na.rm = TRUE),
      stringsAsFactors = FALSE)
  }))
  out <- merge(out, par, by = c("agente", "ano"))
  out[order(out$agente, out$ano), ]
}
