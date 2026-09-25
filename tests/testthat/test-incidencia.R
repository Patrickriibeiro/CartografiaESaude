# Testes de casos e incidência (CS-012). Sem rede.

# População FABRICADA para uma lista de municípios: valores redondos para a conta
# poder ser feita de cabeça. 2024 é diferente dos outros anos de propósito, para
# as duas taxas da D-05 darem números diferentes.
populacao_falsa <- function(cod6, anos = 2022:2025) {
  do.call(rbind, lapply(anos, function(a) data.frame(
    cod6 = cod6, ano = as.integer(a),
    populacao = if (a == 2024) 50000L else 40000L,
    fonte = paste("FABRICADA", a), stringsAsFactors = FALSE)))
}

casos_falsos <- function() {
  data.frame(
    CO_MUN_RES = c("330010", "330010", "330010", "330020", "330020"),
    agente = factor(c("sarscov2", "sarscov2", "vsr", "influenza", "sarscov2"), levels = AGENTES),
    ano_banco = c(2022L, 2022L, 2022L, 2025L, 2025L),
    semana_epi = c(17L, 18L, 53L, 1L, 34L)
  )
}

test_that("quadrimestre epidemiológico: semanas 1–17, 18–34, 35–53", {
  expect_equal(quadrimestre_epi(c(1L, 17L, 18L, 34L, 35L, 52L, 53L, NA)),
               c(1L, 1L, 2L, 2L, 3L, 3L, 3L, NA))
  expect_error(quadrimestre_epi(54L), "fora de 1–53")
})

test_that("calcular_casos conta por município, agente e ano (e quadrimestre)", {
  c1 <- calcular_casos(casos_falsos())
  expect_equal(c1$casos[c1$cod6 == "330010" & c1$agente == "sarscov2" & c1$ano == 2022], 2)
  expect_equal(sum(c1$casos), 5)
  c2 <- calcular_casos(casos_falsos(), por_quadrimestre = TRUE)
  expect_equal(nrow(c2[c2$cod6 == "330010" & c2$agente == "sarscov2", ]), 2)  # semanas 17 e 18
  expect_equal(sum(c2$casos), 5)
})

test_that("a grade completa tem toda combinação, com zero explícito", {
  mun <- c("330010", "330020", "330030")
  g <- completar_municipios(calcular_casos(casos_falsos()), mun)
  expect_equal(nrow(g), 3 * 3 * 4)
  expect_equal(sum(g$casos), 5)
  expect_true(all(g$casos[g$cod6 == "330030"] == 0))  # município sem caso aparece
  expect_false(anyNA(g$casos))
  expect_type(g$casos, "integer")
})

test_that("remover um município do input não o tira da grade (aceite do CS-012)", {
  mun <- c("330010", "330020", "330030")
  sem_330020 <- casos_falsos()[casos_falsos()$CO_MUN_RES != "330020", ]
  g <- completar_municipios(calcular_casos(sem_330020), mun)
  expect_equal(nrow(g), 36)
  expect_equal(sum(g$cod6 == "330020"), 12)
  expect_true(all(g$casos[g$cod6 == "330020"] == 0))
})

test_that("grade quadrimestral tem 3 períodos por ano", {
  g <- completar_municipios(calcular_casos(casos_falsos(), TRUE), c("330010", "330020"),
                            quadrimestres = 1:3)
  expect_equal(nrow(g), 2 * 3 * 4 * 3)
  expect_equal(sum(g$casos), 5)
})

test_that("município com caso fora da lista para com erro", {
  expect_error(completar_municipios(calcular_casos(casos_falsos()), "330010"),
               "fora da lista de municípios: 330020")
})

test_that("as duas taxas da D-05: população do ano e estimativa 2024 em todos os anos", {
  mun <- c("330010", "330020", "330030")
  ind <- calcular_incidencia(completar_municipios(calcular_casos(casos_falsos()), mun),
                             populacao_falsa(mun))
  x <- ind[ind$cod6 == "330010" & ind$agente == "sarscov2" & ind$ano == 2022, ]
  expect_equal(x$incid_100k, 2 / 40000 * 1e5)          # 5 por 100 mil
  expect_equal(x$incid_100k_pop2024, 2 / 50000 * 1e5)  # 4 por 100 mil
  expect_equal(x$fonte_populacao, "FABRICADA 2022")
  # em 2024 as duas taxas coincidem
  y <- ind[ind$ano == 2024, ]
  expect_equal(y$incid_100k, y$incid_100k_pop2024)
  # zero caso = taxa zero, não NA
  expect_true(all(ind$incid_100k[ind$cod6 == "330030"] == 0))
})

