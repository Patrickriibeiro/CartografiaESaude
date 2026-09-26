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

#' Fichas por semana e proporção não encerrada, em DOIS painéis empilhados com o mesmo
#' eixo do tempo (CS-047). A 1ª versão sobrepunha as duas medidas num eixo duplo, e o
#' olho lia cruzamentos entre a barra e a linha que não significam nada: as escalas eram
#' arbitrárias uma em relação à outra.
grafico_nao_encerrados <- function(semanal, versao_banco) {
  paineis <- c("Fichas de SRAG por semana", "Sem classificação final (%)")
  longo <- rbind(
    data.frame(semana_epi = semanal$semana_epi, valor = semanal$fichas, painel = paineis[1]),
    data.frame(semana_epi = semanal$semana_epi, valor = 100 * semanal$proporcao, painel = paineis[2]))
  longo$painel <- factor(longo$painel, levels = paineis)
  ggplot2::ggplot(longo, ggplot2::aes(semana_epi, valor)) +
    ggplot2::geom_col(data = longo[longo$painel == paineis[1], ], fill = "grey70", width = 0.8) +
    ggplot2::geom_line(data = longo[longo$painel == paineis[2], ], colour = COR_NEUTRA, linewidth = 0.7) +
    ggplot2::geom_point(data = longo[longo$painel == paineis[2], ], colour = COR_NEUTRA, size = 1.3) +
    ggplot2::facet_grid(painel ~ ., scales = "free_y", switch = "y") +
    ggplot2::scale_x_continuous(breaks = seq(0, 53, 5)) +
    ggplot2::labs(
      title = sprintf("Fichas de SRAG e fichas ainda não encerradas por semana epidemiológica, %d", semanal$ano[1]),
      subtitle = sprintf("Residentes do RJ; banco na versão %s.", versao_banco),
      x = "Semana epidemiológica do início dos sintomas", y = NULL,
      caption = "Não encerrada = classificação final (CLASSI_FIN) vazia. Fonte: SIVEP-Gripe."
    ) +
    ggplot2::theme_minimal(base_size = 10) +
    ggplot2::theme(plot.title = ggplot2::element_text(face = "bold"),
                   plot.subtitle = ggplot2::element_text(colour = "grey30", size = 8.5),
                   plot.caption = ggplot2::element_text(colour = "grey40", hjust = 0),
                   strip.placement = "outside", strip.text.y.left = ggplot2::element_text(angle = 90, face = "bold"),
                   panel.grid.minor = ggplot2::element_blank())
}

