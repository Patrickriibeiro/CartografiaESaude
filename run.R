# run.R — executa o pipeline inteiro em ordem, parando no primeiro erro
# Implementação completa (tempos por etapa, log): CS-023.

etapas <- c(
  "01_etl_sivep.R", "02_indicadores.R", "03_cartografia.R",
  "04_pesos_espaciais.R", "05_moran_lisa.R", "06_visualizacoes.R",
  "07_exportacao.R"
)

for (etapa in etapas) {
  message("==> ", etapa)
  source(etapa, encoding = "UTF-8")
}
