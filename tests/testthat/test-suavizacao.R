# Testes da suavização empírica de Bayes (CS-013). Sem rede.
# A referência é a fórmula de Marshall (1991) escrita à mão, não a do spdep.

marshall_a_mao <- function(casos, pop) {
  taxa <- casos / pop
  b <- sum(casos) / sum(pop)
  s2 <- sum(pop * (taxa - b)^2) / sum(pop)
  a <- max(0, s2 - b / mean(pop))
  b + a * (taxa - b) / (a + b / pop)
}

grade_eb <- function(casos, pop, agente = "vsr", ano = 2022L) {
  data.frame(cod6 = sprintf("33%04d", seq_along(casos)), agente = agente, ano = ano,
             casos = as.integer(casos), populacao = pop,
             incid_100k = casos / pop * 1e5, stringsAsFactors = FALSE)
}

test_that("a taxa suavizada é a de Marshall (1991), conferida à mão", {
  g <- grade_eb(casos = c(0, 3, 50, 10, 200), pop = c(5000, 4000, 300000, 20000, 6000000))
  s <- suavizar_bayes_empirico(g)
  expect_equal(s$incid_eb_100k, marshall_a_mao(g$casos, g$populacao) * 1e5)
})

test_that("cada taxa suavizada fica entre a taxa bruta e a média do estado", {
  g <- grade_eb(casos = c(0, 3, 50, 10, 200, 1), pop = c(5000, 4000, 300000, 20000, 6000000, 2000))
  s <- suavizar_bayes_empirico(g)
  media <- sum(g$casos) / sum(g$populacao) * 1e5
  lo <- pmin(g$incid_100k, media) - 1e-9
  hi <- pmax(g$incid_100k, media) + 1e-9
  expect_true(all(s$incid_eb_100k >= lo & s$incid_eb_100k <= hi))
})

test_that("município grande quase não muda; pequeno com taxa extrema é puxado", {
  g <- grade_eb(casos = c(3, 300, 30, 20), pop = c(5000, 600000, 60000, 50000))
  s <- suavizar_bayes_empirico(g)
  mudanca <- abs(s$incid_eb_100k - g$incid_100k) / g$incid_100k
  expect_lt(mudanca[2], 0.05)             # 600 mil hab.: menos de 5 %
  expect_gt(mudanca[1], mudanca[2] * 5)   # 5 mil hab. com 60/100 mil: muito mais
  expect_lt(s$incid_eb_100k[1], g$incid_100k[1])
})

test_that("município sem caso sobe para perto da média, não fica em zero", {
  g <- grade_eb(casos = c(0, 40, 50, 60), pop = c(3000, 80000, 90000, 100000))
  s <- suavizar_bayes_empirico(g)
  expect_equal(g$incid_100k[1], 0)
  expect_gt(s$incid_eb_100k[1], 0)
})

test_that("agente × ano sem nenhum caso no estado fica com zero, não NaN", {
  g <- rbind(grade_eb(c(0, 0, 0), c(1000, 2000, 3000), ano = 2022L),
             grade_eb(c(1, 2, 3), c(1000, 2000, 3000), ano = 2023L))
  s <- suavizar_bayes_empirico(g)
  expect_equal(s$incid_eb_100k[s$ano == 2022], c(0, 0, 0))
  expect_false(anyNA(s$incid_eb_100k))
  par <- attr(s, "parametros_eb")
  expect_equal(nrow(par), 2)
  expect_equal(par$media_estado_100k[par$ano == 2022], 0)
})

test_that("taxas iguais: variância nula, encolhimento total para a média", {
  g <- grade_eb(casos = c(10, 20, 30), pop = c(10000, 20000, 30000))  # todas 100/100 mil
  s <- suavizar_bayes_empirico(g)
  expect_equal(s$incid_eb_100k, rep(100, 3))
  expect_true(attr(s, "parametros_eb")$encolhimento_total)
})

test_that("cada agente × ano é suavizado separadamente", {
  g <- rbind(grade_eb(c(1, 100), c(1000, 100000), agente = "vsr"),
             grade_eb(c(50, 1), c(1000, 100000), agente = "influenza"))
  s <- suavizar_bayes_empirico(g)
  expect_equal(s$incid_eb_100k[s$agente == "vsr"], marshall_a_mao(c(1, 100), c(1000, 100000)) * 1e5)
  expect_equal(s$incid_eb_100k[s$agente == "influenza"], marshall_a_mao(c(50, 1), c(1000, 100000)) * 1e5)
})

test_that("o resumo traz uma linha por agente × ano, com a correlação de postos", {
  g <- rbind(grade_eb(c(0, 3, 50, 10), c(5000, 4000, 300000, 20000), ano = 2022L),
             grade_eb(c(1, 3, 40, 12), c(5000, 4000, 300000, 20000), ano = 2023L))
  r <- resumir_suavizacao(suavizar_bayes_empirico(g))
  expect_equal(nrow(r), 2)
  expect_true(all(r$spearman_bruta_eb >= -1 & r$spearman_bruta_eb <= 1))
  expect_equal(r$municipios_sem_caso[r$ano == 2022], 1)
})

# ---- integração com os dados reais (pulado se o pipeline não rodou) ----

test_that("dados reais: taxa suavizada nas 1104 linhas, sem NA, entre bruta e média", {
  withr::local_dir(raiz_projeto)
  skip_if_not(file.exists("dados/processados/indicadores_municipais.parquet"), "02_indicadores.R não rodou")
  ind <- as.data.frame(arrow::read_parquet("dados/processados/indicadores_municipais.parquet"))
  expect_true("incid_eb_100k" %in% names(ind))
  expect_equal(nrow(ind), 1104)
  expect_false(anyNA(ind$incid_eb_100k))
  media <- stats::ave(ind$casos, ind$agente, ind$ano, FUN = sum) /
           stats::ave(ind$populacao, ind$agente, ind$ano, FUN = sum) * 1e5
  expect_true(all(ind$incid_eb_100k >= pmin(ind$incid_100k, media) - 1e-9 &
                  ind$incid_eb_100k <= pmax(ind$incid_100k, media) + 1e-9))
})
