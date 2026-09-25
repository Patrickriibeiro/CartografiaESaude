# 02_indicadores.R — denominadores populacionais e, depois, incidência
#
# Entrega atual (CS-011):
#   dados/externos/sidra_*.json                   respostas do SIDRA, no manifesto
#   dados/processados/populacao_rj.parquet        92 municípios × 4 anos
#   resultados/tabelas/diagnostico_populacao.csv  Censo 2022 × estimativas (ADR-0003)
# Casos e incidência (grade 92 × 3 × 4): CS-012.

source("00_setup.R")

obter_populacao()

populacao <- montar_populacao(metodo_ausente = "interpolacao")  # D-05 / ADR-0003
arrow::write_parquet(populacao, file.path("dados", "processados", "populacao_rj.parquet"))
print(aggregate(populacao ~ ano + fonte, data = populacao, FUN = sum))

diag_pop <- diagnosticar_populacao()
utils::write.csv(diag_pop, file.path("resultados", "tabelas", "diagnostico_populacao.csv"),
                 row.names = FALSE, fileEncoding = "UTF-8")

message("Casos e incidência ainda não implementados (CS-012).")
