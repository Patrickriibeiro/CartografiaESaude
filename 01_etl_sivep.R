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

# Evidência do ADR-0002 (CS-007): quantos casos cada regra candidata conta,
# onde está o laboratório das fichas sem campo específico, e co-detecções.
tabelas_adr <- list(
  comparacao_regras_caso = comparar_regras_caso(sivep_rj),
  decomposicao_sem_campo_especifico = decompor_sem_campo_especifico(sivep_rj),
  codeteccao_por_regra = do.call(rbind, lapply(names(REGRAS_CASO), function(r) resumir_codeteccao(sivep_rj, r)))
)
for (nome in names(tabelas_adr)) {
  utils::write.csv(tabelas_adr[[nome]], file.path("resultados", "tabelas", paste0(nome, ".csv")),
                   row.names = FALSE, fileEncoding = "UTF-8")
}
print(stats::xtabs(casos ~ regra + agente + ano, tabelas_adr$comparacao_regras_caso))

message("Classificação por agente ainda não implementada (CS-008): aguarda a regra aceita no ADR-0002 (D-04).")
