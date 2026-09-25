# 01_etl_sivep.R — baixa, confere e prepara o SIVEP-Gripe do RJ
#
# Entrega atual (CS-005, CS-006):
#   dados/brutos/INFLUD*.parquet              bancos anuais, registrados no manifesto
#   dados/intermediarios/sivep_rj.parquet     fichas de SRAG de residentes do RJ, tipadas
#   resultados/tabelas/diagnostico_sivep.csv  anomalias contadas por ano (não corrigidas)
# A classificação por agente (→ dados/processados/sivep_processado.parquet) é o CS-008.

source("00_setup.R")

baixar_sivep()

sivep_rj <- preparar_sivep()
arrow::write_parquet(sivep_rj, file.path("dados", "intermediarios", "sivep_rj.parquet"))

diagnostico <- diagnosticar_sivep(sivep_rj)
utils::write.csv(diagnostico, file.path("resultados", "tabelas", "diagnostico_sivep.csv"),
                 row.names = FALSE, fileEncoding = "UTF-8")
print(diagnostico)

message("Classificação por agente ainda não implementada (CS-008).")
