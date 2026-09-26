# Séries temporais: casos por semana epidemiológica (CS-032) e proporção de
# fichas não encerradas (CS-035).

# ---------------------------------------------------------------------------
# Série por semana epidemiológica (CS-032)
# ---------------------------------------------------------------------------

#' Domingo que abre a semana epidemiológica de cada data (as semanas do
#' Ministério vão de domingo a sábado). É a posição da semana no eixo do tempo:
#' contínua entre anos, ao contrário do número da semana, que recomeça em 1.
inicio_semana_epi <- function(datas) {
  datas <- as.Date(datas)
  datas - as.POSIXlt(datas)$wday
}

#' Todos os domingos que abrem semanas dos anos epidemiológicos do estudo, com
#' ano_epi e semana_epi. Gerado pelo calendário (semana_epidemiologica()), não
#' pelos dados: semana sem nenhum caso também existe e entra com zero.
semanas_do_estudo <- function(anos = ANOS_ESTUDO) {
  dias <- seq(as.Date(sprintf("%d-12-20", min(anos) - 1)), as.Date(sprintf("%d-01-10", max(anos) + 1)), by = "day")
  domingos <- dias[as.POSIXlt(dias)$wday == 0]
  se <- semana_epidemiologica(domingos)
  s <- data.frame(inicio_semana = domingos, ano_epi = se$ano_epi, semana_epi = se$semana_epi)
  s[s$ano_epi %in% anos, ]
}

#' Casos por semana epidemiológica × agente, para o estado e para cada região de
#' saúde. A semana vem de DT_SIN_PRI (semana_epi calculada no ETL), NUNCA do
#' SEM_PRI do banco, que rotula a semana 53/2025 como 01 (D-08).
#' Devolve: recorte ("Estado do Rio de Janeiro" ou nome da região), agente,
#' inicio_semana, ano_epi, semana_epi, casos — com zero explícito.
serie_semanal <- function(casos, regioes, anos = ANOS_ESTUDO, agentes = AGENTES) {
  if (!all(casos$CO_MUN_RES %in% regioes$cod6)) stop("Caso com município sem região", call. = FALSE)
  d <- data.frame(regiao = regioes$regiao[match(casos$CO_MUN_RES, regioes$cod6)],
                  agente = as.character(casos$agente),
                  inicio_semana = inicio_semana_epi(casos$DT_SIN_PRI), stringsAsFactors = FALSE)
  sem <- semanas_do_estudo(anos)
  if (!all(d$inicio_semana %in% sem$inicio_semana)) stop("Caso fora das semanas do estudo", call. = FALSE)
  recortes <- c("Estado do Rio de Janeiro", sort(unique(regioes$regiao)))
  grade <- expand.grid(recorte = recortes, agente = agentes, i = seq_len(nrow(sem)),
                       stringsAsFactors = FALSE, KEEP.OUT.ATTRS = FALSE)
  grade <- cbind(grade[, c("recorte", "agente")], sem[grade$i, ])
  chave <- function(r, a, s) paste(r, a, format(s))
  n_reg <- table(chave(d$regiao, d$agente, d$inicio_semana))
  n_est <- table(chave("Estado do Rio de Janeiro", d$agente, d$inicio_semana))
  n <- c(n_reg, n_est)
  k <- chave(grade$recorte, grade$agente, grade$inicio_semana)
  grade$casos <- as.integer(ifelse(k %in% names(n), n[k], 0L))
  est <- grade$recorte == "Estado do Rio de Janeiro"
  if (sum(grade$casos[est]) != nrow(casos) || sum(grade$casos[!est]) != nrow(casos)) {
    stop("Série semanal não soma o número de casos", call. = FALSE)
  }
  grade <- grade[order(match(grade$recorte, recortes), match(grade$agente, agentes), grade$inicio_semana), ]
  rownames(grade) <- NULL
  grade
}

#' Datas de início das campanhas de influenza, de config/fontes.yml.
ler_campanhas_influenza <- function(fontes = ler_fontes()) {
  x <- fontes$campanhas_influenza
  if (is.null(x)) stop("config/fontes.yml sem campanhas_influenza", call. = FALSE)
  data.frame(ano = vapply(x, function(i) as.integer(i$ano), integer(1)),
             inicio = as.Date(vapply(x, function(i) i$inicio, character(1))),
             fonte = vapply(x, function(i) i$fonte, character(1)), stringsAsFactors = FALSE)
}

#' Gráfico de linhas: casos por semana, uma linha por agente, com linhas
#' verticais tracejadas no início de cada campanha de influenza.
grafico_serie_semanal <- function(serie, recorte, campanhas) {
  x <- serie[serie$recorte == recorte, ]
  if (nrow(x) == 0) stop("Recorte sem dados: ", recorte, call. = FALSE)
  x$agente_rotulo <- factor(ROTULOS_AGENTE[x$agente], levels = ROTULOS_AGENTE)
  ggplot2::ggplot(x, ggplot2::aes(inicio_semana, casos, colour = agente_rotulo)) +
    ggplot2::geom_vline(xintercept = campanhas$inicio, linetype = "dashed", colour = "grey45", linewidth = 0.4) +
    ggplot2::annotate("text", x = campanhas$inicio, y = Inf, label = "campanha", angle = 90,
                      hjust = 1.1, vjust = -0.4, size = 2.6, colour = "grey35") +
    ggplot2::geom_line(linewidth = 0.8) +
    escala_cor_agente() +
    ggplot2::scale_x_date(date_breaks = "3 months", date_labels = "%m/%Y", expand = ggplot2::expansion(mult = 0.01)) +
    ggplot2::labs(
      title = sprintf("Casos de SRAG por semana epidemiológica, %s", recorte),
      subtitle = "Semana do início dos sintomas (domingo a sábado). Tracejado: início da campanha nacional de vacinação contra influenza",
      x = NULL, y = "Casos por semana",
      caption = "Fontes: SIVEP-Gripe (critério do ADR-0002), Ministério da Saúde (datas das campanhas)."
    ) +
    ggplot2::theme_minimal(base_size = 10) +
    ggplot2::theme(legend.position = "top", axis.text.x = ggplot2::element_text(angle = 45, hjust = 1),
                   plot.title = ggplot2::element_text(face = "bold"),
                   plot.subtitle = ggplot2::element_text(colour = "grey30", size = 8.5),
                   plot.caption = ggplot2::element_text(colour = "grey40", hjust = 0),
                   panel.grid.minor = ggplot2::element_blank())
}

