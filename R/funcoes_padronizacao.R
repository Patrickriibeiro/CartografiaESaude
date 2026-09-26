# Padronização por idade, método direto (CS-033, OE9).
#
# Taxa padronizada = soma, sobre as faixas etárias, da taxa específica do município
# na faixa vezes o peso da faixa numa população-padrão. Dois municípios com as
# mesmas taxas por idade ficam com a mesma taxa padronizada, mesmo que um seja
# "jovem" e o outro "velho". A população-padrão é o RJ inteiro no Censo 2022.

# As 11 faixas: <1 e 1-4 separadas porque o VSR se concentra em bebês; depois de
# 10 anos, faixas de 10 em 10, com 80+ aberta. Limite inferior em anos completos.
FAIXAS_ETARIAS <- data.frame(
  faixa = c("<1", "1-4", "5-9", "10-19", "20-29", "30-39", "40-49", "50-59", "60-69", "70-79", "80+"),
  idade_min = c(0, 1, 5, 10, 20, 30, 40, 50, 60, 70, 80),
  stringsAsFactors = FALSE
)

# Categorias da tabela 9514 do SIDRA (classificação 287, "Idade") -> faixa.
# "0 a 4 anos" (93070) não é faixa: 1-4 sai de 93070 menos "Menos de 1 ano" (6557).
CATEGORIAS_IDADE_9514 <- c(
  "6557" = "<1", "93070" = "0-4", "93084" = "5-9", "93085" = "10-19", "93086" = "10-19",
  "93087" = "20-29", "93088" = "20-29", "93089" = "30-39", "93090" = "30-39",
  "93091" = "40-49", "93092" = "40-49", "93093" = "50-59", "93094" = "50-59",
  "93095" = "60-69", "93096" = "60-69", "93097" = "70-79", "93098" = "70-79",
  "49108" = "80+", "49109" = "80+", "60040" = "80+", "60041" = "80+", "6653" = "80+"
)
CATEGORIA_TOTAL_9514 <- "100362"

#' Baixa a tabela 9514 (Censo 2022 por grupo de idade) e registra no manifesto.
obter_populacao_idade <- function(fontes = ler_fontes()) {
  p <- fontes$ibge$populacao_idade
  baixar_e_registrar(p$url, p$destino, descricao = p$descricao, versao = paste0("SIDRA tabela ", p$tabela))
}

