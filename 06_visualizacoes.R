# 06_visualizacoes.R — mapas de incidência e de LISA (CS-019)
#
#   resultados/mapas/incidencia_<agente>_<ano>.png   12 mapas, 300 dpi
#   resultados/mapas/lisa_<agente>_<ano>.png         12 mapas, 300 dpi
#   resultados/mapas/painel_incidencia.png           3 agentes × 4 anos (para o relatório)
#   resultados/mapas/painel_lisa.png                 3 agentes × 4 anos (para o relatório)
#   resultados/mapas/regional_<agente>_<ano>.png     12 mapas por região de saúde (CS-030)
#   resultados/tabelas/serie_semanal.csv             casos por semana × agente, estado e 9 regiões (CS-032)
#   resultados/estatistica/serie_semanal_*.png       1 gráfico do estado + 9 regionais + painel (CS-032)
#   resultados/estatistica/nao_encerrados_<ano>.png  maturação do último ano (CS-035)
#   resultados/estatistica/leitos_x_incidencia.png   taxa de SRAG × leitos por 100 mil, por ano (CS-034)
#   resultados/estatistica/padronizacao_bruta_vs_padronizada.png  dispersão por município (CS-033)
#   resultados/estatistica/guia_cores.png            cor de cada vírus, rampas e classes do LISA (CS-046)

source("00_setup.R")

malha <- readRDS(file.path("dados", "processados", "municipios_rj.rds"))
ind <- as.data.frame(arrow::read_parquet(file.path("dados", "processados", "indicadores_municipais.parquet")))
lisa <- readRDS(file.path("resultados", "estatistica", "moran_lisa.rds"))$principal$lisa

pasta <- file.path("resultados", "mapas")
gerados <- character(0)
paineis_inc <- list(); paineis_lisa <- list()

for (ag in AGENTES) for (a in ANOS_ESTUDO) {
  d <- dados_mapa(malha, ind, lisa, ag, a)
  m1 <- mapa_incidencia(d, ag, a)
  m2 <- mapa_lisa(d, ag, a)
  f1 <- file.path(pasta, sprintf("incidencia_%s_%d.png", ag, a))
  f2 <- file.path(pasta, sprintf("lisa_%s_%d.png", ag, a))
  ggplot2::ggsave(f1, m1, width = 8, height = 5.5, dpi = 300, bg = "white")
  ggplot2::ggsave(f2, m2, width = 8, height = 5.5, dpi = 300, bg = "white")
  gerados <- c(gerados, f1, f2)
  d$agente_rotulo <- ROTULOS_AGENTE[[ag]]; d$ano_rotulo <- a
  paineis_lisa[[length(paineis_lisa) + 1]] <- d
}

# Painel LISA 3 × 4: a mesma legenda para os 12 mapas (as classes são as mesmas).
todos <- do.call(rbind, paineis_lisa)
todos$categoria <- categoria_lisa(todos$quadrante, todos$nivel)
todos$agente_rotulo <- factor(todos$agente_rotulo, levels = ROTULOS_AGENTE)
instaveis <- todos[todos$instavel, ]
hach <- do.call(rbind, lapply(split(instaveis, list(instaveis$agente_rotulo, instaveis$ano_rotulo), drop = TRUE),
                              function(x) { h <- hachurar(x); h$agente_rotulo <- x$agente_rotulo[1]; h$ano_rotulo <- x$ano_rotulo[1]; h }))
painel_lisa <- ggplot2::ggplot(todos) +
  ggplot2::geom_sf(ggplot2::aes(fill = categoria), colour = "white", linewidth = 0.08, show.legend = TRUE) +
  ggplot2::geom_sf(data = hach, colour = "grey25", linewidth = 0.15) +
  escala_lisa() +
  ggplot2::facet_grid(agente_rotulo ~ ano_rotulo) +
  ggplot2::labs(title = "Agrupamentos espaciais de SRAG por agente e ano, Estado do Rio de Janeiro",
                subtitle = "Cor cheia: confirmado após correção FDR. Cor clara: indicativo, sem correção. Hachura: classe instável (um único vizinho).",
                caption = "LISA sobre a taxa suavizada por Bayes empírico, vizinhança Queen, 9.999 permutações (ADR-0004). Fontes: SIVEP-Gripe, IBGE.") +
  tema_mapa(9) + ggplot2::theme(legend.position = "bottom", strip.text = ggplot2::element_text(face = "bold"))
