# 01_etl_sivep.R — baixa, confere e prepara o SIVEP-Gripe do RJ
#
# Entrega atual (CS-005, CS-006, CS-007, CS-008):
#   dados/brutos/INFLUD*.parquet              bancos anuais, registrados no manifesto
#   dados/intermediarios/sivep_rj.parquet     fichas de SRAG de residentes do RJ, tipadas
#   resultados/tabelas/diagnostico_sivep.csv  anomalias contadas por ano (não corrigidas)
#   dados/processados/sivep_processado.parquet  casos confirmados pela regra do ADR-0002 (CS-008)
#   resultados/tabelas/casos_por_agente.csv, subtipo_influenza.csv, codeteccao_casos.csv
#   dados/processados/sivep_notificados_de_fora.parquet  casos notificados no RJ de quem mora fora (CS-031)
#   resultados/tabelas/nao_encerrados.csv                fichas com CLASSI_FIN vazio por ano (CS-035)
#   resultados/tabelas/nao_encerrados_semanal.csv        a mesma proporção por semana do último ano (CS-035)

source("00_setup.R")

baixar_sivep()

sivep_rj <- preparar_sivep()
arrow::write_parquet(sivep_rj, file.path("dados", "intermediarios", "sivep_rj.parquet"))

diagnostico <- diagnosticar_sivep(sivep_rj)
utils::write.csv(diagnostico, file.path("resultados", "tabelas", "diagnostico_sivep.csv"),
                 row.names = FALSE, fileEncoding = "UTF-8")
print(diagnostico)

# CS-035: fichas não encerradas. Tem de bater com a coluna do diagnóstico, que conta o mesmo.
nao_enc <- resumir_nao_encerrados(sivep_rj)
stopifnot(identical(nao_enc$nao_encerradas, diagnostico$classi_fin_vazio[match(nao_enc$ano, diagnostico$ano)]))
nao_enc_sem <- nao_encerrados_por_semana(sivep_rj, max(ANOS_ESTUDO))
stopifnot(sum(nao_enc_sem$fichas) == nao_enc$fichas[nao_enc$ano == max(ANOS_ESTUDO)])
utils::write.csv(nao_enc, file.path("resultados", "tabelas", "nao_encerrados.csv"), row.names = FALSE, fileEncoding = "UTF-8")
utils::write.csv(nao_enc_sem, file.path("resultados", "tabelas", "nao_encerrados_semanal.csv"), row.names = FALSE, fileEncoding = "UTF-8")

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

# Classificação por agente (CS-008), com a regra aceita no ADR-0002 (D-04).
casos <- aplicar_criterios_inclusao(classificar_agente(sivep_rj, REGRA_CASO))
por_agente <- contar_casos_agente(casos)

# Aceite do CS-008: a contagem tem de ser idêntica à linha da regra na tabela da decisão.
linha_adr <- tabelas_adr$comparacao_regras_caso
linha_adr <- linha_adr[linha_adr$regra == REGRA_CASO & linha_adr$agente %in% AGENTES, ]
conferencia <- merge(por_agente, linha_adr, by = c("agente", "ano"), suffixes = c("", "_adr"))
if (nrow(conferencia) != length(AGENTES) * length(ANOS_ESTUDO) ||
    any(conferencia$casos != conferencia$casos_adr)) {
  stop("Casos classificados diferem da tabela do ADR-0002 para a regra ", REGRA_CASO, call. = FALSE)
}

arrow::write_parquet(casos, file.path("dados", "processados", "sivep_processado.parquet"))

# CS-031: o complemento para contar por município de notificação. Mesma regra de
# caso; fica em arquivo separado para não entrar em nenhuma contagem por residência.
casos_de_fora <- aplicar_criterios_inclusao(classificar_agente(preparar_sivep_notificados_de_fora(), REGRA_CASO))
arrow::write_parquet(casos_de_fora, file.path("dados", "processados", "sivep_notificados_de_fora.parquet"))
message(sprintf("CS-031: %d casos notificados no RJ de residentes de fora do RJ", nrow(casos_de_fora)))
utils::write.csv(por_agente, file.path("resultados", "tabelas", "casos_por_agente.csv"),
                 row.names = FALSE, fileEncoding = "UTF-8")
subtipo <- as.data.frame(table(ano = casos$ano_banco[casos$agente == "influenza"],
                               subtipo = casos$subtipo_influenza[casos$agente == "influenza"],
                               useNA = "ifany"), stringsAsFactors = FALSE)
utils::write.csv(subtipo, file.path("resultados", "tabelas", "subtipo_influenza.csv"),
                 row.names = FALSE, fileEncoding = "UTF-8")
codet <- as.data.frame(table(agente = casos$agente, ano = casos$ano_banco, codeteccao = casos$codeteccao),
                       stringsAsFactors = FALSE)
utils::write.csv(codet[codet$codeteccao == "TRUE", c("agente", "ano", "Freq")],
                 file.path("resultados", "tabelas", "codeteccao_casos.csv"), row.names = FALSE,
                 fileEncoding = "UTF-8")

message(sprintf("CS-008: %d casos (%s), idênticos à tabela do ADR-0002",
                nrow(casos), paste(names(table(casos$agente)), table(casos$agente), sep = " ", collapse = ", ")))
print(stats::xtabs(casos ~ agente + ano, por_agente))
print(stats::xtabs(Freq ~ ano + subtipo, subtipo, addNA = TRUE))