#' Lê a resposta da tabela 9514 e devolve cod6 × faixa × populacao (92 × 11).
#' "-" no SIDRA é zero (não resultante de arredondamento) e vira 0; "X" (sigilo)
#' e "..." (não disponível) param. Para se a soma das faixas de um município não
#' bater com o Total dele, ou se faltar categoria.
ler_populacao_idade <- function(caminho, n_municipios = 92L) {
  verificar_manifesto(caminho)
  j <- jsonlite::fromJSON(caminho)
  if (!is.data.frame(j) || nrow(j) < 2 || !all(c("D1C", "D6C", "V") %in% names(j))) {
    stop("Resposta SIDRA 9514 em formato inesperado: ", caminho, call. = FALSE)
  }
  corpo <- j[-1, , drop = FALSE]
  corpo$V[corpo$V == "-"] <- "0"
  if (any(!grepl("^[0-9]+$", corpo$V))) {
    stop("Valor não numérico na tabela 9514: ", exemplos(corpo$V[!grepl("^[0-9]+$", corpo$V)]), call. = FALSE)
  }
  desconhecida <- setdiff(unique(corpo$D6C), c(names(CATEGORIAS_IDADE_9514), CATEGORIA_TOTAL_9514))
  if (length(desconhecida) > 0) stop("Categoria de idade desconhecida: ", exemplos(desconhecida), call. = FALSE)
  corpo$cod6 <- substr(corpo$D1C, 1, 6)
  corpo$valor <- as.numeric(corpo$V)

  por_mun <- split(corpo, corpo$cod6)
  out <- do.call(rbind, lapply(names(por_mun), function(m) {
    x <- por_mun[[m]]
    v <- stats::setNames(x$valor, x$D6C)
    faltam <- setdiff(c(names(CATEGORIAS_IDADE_9514), CATEGORIA_TOTAL_9514), names(v))
    if (length(faltam) > 0) stop("Município ", m, " sem categoria(s) ", exemplos(faltam), call. = FALSE)
    if (anyDuplicated(names(v))) stop("Categoria repetida no município ", m, call. = FALSE)
    grupos <- tapply(v[names(CATEGORIAS_IDADE_9514)], CATEGORIAS_IDADE_9514, sum)
    de_1_a_4 <- grupos[["0-4"]] - grupos[["<1"]]
    if (de_1_a_4 < 0) stop("Menos de 1 ano maior que 0 a 4 anos no município ", m, call. = FALSE)
    faixas <- c(grupos[["<1"]], de_1_a_4, grupos[setdiff(FAIXAS_ETARIAS$faixa, c("<1", "1-4"))])
    if (sum(faixas) != v[[CATEGORIA_TOTAL_9514]]) {
      stop("Soma das faixas (", sum(faixas), ") difere do total (", v[[CATEGORIA_TOTAL_9514]], ") no município ", m, call. = FALSE)
    }
    data.frame(cod6 = m, faixa = FAIXAS_ETARIAS$faixa, populacao = as.numeric(faixas), stringsAsFactors = FALSE)
  }))
  if (length(unique(out$cod6)) != n_municipios) {
    stop("Tabela 9514 com ", length(unique(out$cod6)), " municípios; esperado ", n_municipios, call. = FALSE)
  }
  rownames(out) <- NULL
  out
}

#' Idade em anos completos a partir de NU_IDADE_N e TP_IDADE (1 = dias, 2 = meses,
#' 3 = anos). Sem o tipo, "6" pode ser 6 dias ou 6 anos. Para em NA ou idade
#' impossível (> 120): a padronização não tem faixa "ignorada".
idade_em_anos <- function(nu_idade, tp_idade) {
  if (anyNA(nu_idade) || anyNA(tp_idade)) {
    stop(sum(is.na(nu_idade) | is.na(tp_idade)), " caso(s) sem idade ou sem tipo de idade", call. = FALSE)
  }
  if (!all(tp_idade %in% 1:3)) stop("TP_IDADE fora de 1-3: ", exemplos(tp_idade[!tp_idade %in% 1:3]), call. = FALSE)
  anos <- ifelse(tp_idade == 3L, nu_idade, ifelse(tp_idade == 2L, nu_idade %/% 12, nu_idade %/% 365))
  if (any(anos > 120)) stop(sum(anos > 120), " caso(s) com idade acima de 120 anos", call. = FALSE)
  as.integer(anos)
}

#' Faixa etária de uma idade em anos completos (fator com as 11 faixas, na ordem).
faixa_etaria <- function(anos) {
  cut(anos, breaks = c(FAIXAS_ETARIAS$idade_min, Inf), right = FALSE, labels = FAIXAS_ETARIAS$faixa)
}

