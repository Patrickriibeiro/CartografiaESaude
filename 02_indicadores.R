# 02_indicadores.R — denominadores populacionais, casos e incidência
#
#   dados/externos/sidra_*.json                          respostas do SIDRA, no manifesto (CS-011)
#   dados/processados/populacao_rj.parquet               92 municípios × 4 anos (CS-011)
#   resultados/tabelas/diagnostico_populacao.csv         Censo 2022 × estimativas (ADR-0003)
#   dados/processados/indicadores_municipais.parquet     92 × 3 agentes × 4 anos (CS-012)
#   dados/processados/indicadores_quadrimestrais.parquet 92 × 3 × 4 anos × 3 quadrimestres (CS-012)
#   resultados/tabelas/incidencia_estado.csv             totais do estado, dois denominadores
#   resultados/tabelas/indicadores_municipais.csv        a mesma grade anual, para leitura
#   resultados/tabelas/suavizacao_bayes_empirico.csv     resumo da suavização (CS-013)
#   resultados/estatistica/ebayes_bruta_vs_suavizada.png dispersão bruta × suavizada (CS-013)
#   dados/processados/residencia_notificacao.parquet     casos por residência e por notificação, 92 × 3 × 4 (CS-031)
#   resultados/tabelas/residencia_notificacao.csv        uma linha por município, com razão e saldo (CS-031)

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
anual <- suavizar_bayes_empirico(anual)   # CS-013, D-09: o LISA usa incid_eb_100k
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

# ---- suavização (CS-013) ----
suav <- resumir_suavizacao(anual)
utils::write.csv(suav, file.path("resultados", "tabelas", "suavizacao_bayes_empirico.csv"),
                 row.names = FALSE, fileEncoding = "UTF-8")
grafico_eb <- ggplot2::ggplot(anual, ggplot2::aes(incid_100k, incid_eb_100k)) +
  ggplot2::geom_abline(slope = 1, intercept = 0, colour = "grey60", linetype = "dashed") +
  ggplot2::geom_point(ggplot2::aes(size = populacao), alpha = 0.5, colour = "#3b6e8f") +
  ggplot2::scale_size_area(max_size = 5, labels = scales::label_number(big.mark = ".", decimal.mark = ","),
                           name = "População") +
  ggplot2::facet_wrap(agente ~ ano, scales = "free", ncol = 4,
                      labeller = ggplot2::labeller(agente = c(influenza = "Influenza", sarscov2 = "SARS-CoV-2", vsr = "VSR"))) +
  ggplot2::labs(
    title = "Taxa bruta × taxa suavizada por Bayes empírico, por município",
    subtitle = paste("SRAG por 100 mil hab., RJ. Abaixo da diagonal: municípios pequenos com taxa alta, puxados para baixo.",
                     "Sobre o eixo vertical: municípios sem caso, puxados para cima, em direção à média do estado."),
    x = "Taxa bruta", y = "Taxa suavizada (Bayes empírico)",
    caption = "Fontes: SIVEP-Gripe (regra do ADR-0002), IBGE. Suavização global de Marshall (1991)."
  ) +
  ggplot2::theme_minimal(base_size = 9) +
  ggplot2::theme(legend.position = "bottom")
ggplot2::ggsave(file.path("resultados", "estatistica", "ebayes_bruta_vs_suavizada.png"),
                grafico_eb, width = 11, height = 8, dpi = 150, bg = "white")
utils::write.csv(estado, file.path("resultados", "tabelas", "incidencia_estado.csv"),
                 row.names = FALSE, fileEncoding = "UTF-8")

message(sprintf("Grade anual: %d linhas, %d casos, %d combinações com zero caso",
                nrow(anual), sum(anual$casos), sum(anual$casos == 0)))
print(estado, row.names = FALSE, digits = 4)
print(suav[, c("agente", "ano", "municipios_sem_caso", "bruta_max_100k", "eb_max_100k",
               "spearman_bruta_eb", "mudanca_mediana_pct", "encolhimento_total")], row.names = FALSE, digits = 3)

# ---- residência × notificação (CS-031) ----
casos_de_fora <- arrow::read_parquet(file.path("dados", "processados", "sivep_notificados_de_fora.parquet"))
rn <- comparar_residencia_notificacao(casos, casos_de_fora, municipios)
stopifnot(nrow(rn) == esperado_anual, identical(rn$casos_res, anual$casos[order(anual$cod6, anual$agente, anual$ano)]))
arrow::write_parquet(rn, file.path("dados", "processados", "residencia_notificacao.parquet"))
rn_mun <- resumir_residencia_notificacao(rn)
utils::write.csv(rn_mun, file.path("resultados", "tabelas", "residencia_notificacao.csv"),
                 row.names = FALSE, fileEncoding = "UTF-8")
message(sprintf("Residência × notificação: %d casos por residência, %d por notificação no RJ; %d municípios com saldo positivo",
                sum(rn$casos_res), sum(rn$casos_not), sum(rn_mun$saldo > 0)))