f <- file.path(pasta, "painel_lisa.png")
ggplot2::ggsave(f, painel_lisa, width = 13, height = 9, dpi = 300, bg = "white")
gerados <- c(gerados, f)

# Painel de incidência: 1 linha por agente, 4 anos, escala COMUM por agente
# (dentro de um agente os anos são comparáveis; entre agentes não).
paineis <- lapply(AGENTES, function(ag) {
  x <- todos[todos$agente == ag, ]
  ggplot2::ggplot(x) +
    ggplot2::geom_sf(ggplot2::aes(fill = incid_eb_100k), colour = "white", linewidth = 0.08) +
    escala_incidencia(ag, name = "por 100 mil", trans = "sqrt") +
    ggplot2::facet_wrap(~ano_rotulo, nrow = 1) +
    ggplot2::labs(title = ROTULOS_AGENTE[[ag]]) +
    tema_mapa(9) + ggplot2::theme(legend.position = "right")
})
f <- file.path(pasta, "painel_incidencia.png")
png(f, width = 13, height = 10, units = "in", res = 300, bg = "white")
grid::grid.newpage()
lay <- grid::grid.layout(4, 1, heights = grid::unit(c(0.06, 0.31, 0.31, 0.32), "npc"))
grid::pushViewport(grid::viewport(layout = lay))
grid::grid.text("Incidência de SRAG por agente (taxa suavizada por Bayes empírico, escala raiz quadrada, comum aos 4 anos de cada agente)",
                vp = grid::viewport(layout.pos.row = 1), gp = grid::gpar(fontsize = 12, fontface = "bold"))
for (k in seq_along(paineis)) print(paineis[[k]], vp = grid::viewport(layout.pos.row = k + 1))
invisible(dev.off())
gerados <- c(gerados, f)

# Escala regional (CS-030): taxa bruta regional, nome e valor escritos em cada região.
regioes_rj <- readRDS(file.path("dados", "processados", "regioes_saude_rj.rds"))
ind_reg <- as.data.frame(arrow::read_parquet(file.path("dados", "processados", "indicadores_regionais.parquet")))
pop2022 <- as.data.frame(arrow::read_parquet(file.path("dados", "processados", "populacao_rj.parquet")))
pop2022 <- pop2022[pop2022$ano == 2022, ]
municipio_regiao <- as.data.frame(arrow::read_parquet(file.path("dados", "processados", "municipio_regiao.parquet")))
pontos <- pontos_rotulo_regioes(malha, municipio_regiao, pop2022)
for (ag in AGENTES) for (a in ANOS_ESTUDO) {
  f <- file.path(pasta, sprintf("regional_%s_%d.png", ag, a))
  ggplot2::ggsave(f, mapa_regional(regioes_rj, ind_reg, ag, a, malha = malha, pontos = pontos),
                  width = 8, height = 5.5, dpi = 300, bg = "white")
  gerados <- c(gerados, f)
}