#' Casos por município × agente × ano × faixa, grade completa com zero explícito.
calcular_casos_faixa <- function(casos, cod6, anos = ANOS_ESTUDO, agentes = AGENTES) {
  validar_municipios_rj(casos$CO_MUN_RES, cod6, "Município com caso")
  d <- data.frame(cod6 = casos$CO_MUN_RES, agente = as.character(casos$agente), ano = as.integer(casos$ano_banco),
                  faixa = as.character(faixa_etaria(idade_em_anos(casos$NU_IDADE_N, casos$TP_IDADE))),
                  stringsAsFactors = FALSE)
  d$casos <- 1L
  contagem <- stats::aggregate(casos ~ cod6 + agente + ano + faixa, data = d, FUN = sum)
  grade <- expand.grid(cod6 = sort(unique(cod6)), agente = agentes, ano = as.integer(anos),
                       faixa = FAIXAS_ETARIAS$faixa, stringsAsFactors = FALSE, KEEP.OUT.ATTRS = FALSE)
  g <- merge(grade, contagem, by = c("cod6", "agente", "ano", "faixa"), all.x = TRUE, sort = FALSE)
  g$casos[is.na(g$casos)] <- 0L
  g$casos <- as.integer(g$casos)
  if (sum(g$casos) != nrow(casos)) stop("Grade por faixa etária perdeu casos", call. = FALSE)
  g[order(g$cod6, g$agente, g$ano, match(g$faixa, FAIXAS_ETARIAS$faixa)), ]
}

#' População por município × ano × faixa. O IBGE só tem a estrutura etária
#' municipal no Censo 2022: a PROPORÇÃO de cada faixa em 2022 é aplicada à
#' população total de cada ano (ADR-0003), de modo que a soma das faixas é
#' exatamente a população do ano e a taxa bruta recalculada das faixas é a
#' mesma taxa bruta do estudo.
montar_populacao_faixas <- function(pop_idade, populacao) {
  if (!setequal(pop_idade$cod6, populacao$cod6)) stop("Municípios diferentes entre 9514 e população anual", call. = FALSE)
  total_2022 <- tapply(pop_idade$populacao, pop_idade$cod6, sum)
  pop_idade$proporcao <- pop_idade$populacao / total_2022[pop_idade$cod6]
  out <- merge(populacao[, c("cod6", "ano", "populacao")], pop_idade[, c("cod6", "faixa", "proporcao")], by = "cod6")
  out$populacao_faixa <- out$populacao * out$proporcao
  out <- out[order(out$cod6, out$ano, match(out$faixa, FAIXAS_ETARIAS$faixa)), c("cod6", "ano", "faixa", "populacao_faixa")]
  rownames(out) <- NULL
  out
}

#' Pesos da população-padrão: participação de cada faixa no total do RJ (Censo 2022).
populacao_padrao <- function(pop_idade) {
  p <- tapply(pop_idade$populacao, pop_idade$faixa, sum)[FAIXAS_ETARIAS$faixa]
  data.frame(faixa = names(p), populacao = as.numeric(p), peso = as.numeric(p) / sum(p), stringsAsFactors = FALSE)
}

#' Método direto: por município × agente × ano, incid_pad_100k = Σ (casos_a / pop_a) × peso_a × 1e5.
#' Devolve também incid_faixas_100k, a taxa bruta recalculada das faixas, para a
#' conferência com incid_100k. Faixa com população zero e caso > 0 é erro.
padronizar_direto <- function(casos_faixa, pop_faixas, padrao) {
  d <- merge(casos_faixa, pop_faixas, by = c("cod6", "ano", "faixa"), all.x = TRUE)
  if (anyNA(d$populacao_faixa)) stop("Faixa sem população para alguma linha", call. = FALSE)
  if (any(d$populacao_faixa == 0 & d$casos > 0)) stop("Caso em faixa com população zero", call. = FALSE)
  d$peso <- padrao$peso[match(d$faixa, padrao$faixa)]
  if (anyNA(d$peso)) stop("Faixa sem peso na população-padrão", call. = FALSE)
  d$taxa_faixa <- ifelse(d$populacao_faixa > 0, d$casos / d$populacao_faixa, 0)
  d$contrib <- d$taxa_faixa * d$peso
  out <- stats::aggregate(cbind(casos, populacao_faixa, contrib) ~ cod6 + agente + ano, data = d, FUN = sum)
  out$incid_pad_100k <- out$contrib * 1e5
  out$incid_faixas_100k <- out$casos / out$populacao_faixa * 1e5
  out <- out[order(out$cod6, out$agente, out$ano), c("cod6", "agente", "ano", "incid_pad_100k", "incid_faixas_100k")]
  rownames(out) <- NULL
  out
}

