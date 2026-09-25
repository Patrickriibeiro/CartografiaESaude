# 04_pesos_espaciais.R — vizinhança Queen e pesos espaciais (CS-016)
#
#   resultados/objetos/vizinhos_queen.rds            objeto nb (region.id = cod6)
#   resultados/objetos/pesos_queen.rds               objeto listw, estilo W
#   resultados/estatistica/vizinhos_por_municipio.csv
#   resultados/estatistica/histograma_vizinhos.png

source("00_setup.R")

municipios_rj <- readRDS(file.path("dados", "processados", "municipios_rj.rds"))

vizinhos <- criar_vizinhos_queen(municipios_rj)
pesos <- criar_pesos(vizinhos)

# Verificação cruzada do ADR-0006: a malha oficial do IBGE tem 456 ligações
# Queen; a simplificada do geobr tinha 440. Outro número = malha trocada.
ligacoes <- contar_ligacoes(vizinhos)
if (ligacoes != 456) {
  stop("Vizinhança com ", ligacoes, " ligações; esperado 456 (ADR-0006)", call. = FALSE)
}

saveRDS(vizinhos, file.path("resultados", "objetos", "vizinhos_queen.rds"))
saveRDS(pesos, file.path("resultados", "objetos", "pesos_queen.rds"))

tabela <- resumir_vizinhanca(vizinhos, municipios_rj)
utils::write.csv(tabela, file.path("resultados", "estatistica", "vizinhos_por_municipio.csv"),
                 row.names = FALSE, fileEncoding = "UTF-8")

grafico <- ggplot2::ggplot(tabela, ggplot2::aes(x = n_vizinhos)) +
  ggplot2::geom_bar(fill = "#3b6e8f") +
  ggplot2::scale_x_continuous(breaks = seq(min(tabela$n_vizinhos), max(tabela$n_vizinhos))) +
  ggplot2::labs(
    title = "Número de vizinhos por município (contiguidade Queen)",
    subtitle = sprintf("Estado do Rio de Janeiro, 92 municípios, %d ligações, 1 bloco conexo",
                       ligacoes),
    x = "Número de municípios vizinhos", y = "Municípios",
    caption = "Fonte: Malha Municipal 2022, IBGE"
  ) +
  ggplot2::theme_minimal(base_size = 11)
ggplot2::ggsave(file.path("resultados", "estatistica", "histograma_vizinhos.png"),
                grafico, width = 7, height = 4.5, dpi = 150, bg = "white")

message(sprintf("Vizinhança Queen: %d municípios, %d ligações, vizinhos por município de %d a %d (mediana %g)",
                length(vizinhos), ligacoes, min(tabela$n_vizinhos), max(tabela$n_vizinhos),
                stats::median(tabela$n_vizinhos)))
