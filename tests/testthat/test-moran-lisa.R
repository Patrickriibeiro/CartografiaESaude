# Testes do Moran global e do LISA (CS-017) com padrões de resposta conhecida
# (CS-018). Grade de quadrados; `grade()` está em test-vizinhanca.R, então este
# arquivo recria uma versão local para não depender da ordem dos arquivos.

grade_q <- function(n) {
  quadrados <- list()
  for (i in 0:(n - 1)) for (j in 0:(n - 1)) {
    quadrados[[length(quadrados) + 1]] <- sf::st_polygon(list(rbind(
      c(j, i), c(j + 1, i), c(j + 1, i + 1), c(j, i + 1), c(j, i))))
  }
  g <- sf::st_sf(cod6 = sprintf("%06d", seq_along(quadrados)), nome = paste0("Q", seq_along(quadrados)),
                 geometry = sf::st_sfc(quadrados))
  g$linha <- rep(0:(n - 1), each = n); g$coluna <- rep(0:(n - 1), times = n)
  g
}
pesos_grade <- function(g) criar_pesos(criar_vizinhos_queen(g))

test_that("tabuleiro de xadrez: I negativo e significativo sob Rook; perto de zero sob Queen", {
  # Sob Rook, todo vizinho tem a cor oposta: I ≈ -1. Sob Queen, 4 dos 8 vizinhos
  # (as diagonais) têm a MESMA cor, e o efeito quase se cancela. Errar isso foi o
  # primeiro erro deste arquivo (2026-09-25): o teste esperava I < -0,5 sob Queen.
  g <- grade_q(10)
  x <- ifelse((g$linha + g$coluna) %% 2 == 0, 10, 0)
  rook <- criar_pesos(criar_vizinhos_queen(g, queen = FALSE))
  m <- calcular_moran(x, rook, nsim = 999, alternativa = "less")
  expect_lt(m$I, -0.9)
  expect_lt(m$p_perm, 0.01)
  q <- calcular_moran(x, pesos_grade(g), nsim = 999, alternativa = "less")
  expect_gt(q$I, -0.2)
})

test_that("gradiente: I positivo e significativo (similaridade entre vizinhos)", {
  g <- grade_q(10); w <- pesos_grade(g)
  x <- g$linha + g$coluna
  m <- calcular_moran(x, w, nsim = 999)
  expect_gt(m$I, 0.5)
  expect_lt(m$p_perm, 0.01)
  expect_equal(m$esperado_I, -1 / 99)
})

test_that("ruído aleatório: p > 0,05 na maioria de 20 sementes", {
  g <- grade_q(10); w <- pesos_grade(g)
  ps <- vapply(1:20, function(s) {
    set.seed(1000 + s); x <- stats::rnorm(100)
    calcular_moran(x, w, nsim = 499, semente = s)$p_perm
  }, numeric(1))
  expect_gte(sum(ps > 0.05), 15)
})

test_that("mesma semente, mesmo resultado; semente diferente, p pode variar", {
  g <- grade_q(6); w <- pesos_grade(g)
  set.seed(7); x <- stats::rnorm(36)
  expect_identical(calcular_moran(x, w, nsim = 499, semente = 1), calcular_moran(x, w, nsim = 499, semente = 1))
  l1 <- calcular_lisa(x, w, nsim = 499, semente = 1); l2 <- calcular_lisa(x, w, nsim = 499, semente = 1)
  expect_identical(l1$p_perm, l2$p_perm)
})

test_that("quadrantes do diagrama de Moran, conferidos à mão numa grade 3×3", {
  g <- grade_q(3); w <- pesos_grade(g)
  x <- c(1, 1, 1, 1, 9, 1, 1, 1, 1)   # só o centro é alto; média = 1,889
  q <- quadrante_moran(x, w)
  expect_equal(q$quadrante[5], "HL")                 # alto cercado de baixos
  expect_true(all(q$quadrante[-5] == "LH"))          # baixos, mas todos vizinhos do centro alto
  expect_equal(q$z, x - mean(x))
})

test_that("LISA num bloco alto: o bloco sai HH e o resto LL, com alinhamento pela chave", {
  g <- grade_q(8); w <- pesos_grade(g)
  x <- ifelse(g$linha >= 5 & g$coluna >= 5, 100, 0)  # canto superior direito 3×3 alto
  l <- classificar_lisa(calcular_lisa(x, w, nsim = 999))
  expect_equal(nrow(l), 64)
  expect_equal(l$cod6, attr(w, "region.id"))
  bloco <- g$cod6[g$linha >= 6 & g$coluna >= 6]     # miolo do bloco (vizinhos todos altos)
  expect_true(all(l$quadrante[l$cod6 %in% bloco] == "HH"))
  expect_gt(sum(l$nivel == "confirmado"), 0)
  expect_true(all(l$p_fdr >= l$p_perm))
  expect_true(all(l$classe[l$nivel == "ns"] == "ns"))
  expect_true(all(l$classe[l$nivel != "ns"] == l$quadrante[l$nivel != "ns"]))
})