#' Resumo por agente × ano: quanto a padronização muda a ordem e a escala.
resumir_padronizacao <- function(ind) {
  out <- do.call(rbind, lapply(split(ind, list(ind$agente, ind$ano), drop = TRUE), function(x) {
    com <- x$incid_100k > 0
    razao <- x$incid_pad_100k[com] / x$incid_100k[com]
    data.frame(agente = x$agente[1], ano = x$ano[1],
               spearman_bruta_pad = suppressWarnings(stats::cor(x$incid_100k, x$incid_pad_100k, method = "spearman")),
               razao_mediana = stats::median(razao), razao_min = min(razao), razao_max = max(razao),
               mun_razao_min = x$cod6[com][which.min(razao)], mun_razao_max = x$cod6[com][which.max(razao)],
               stringsAsFactors = FALSE)
  }))
  out <- out[order(match(out$agente, AGENTES), out$ano), ]
  rownames(out) <- NULL
  out
}

#' Casos por faixa etária no estado, por agente × ano, com a taxa específica
#' (população-padrão do ano = soma das faixas): o perfil etário de cada vírus.
resumir_perfil_etario <- function(casos_faixa, pop_faixas) {
  c <- stats::aggregate(casos ~ agente + ano + faixa, data = casos_faixa, FUN = sum)
  p <- stats::aggregate(populacao_faixa ~ ano + faixa, data = pop_faixas, FUN = sum)
  d <- merge(c, p, by = c("ano", "faixa"))
  d$taxa_100k <- d$casos / d$populacao_faixa * 1e5
  tot <- tapply(d$casos, paste(d$agente, d$ano), sum)
  d$proporcao <- d$casos / tot[paste(d$agente, d$ano)]
  d <- d[order(match(d$agente, AGENTES), d$ano, match(d$faixa, FAIXAS_ETARIAS$faixa)),
         c("agente", "ano", "faixa", "casos", "populacao_faixa", "taxa_100k", "proporcao")]
  rownames(d) <- NULL
  d
}

#' Dispersão taxa bruta × taxa padronizada por município, agente × ano.
grafico_padronizacao <- function(ind) {
  ind$agente_rotulo <- factor(ROTULOS_AGENTE[ind$agente], levels = ROTULOS_AGENTE)
  ggplot2::ggplot(ind, ggplot2::aes(incid_100k, incid_pad_100k)) +
    ggplot2::geom_abline(slope = 1, intercept = 0, colour = "grey60", linetype = "dashed") +
    ggplot2::geom_point(ggplot2::aes(size = populacao, colour = agente_rotulo), alpha = 0.6, show.legend = c(colour = FALSE)) +
    escala_cor_agente() +
    ggplot2::scale_size_area(max_size = 5, labels = scales::label_number(big.mark = ".", decimal.mark = ","), name = "População") +
    ggplot2::facet_wrap(agente_rotulo ~ ano, scales = "free", ncol = 4) +
    ggplot2::labs(
      title = "Taxa bruta × taxa padronizada por idade (método direto, padrão RJ 2022), por município",
      subtitle = "Acima da diagonal: o município tem, em proporção, menos gente que o estado nas idades em que o vírus incide, e a taxa bruta o subestima. A padronização corrige a estrutura etária, não a testagem.",
      x = "Taxa bruta por 100 mil hab.", y = "Taxa padronizada por 100 mil hab.",
      caption = "Fontes: SIVEP-Gripe (critério do ADR-0002), IBGE (Censo 2022 por idade, tabela 9514; estrutura etária de 2022 aplicada a todos os anos)."
    ) +
    ggplot2::theme_minimal(base_size = 9) +
    ggplot2::theme(legend.position = "bottom", plot.title = ggplot2::element_text(face = "bold"))
}
