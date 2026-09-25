# 02_indicadores.R — denominadores populacionais, casos e incidência
#
#   dados/externos/sidra_*.json                          respostas do SIDRA, no manifesto (CS-011)
#   dados/processados/populacao_rj.parquet               92 municípios × 4 anos (CS-011)
#   resultados/tabelas/diagnostico_populacao.csv         Censo 2022 × estimativas (ADR-0003)
#   dados/processados/indicadores_municipais.parquet     92 × 3 agentes × 4 anos (CS-012)
#   dados/processados/indicadores_quadrimestrais.parquet 92 × 3 × 4 anos × 3 quadrimestres (CS-012)
#   resultados/tabelas/incidencia_estado.csv             totais do estado, dois denominadores
#   resultados/tabelas/indicadores_municipais.csv        a mesma grade anual, para leitura

source("00_setup.R")

# ---- população (CS-011) ----
obter_populacao()
populacao <- montar_populacao(metodo_ausente = "interpolacao")  # ADR-0003, opção A no ano
arrow::write_parquet(populacao, file.path("dados", "processados", "populacao_rj.parquet"))
diag_pop <- diagnosticar_populacao()
utils::write.csv(diag_pop, file.path("resultados", "tabelas", "diagnostico_populacao.csv"),
                 row.names = FALSE, fileEncoding = "UTF-8")

# ---- casos e incidência (CS-012) ----
casos <- arrow::read_parquet(file.path("dados", "processados", "sivep_processado.parquet"))
municipios <- sort(unique(populacao$cod6))

anual <- calcular_incidencia(
  completar_municipios(calcular_casos(casos), municipios),
  populacao
)
quadrimestral <- calcular_incidencia(
  completar_municipios(calcular_casos(casos, por_quadrimestre = TRUE), municipios,
                       quadrimestres = 1:3),
  populacao
)

# Contratos da trilha §3.2: grade completa, sem NA, nenhum caso perdido.
esperado_anual <- length(municipios) * length(AGENTES) * length(ANOS_ESTUDO)
if (nrow(anual) != esperado_anual) stop("Grade anual com ", nrow(anual), " linhas; esperado ", esperado_anual)
if (nrow(quadrimestral) != esperado_anual * 3) stop("Grade quadrimestral incompleta")
if (anyNA(anual[, c("casos", "incid_100k", "incid_100k_pop2024")])) stop("NA na grade anual")
if (sum(anual$casos) != nrow(casos) || sum(quadrimestral$casos) != nrow(casos)) {
  stop("A soma da grade difere do número de casos classificados", call. = FALSE)
}

arrow::write_parquet(anual, file.path("dados", "processados", "indicadores_municipais.parquet"))
arrow::write_parquet(quadrimestral, file.path("dados", "processados", "indicadores_quadrimestrais.parquet"))
utils::write.csv(anual, file.path("resultados", "tabelas", "indicadores_municipais.csv"),
                 row.names = FALSE, fileEncoding = "UTF-8")
estado <- resumir_incidencia_estado(anual)
utils::write.csv(estado, file.path("resultados", "tabelas", "incidencia_estado.csv"),
                 row.names = FALSE, fileEncoding = "UTF-8")

message(sprintf("Grade anual: %d linhas, %d casos, %d combinações com zero caso",
                nrow(anual), sum(anual$casos), sum(anual$casos == 0)))
print(estado, row.names = FALSE, digits = 4)