test_that("embaralhar as linhas do dado não muda o resultado: alinhamento é pela chave", {
  g <- grade_q(6); w <- pesos_grade(g)
  df <- data.frame(cod6 = g$cod6, agente = "vsr", ano = 2022L, incid_eb_100k = g$linha * 10 + g$coluna)
  r1 <- executar_moran_lisa(df, w, nsim = 499)
  r2 <- executar_moran_lisa(df[sample(nrow(df)), ], w, nsim = 499)
  expect_identical(r1$global$I, r2$global$I)
  expect_identical(r1$lisa$Ii, r2$lisa$Ii)
  expect_identical(r1$lisa$cod6, attr(w, "region.id"))
})

test_that("dado com município a menos, a mais ou repetido para com erro", {
  g <- grade_q(3); w <- pesos_grade(g)
  df <- data.frame(cod6 = g$cod6, v = 1:9)
  expect_error(alinhar_a_pesos(df[-1, ], w), "1 faltando")
  expect_error(alinhar_a_pesos(rbind(df, data.frame(cod6 = "999999", v = 0)), w), "1 sobrando")
  expect_error(alinhar_a_pesos(rbind(df, df[1, ]), w), "repetida")
})

test_that("classificação: níveis confirmado/indicativo/ns e marca de instável", {
  # BH à mão, m = 5, p ordenados: 0,0001 · 0,0002 · 0,03 · 0,045 · 0,2
  #   ajustado(0,2)    = 0,2
  #   ajustado(0,045)  = min(0,045·5/4, 0,2)      = 0,05625  -> não < 0,05: indicativo
  #   ajustado(0,03)   = min(0,03·5/3, 0,05625)   = 0,05     -> não < 0,05: indicativo
  #   ajustado(0,0002) = min(0,0002·5/2, 0,05)    = 0,0005   -> confirmado
  #   ajustado(0,0001) = min(0,0001·5/1, 0,0005)  = 0,0005   -> confirmado
  l <- data.frame(cod6 = sprintf("%06d", 1:5), p_perm = c(0.0001, 0.03, 0.2, 0.0002, 0.045),
                  quadrante = c("HH", "LL", "HH", "HH", "HL"), n_vizinhos = c(1L, 3L, 4L, 5L, 2L))
  c <- classificar_lisa(l, alfa = 0.05)
  expect_equal(c$p_fdr, c(0.0005, 0.05, 0.2, 0.0005, 0.05625))
  expect_equal(c$nivel, c("confirmado", "indicativo", "ns", "confirmado", "indicativo"))
  expect_equal(c$classe, c("HH", "LL", "ns", "HH", "HL"))
  expect_equal(c$instavel, c(TRUE, FALSE, FALSE, FALSE, FALSE))
})

test_that("resumo conta o esperado por acaso, os níveis e os instáveis", {
  l <- data.frame(agente = "vsr", ano = 2024L, cod6 = sprintf("%06d", 1:5),
                  quadrante = c("HH", "LL", "HH", "HH", "HL"),
                  nivel = c("confirmado", "indicativo", "ns", "confirmado", "indicativo"),
                  instavel = c(TRUE, FALSE, FALSE, FALSE, FALSE))
  r <- resumir_lisa(l, alfa = 0.05)
  expect_equal(r$esperado_por_acaso, 0.25)
  expect_equal(r$sig_sem_correcao, 4); expect_equal(r$sig_fdr, 2)
  expect_equal(r$HH_confirmado, 2); expect_equal(r$LL_indicativo, 1); expect_equal(r$HL_LH_sig, 1)
  expect_equal(r$instaveis_sig, 1)
})

test_that("concordância entre duas classificações", {
  a <- data.frame(agente = "vsr", ano = 2024L, cod6 = sprintf("%06d", 1:4), classe = c("HH", "ns", "LL", "ns"))
  b <- data.frame(agente = "vsr", ano = 2024L, cod6 = sprintf("%06d", 1:4), classe = c("HH", "ns", "ns", "HL"))
  c <- comparar_lisa(a, b)
  expect_equal(c$concordancia, 0.5)
  expect_equal(c$sig_em_ambas, 1); expect_equal(c$sig_so_na_primeira, 1); expect_equal(c$sig_so_na_segunda, 1)
})

# ---- integração com os resultados reais (pulado se o script não rodou) ----

test_that("resultados reais: 12 globais, 92 × 12 locais, sem NA, 3 instáveis por mapa", {
  withr::local_dir(raiz_projeto)
  skip_if_not(file.exists("resultados/estatistica/moran_lisa.rds"), "05_moran_lisa.R não rodou")
  r <- readRDS("resultados/estatistica/moran_lisa.rds")
  expect_equal(nrow(r$principal$global), 12)
  expect_equal(nrow(r$principal$lisa), 92 * 12)
  expect_false(anyNA(r$principal$lisa[, c("Ii", "p_perm", "p_fdr", "classe")]))
  expect_equal(r$nsim, 9999L)
  expect_true(all(tapply(r$principal$lisa$instavel, paste(r$principal$lisa$agente, r$principal$lisa$ano), sum) == 3))
  expect_true(all(r$principal$global$p_perm >= 1 / (r$nsim + 1)))
})