# Série por semana epidemiológica (CS-032): estado e cada região de saúde.
casos <- arrow::read_parquet(file.path("dados", "processados", "sivep_processado.parquet"))
serie <- serie_semanal(casos, municipio_regiao)
utils::write.csv(serie, file.path("resultados", "tabelas", "serie_semanal.csv"), row.names = FALSE, fileEncoding = "UTF-8")
campanhas <- ler_campanhas_influenza()
pasta_est <- file.path("resultados", "estatistica")
sem_acento <- function(x) gsub("[^a-z0-9]+", "_", chartr("áâãàéêíóôõúç", "aaaaeeiooouc", tolower(x)))
graficos <- character(0)
for (r in unique(serie$recorte)) {
  f <- file.path(pasta_est, paste0("serie_semanal_", if (r == "Estado do Rio de Janeiro") "estado" else sem_acento(r), ".png"))
  ggplot2::ggsave(f, grafico_serie_semanal(serie, r, campanhas), width = 10, height = 4.5, dpi = 150, bg = "white")
  graficos <- c(graficos, f)
}
# Painel das 9 regiões para o relatório: eixo y livre (a Metropolitana I tem 38 vezes a população da menor).
reg <- serie[serie$recorte != "Estado do Rio de Janeiro", ]
reg$agente_rotulo <- factor(ROTULOS_AGENTE[reg$agente], levels = ROTULOS_AGENTE)
painel_series <- ggplot2::ggplot(reg, ggplot2::aes(inicio_semana, casos, colour = agente_rotulo)) +
  ggplot2::geom_vline(xintercept = campanhas$inicio, linetype = "dashed", colour = "grey55", linewidth = 0.3) +
  ggplot2::geom_line(linewidth = 0.6) +
  ggplot2::facet_wrap(~recorte, ncol = 3, scales = "free_y") +
  escala_cor_agente() +
  ggplot2::scale_x_date(date_breaks = "1 year", date_labels = "%Y") +
  ggplot2::labs(title = "Casos de SRAG por semana epidemiológica e região de saúde",
                subtitle = "Escala vertical própria de cada região. Tracejado: início da campanha nacional contra influenza",
                x = NULL, y = "Casos por semana", caption = "Fontes: SIVEP-Gripe (critério do ADR-0002), Ministério da Saúde.") +
  ggplot2::theme_minimal(base_size = 9) +
  ggplot2::theme(legend.position = "top", plot.title = ggplot2::element_text(face = "bold"),
                 strip.text = ggplot2::element_text(face = "bold"), panel.grid.minor = ggplot2::element_blank())
f <- file.path(pasta_est, "serie_semanal_painel_regioes.png")
ggplot2::ggsave(f, painel_series, width = 11, height = 8, dpi = 150, bg = "white")
graficos <- c(graficos, f)

# Maturação do último ano (CS-035).
nao_enc_sem <- utils::read.csv(file.path("resultados", "tabelas", "nao_encerrados_semanal.csv"))
versao_ult <- ler_fontes()$sivep$bancos[[length(ler_fontes()$sivep$bancos)]]$versao
f <- file.path(pasta_est, sprintf("nao_encerrados_%d.png", max(ANOS_ESTUDO)))
ggplot2::ggsave(f, grafico_nao_encerrados(nao_enc_sem, versao_ult), width = 9, height = 4.5, dpi = 150, bg = "white")
graficos <- c(graficos, f)
# Taxa × leitos (CS-034).
leitos <- as.data.frame(arrow::read_parquet(file.path("dados", "processados", "leitos_rj.parquet")))
sp <- utils::read.csv(file.path("resultados", "estatistica", "spearman_leitos.csv"), encoding = "UTF-8")
f <- file.path(pasta_est, "leitos_x_incidencia.png")
ggplot2::ggsave(f, grafico_leitos(ind, leitos, sp), width = 11, height = 6, dpi = 150, bg = "white")
graficos <- c(graficos, f)
# Guia de cores (CS-046).
f <- file.path(pasta_est, "guia_cores.png")
ggplot2::ggsave(f, grafico_guia_cores(), width = 9, height = 5.2, dpi = 150, bg = "white")
graficos <- c(graficos, f)

# Bruta × padronizada por idade (CS-033).
f <- file.path(pasta_est, "padronizacao_bruta_vs_padronizada.png")
ggplot2::ggsave(f, grafico_padronizacao(ind), width = 11, height = 8, dpi = 150, bg = "white")
graficos <- c(graficos, f)
stopifnot(all(file.exists(graficos)), length(graficos) == 1 + 9 + 1 + 1 + 1 + 1 + 1)

stopifnot(all(file.exists(gerados)), length(gerados) == 38)
message(sprintf("%d mapas gravados em %s", length(gerados), pasta))