# ---------------------------------------------------------------------------
# Fichas não encerradas (CS-035)
# ---------------------------------------------------------------------------

#' Por ano: fichas de SRAG de residentes do RJ, quantas estão com CLASSI_FIN
#' vazio (não encerradas) e a proporção. Não encerrada não entra como caso de
#' nenhum agente (ADR-0002): é uma perda de casos, medida aqui por ano.
resumir_nao_encerrados <- function(sivep_rj) {
  por <- split(sivep_rj, sivep_rj$ano_banco)
  out <- do.call(rbind, lapply(names(por), function(a) {
    x <- por[[a]]
    data.frame(ano = as.integer(a), fichas = nrow(x), nao_encerradas = sum(is.na(x$CLASSI_FIN)),
               proporcao = mean(is.na(x$CLASSI_FIN)))
  }))
  rownames(out) <- NULL
  out
}

#' A mesma proporção por semana epidemiológica de um ano. Serve para ver a
#' maturação do banco: se a investigação ainda não terminou, a proporção sobe nas
#' últimas semanas. Se não sobe, o banco já amadureceu — o gráfico mostra, não supõe.
nao_encerrados_por_semana <- function(sivep_rj, ano) {
  x <- sivep_rj[sivep_rj$ano_banco == ano, ]
  if (nrow(x) == 0) stop("Sem fichas em ", ano, call. = FALSE)
  por <- split(x, x$semana_epi)
  out <- do.call(rbind, lapply(names(por), function(s) {
    y <- por[[s]]
    data.frame(ano = as.integer(ano), semana_epi = as.integer(s), fichas = nrow(y),
               nao_encerradas = sum(is.na(y$CLASSI_FIN)), proporcao = mean(is.na(y$CLASSI_FIN)))
  }))
  out <- out[order(out$semana_epi), ]
  rownames(out) <- NULL
  out
}

#' Gráfico da proporção não encerrada por semana (barras = fichas).
grafico_nao_encerrados <- function(semanal, versao_banco) {
  escala <- max(semanal$fichas) / max(1e-9, max(semanal$proporcao))
  ggplot2::ggplot(semanal, ggplot2::aes(semana_epi)) +
    ggplot2::geom_col(ggplot2::aes(y = fichas), fill = "grey85") +
    ggplot2::geom_line(ggplot2::aes(y = proporcao * escala), colour = COR_NEUTRA, linewidth = 0.8) +
    ggplot2::scale_y_continuous(
      name = "Fichas de SRAG (barras)",
      sec.axis = ggplot2::sec_axis(~ . / escala, name = "Não encerradas (linha)",
                                   labels = scales::label_percent(decimal.mark = ","))) +
    ggplot2::labs(
      title = sprintf("Fichas ainda não encerradas por semana epidemiológica, %d", semanal$ano[1]),
      subtitle = sprintf("Residentes do RJ; banco na versão %s. Barras: fichas por semana. Linha: proporção sem classificação final.",
                         versao_banco),
      x = "Semana epidemiológica do início dos sintomas",
      caption = "Não encerrada = classificação final (CLASSI_FIN) vazia. Fonte: SIVEP-Gripe."
    ) +
    ggplot2::theme_minimal(base_size = 10) +
    ggplot2::theme(plot.title = ggplot2::element_text(face = "bold"),
                   plot.subtitle = ggplot2::element_text(colour = "grey30", size = 8.5),
                   plot.caption = ggplot2::element_text(colour = "grey40", hjust = 0),
                   axis.title.y.right = ggplot2::element_text(colour = COR_NEUTRA))
}

# ---------------------------------------------------------------------------
# Ano epidemiológico (CS-036)
# ---------------------------------------------------------------------------

#' Limites de cada ano epidemiológico do estudo: primeiro domingo, último
#' sábado, número de dias e de semanas, e o dia do meio. Cada banco anual do
#' SIVEP é um ano epidemiológico (ADR-0001), não um ano civil: 2024 começa em
#' 31/12/2023 e 2025 tem 53 semanas, terminando em 03/01/2026.
limites_ano_epi <- function(anos = ANOS_ESTUDO) {
  s <- semanas_do_estudo(anos)
  out <- do.call(rbind, lapply(split(s, s$ano_epi), function(x) {
    ini <- min(x$inicio_semana); fim <- max(x$inicio_semana) + 6
    data.frame(ano = x$ano_epi[1], inicio = ini, fim = fim, dias = as.integer(fim - ini) + 1L,
               semanas = nrow(x), meio = ini + as.integer(fim - ini) %/% 2L)
  }))
  rownames(out) <- NULL
  out
}