#' Série semanal com um painel por vírus, cada um na sua escala (CS-047): o pico de
#' SARS-CoV-2 de 2022 esconde, na escala comum, o tempo e a forma das ondas de influenza
#' e VSR. Complementa grafico_serie_semanal(), que mostra a magnitude relativa.
grafico_serie_por_virus <- function(serie, recorte, campanhas) {
  x <- serie[serie$recorte == recorte, ]
  if (nrow(x) == 0) stop("Recorte sem dados: ", recorte, call. = FALSE)
  x$agente_rotulo <- factor(ROTULOS_AGENTE[x$agente], levels = ROTULOS_AGENTE)
  ggplot2::ggplot(x, ggplot2::aes(inicio_semana, casos, colour = agente_rotulo)) +
    ggplot2::geom_vline(xintercept = campanhas$inicio, linetype = "dashed", colour = "grey55", linewidth = 0.35) +
    ggplot2::geom_line(linewidth = 0.7, show.legend = FALSE) +
    escala_cor_agente() +
    ggplot2::facet_wrap(~agente_rotulo, ncol = 1, scales = "free_y") +
    ggplot2::scale_x_date(date_breaks = "3 months", date_labels = "%m/%Y", expand = ggplot2::expansion(mult = 0.01)) +
    ggplot2::labs(
      title = sprintf("Casos de SRAG por semana epidemiológica, %s: cada vírus na sua escala", recorte),
      subtitle = "Escalas verticais diferentes: compare o TEMPO das ondas, não a altura entre painéis. Tracejado: campanha contra influenza.",
      x = NULL, y = "Casos por semana",
      caption = "Fontes: SIVEP-Gripe (critério do ADR-0002), Ministério da Saúde (datas das campanhas)."
    ) +
    ggplot2::theme_minimal(base_size = 10) +
    ggplot2::theme(axis.text.x = ggplot2::element_text(angle = 45, hjust = 1),
                   plot.title = ggplot2::element_text(face = "bold"),
                   plot.subtitle = ggplot2::element_text(colour = "grey30", size = 8.5),
                   plot.caption = ggplot2::element_text(colour = "grey40", hjust = 0),
                   strip.text = ggplot2::element_text(face = "bold", hjust = 0),
                   panel.grid.minor = ggplot2::element_blank())
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

# ---------------------------------------------------------------------------
# Versões do banco e tempo até o encerramento (CS-048)
# ---------------------------------------------------------------------------

#' Versões anteriores configuradas em config/fontes.yml, com destino em dados/brutos/versoes.
versoes_anteriores <- function(fontes = ler_fontes()) {
  v <- fontes$sivep$versoes_anteriores
  if (is.null(v)) return(data.frame(ano = integer(0), versao = character(0), url = character(0), destino = character(0)))
  d <- data.frame(ano = vapply(v, function(x) as.integer(x$ano), integer(1)),
                  versao = vapply(v, function(x) x$versao, character(1)),
                  url = vapply(v, function(x) x$url, character(1)), stringsAsFactors = FALSE)
  d$destino <- file.path("dados", "brutos", "versoes", basename(d$url))
  d
}

#' Baixa as versões anteriores e registra cada uma no manifesto.
baixar_versoes_anteriores <- function(fontes = ler_fontes()) {
  v <- versoes_anteriores(fontes)
  for (i in seq_len(nrow(v))) {
    baixar_e_registrar(v$url[i], v$destino[i], versao = v$versao[i],
                       descricao = sprintf("SIVEP-Gripe, banco %d, versão ANTERIOR de %s (só para o CS-048)", v$ano[i], v$versao[i]))
  }
  invisible(v)
}

#' Resume uma versão de um banco anual: fichas de residentes do RJ no ano
#' epidemiológico, quantas estão encerradas e quantos casos de cada agente pela
#' regra do estudo (ADR-0002). Fichas fora do ano epidemiológico são contadas e
#' descartadas (versões antigas não passam pelas validações do estudo).
resumir_versao <- function(caminho, ano, versao, regra = REGRA_CASO) {
  d <- ler_banco_sivep_rj(caminho, ano)
  dentro <- !is.na(d$ano_epi) & d$ano_epi == ano
  d <- d[dentro, , drop = FALSE]
  casos <- aplicar_criterios_inclusao(classificar_agente(d, regra))
  n <- table(factor(as.character(casos$agente), levels = AGENTES))
  data_versao <- as.Date(versao, format = "%d-%m-%Y")
  fim_ano <- limites_ano_epi(ano)$fim
  data.frame(ano = as.integer(ano), versao = versao, data_versao = data_versao,
             dias_apos_fim_do_ano = as.integer(data_versao - fim_ano),
             fichas = nrow(d), fora_do_ano = sum(!dentro), encerradas = sum(!is.na(d$CLASSI_FIN)),
             casos_sarscov2 = as.integer(n[["sarscov2"]]), casos_influenza = as.integer(n[["influenza"]]),
             casos_vsr = as.integer(n[["vsr"]]), stringsAsFactors = FALSE)
}

#' Junta os resumos de várias versões e expressa cada contagem como % da versão mais
#' recente do mesmo ano (a de referência do estudo).
comparar_versoes <- function(resumos) {
  r <- resumos[order(resumos$ano, resumos$data_versao), ]
  cols <- c("fichas", "encerradas", "casos_sarscov2", "casos_influenza", "casos_vsr")
  ref <- r[!duplicated(r$ano, fromLast = TRUE), c("ano", cols)]
  for (cl in cols) r[[paste0("pct_", cl)]] <- 100 * r[[cl]] / ref[[cl]][match(r$ano, ref$ano)]
  r$referencia <- !duplicated(r$ano, fromLast = TRUE)
  rownames(r) <- NULL
  r
}

#' Tempo entre o início dos sintomas e o encerramento (DT_ENCERRA) e a digitação
#' (DT_DIGITA), por ano: mediana e percentil 90 em dias, e proporção de TODAS as
#' fichas encerradas em até 30, 60 e 90 dias. Datas de encerramento anteriores ao
#' início dos sintomas são contadas como inconsistentes e ficam fora das medidas.
tempo_encerramento <- function(sivep_rj) {
  out <- do.call(rbind, lapply(split(sivep_rj, sivep_rj$ano_banco), function(x) {
    enc <- as.numeric(x$DT_ENCERRA - x$DT_SIN_PRI)
    dig <- as.numeric(x$DT_DIGITA - x$DT_SIN_PRI)
    fechada <- !is.na(x$CLASSI_FIN) & !is.na(enc)
    inconsistente <- fechada & enc < 0
    valido <- fechada & !inconsistente
    ate <- function(dias) mean(valido & enc <= dias)
    data.frame(ano = as.integer(x$ano_banco[1]), fichas = nrow(x),
               encerradas_com_data = sum(fechada), encerramento_antes_dos_sintomas = sum(inconsistente),
               dias_encerramento_mediana = stats::median(enc[valido]),
               dias_encerramento_p90 = unname(stats::quantile(enc[valido], 0.9)),
               pct_encerradas_30d = 100 * ate(30), pct_encerradas_60d = 100 * ate(60), pct_encerradas_90d = 100 * ate(90),
               dias_digitacao_mediana = stats::median(dig[!is.na(dig) & dig >= 0]),
               stringsAsFactors = FALSE)
  }))
  rownames(out) <- NULL
  out
}

#' Evolução das contagens de um ano ao longo das versões: DIFERENÇA em número de casos
#' em relação à versão do estudo, uma linha por agente (cores do projeto). Em número
#' absoluto, e não em %: com diferenças de 1 a 3 casos, um eixo de 99,9 % a 100,1 %
#' faria ruído parecer mudança.
grafico_versoes <- function(comp, ano) {
  x <- comp[comp$ano == ano, ]
  if (nrow(x) < 2) stop("Menos de duas versões para ", ano, call. = FALSE)
  ref <- x[x$referencia, ]
  longo <- do.call(rbind, lapply(AGENTES, function(ag) {
    col <- paste0("casos_", ag)
    data.frame(dias = x$dias_apos_fim_do_ano, dif = x[[col]] - ref[[col]], serie = ROTULOS_AGENTE[[ag]])
  }))
  longo$serie <- factor(longo$serie, levels = ROTULOS_AGENTE)
  lim <- max(5, max(abs(longo$dif)) + 1)
  ggplot2::ggplot(longo, ggplot2::aes(dias, dif, colour = serie)) +
    ggplot2::geom_hline(yintercept = 0, colour = "grey60", linetype = "dashed") +
    ggplot2::geom_line(linewidth = 0.9) +
    ggplot2::geom_point(size = 2.2) +
    escala_cor_agente() +
    ggplot2::scale_y_continuous(limits = c(-lim, lim), breaks = scales::breaks_pretty(n = 5)) +
    ggplot2::labs(
      title = sprintf("Casos confirmados do banco de %d em cada versão publicada", ano),
      subtitle = sprintf("Diferença em número de casos para a versão usada no estudo (%s): %s, %s e %s casos nela.",
                         ref$versao, formatC(ref$casos_sarscov2, format = "d", big.mark = ".", decimal.mark = ","),
                         formatC(ref$casos_influenza, format = "d", big.mark = ".", decimal.mark = ","), formatC(ref$casos_vsr, format = "d", big.mark = ".", decimal.mark = ",")),
      x = "Dias depois do fim do ano epidemiológico", y = "Casos a mais (+) ou a menos (-)",
      caption = "Fonte: versões semanais do banco SIVEP-Gripe no Portal de Dados Abertos do SUS; critério de caso do ADR-0002.") +
    ggplot2::theme_minimal(base_size = 10) +
    ggplot2::theme(legend.position = "top", plot.title = ggplot2::element_text(face = "bold"),
                   plot.subtitle = ggplot2::element_text(colour = "grey30", size = 8.5),
                   plot.caption = ggplot2::element_text(colour = "grey40", hjust = 0),
                   panel.grid.minor = ggplot2::element_blank())
}