test_that("falta de população para alguma linha para com erro", {
  mun <- c("330010", "330020", "330030")
  g <- completar_municipios(calcular_casos(casos_falsos()), mun)
  pop <- populacao_falsa(mun)
  expect_error(calcular_incidencia(g, pop[!(pop$cod6 == "330030" & pop$ano == 2023), ]),
               "sem população")
  expect_error(calcular_incidencia(g, pop[pop$ano != 2024, ]), "Sem população de 2024")
})

test_that("o resumo do estado soma casos e populações antes de dividir", {
  mun <- c("330010", "330020")
  ind <- calcular_incidencia(completar_municipios(calcular_casos(casos_falsos()), mun),
                             populacao_falsa(mun))
  e <- resumir_incidencia_estado(ind)
  x <- e[e$agente == "sarscov2" & e$ano == 2022, ]
  expect_equal(x$casos, 2)
  expect_equal(x$populacao, 80000)
  expect_equal(x$incid_100k, 2 / 80000 * 1e5)
  expect_equal(nrow(e), 3 * 4)
})

test_that("base sintética: 92 × 3 × 4, os 32 municípios sem caso ficam com zero", {
  projeto_temporario()
  f <- ler_fixture_sivep()
  d <- suppressMessages(preparar_sivep(2022:2025, fontes = bancos_da_fixture(f)))
  casos <- aplicar_criterios_inclusao(classificar_agente(d))
  mun <- sort(unique(f$CO_MUN_RES))
  ind <- calcular_incidencia(completar_municipios(calcular_casos(casos), mun), populacao_falsa(mun))
  expect_equal(nrow(ind), 92 * 3 * 4)
  expect_equal(sum(ind$casos), nrow(casos))
  sem_caso <- setdiff(mun, unique(casos$CO_MUN_RES))
  expect_gte(length(sem_caso), 32)
  expect_true(all(ind$casos[ind$cod6 %in% sem_caso] == 0))
  expect_false(anyNA(ind$incid_100k))
})

# ---- integração com os dados reais (pulado se o pipeline não rodou) ----

test_that("dados reais: grade 1104, soma dos casos preservada, sem NA", {
  withr::local_dir(raiz_projeto)
  skip_if_not(file.exists("dados/processados/indicadores_municipais.parquet"), "02_indicadores.R não rodou")
  ind <- as.data.frame(arrow::read_parquet("dados/processados/indicadores_municipais.parquet"))
  casos <- arrow::read_parquet("dados/processados/sivep_processado.parquet", col_select = "agente")
  expect_equal(nrow(ind), 1104)
  expect_equal(sum(ind$casos), nrow(casos))
  expect_false(anyNA(ind[, c("casos", "incid_100k", "incid_100k_pop2024")]))
  expect_equal(length(unique(ind$cod6)), 92)
  # 2024: os dois denominadores são o mesmo
  expect_equal(ind$incid_100k[ind$ano == 2024], ind$incid_100k_pop2024[ind$ano == 2024])
})

test_that("diagnóstico de zeros: zeros esperados por Poisson e cruzamentos, com conta à mão", {
  ind <- data.frame(cod6 = c("330010", "330020", "330030", "330040"), agente = "vsr", ano = 2022L,
                    casos = c(0L, 0L, 10L, 10L), populacao = c(100, 1000, 10000, 8900))
  notif <- data.frame(cod6 = c("330020", "330030", "330040"), ano = 2022L)
  leitos <- data.frame(cod6 = ind$cod6, ano = 2022L, leitos_sus = c(0, 5, 5, 0))
  d <- diagnosticar_zeros(ind, notif, leitos)
  taxa <- 20 / 20000
  expect_equal(d$zeros, 2L)
  expect_equal(d$zeros_esperados, sum(exp(-ind$populacao * taxa)))   # 0,905 + 0,368 + ~0 + ~0
  expect_equal(d$zeros_sem_notificacao, 1L); expect_equal(d$outros_sem_notificacao, 0L)
  expect_equal(d$zeros_sem_leito, 1L); expect_equal(d$outros_sem_leito, 1L)
  expect_equal(d$pop_mediana_zeros, 550); expect_equal(d$pop_mediana_outros, 9450)
  expect_false("zeros_sem_leito" %in% names(diagnosticar_zeros(ind, notif)))
  # Testagem: o município 330010 tem 4 fichas e 1 testada; 330020, nenhuma ficha.
  f <- data.frame(cod6 = c("330010", "330030", "330040"), ano = 2022L, fichas = c(4L, 10L, 10L), testadas = c(1L, 9L, 9L))
  d2 <- diagnosticar_zeros(ind, notif, leitos, f)
  expect_equal(c(d2$fichas_zeros, d2$zeros_sem_ficha), c(4, 1L))
  expect_equal(c(d2$pct_testadas_zeros, d2$pct_testadas_outros), c(0.25, 0.9))
})
