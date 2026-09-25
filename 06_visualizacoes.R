# 06_visualizacoes.R — mapas de incidência e de LISA (CS-019)
#
#   resultados/mapas/incidencia_<agente>_<ano>.png   12 mapas, 300 dpi
#   resultados/mapas/lisa_<agente>_<ano>.png         12 mapas, 300 dpi
#   resultados/mapas/painel_incidencia.png           3 agentes × 4 anos (para o relatório)
#   resultados/mapas/painel_lisa.png                 3 agentes × 4 anos (para o relatório)

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
    ggplot2::scale_fill_viridis_c(option = "magma", direction = -1, begin = 0.1, end = 0.95,
                                  trans = "sqrt", name = "por 100 mil") +
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

stopifnot(all(file.exists(gerados)), length(gerados) == 26)
message(sprintf("%d mapas gravados em %s", length(gerados), pasta))
