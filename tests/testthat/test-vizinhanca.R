# Testes da vizinhança e dos pesos (CS-016).
# Grade sintética de quadrados, com resposta conhecida à mão.

# n × n quadrados de lado 1, com cod6 fictício "000001", "000002"... por linha.
grade <- function(n = 3) {
  quadrados <- list()
  for (i in 0:(n - 1)) for (j in 0:(n - 1)) {
    quadrados[[length(quadrados) + 1]] <- sf::st_polygon(list(rbind(
      c(j, i), c(j + 1, i), c(j + 1, i + 1), c(j, i + 1), c(j, i))))
  }
  sf::st_sf(cod6 = sprintf("%06d", seq_along(quadrados)),
            nome = paste0("Q", seq_along(quadrados)),
            geometry = sf::st_sfc(quadrados))
}

test_that("Queen numa grade 3×3: canto 3, borda 5, centro 8 vizinhos", {
  nb <- criar_vizinhos_queen(grade(3))
  expect_equal(spdep::card(nb), c(3, 5, 3, 5, 8, 5, 3, 5, 3))
  expect_equal(contar_ligacoes(nb), 40)
})

test_that("Rook na mesma grade ignora os toques só de canto", {
  nb <- criar_vizinhos_queen(grade(3), queen = FALSE)
  expect_equal(spdep::card(nb), c(2, 3, 2, 3, 4, 3, 2, 3, 2))
  expect_equal(contar_ligacoes(nb), 24)
})

test_that("a vizinhança carrega o cod6, e a ordem de entrada não importa", {
  g <- grade(3)
  nb <- criar_vizinhos_queen(g)
  expect_equal(attr(nb, "region.id"), g$cod6)
  embaralhada <- g[c(9, 1, 5, 3, 7, 2, 8, 4, 6), ]
  nb2 <- criar_vizinhos_queen(embaralhada)
  # vizinhos do centro (000005), procurados pela chave, são os mesmos 8
  centro <- which(attr(nb2, "region.id") == "000005")
  expect_setequal(attr(nb2, "region.id")[nb2[[centro]]], setdiff(g$cod6, "000005"))
})

test_that("município isolado para com erro, em vez de peso zero", {
  g <- grade(2)
  ilha <- sf::st_sf(cod6 = "999999", nome = "Ilha",
                    geometry = sf::st_sfc(sf::st_polygon(list(rbind(
                      c(10, 10), c(11, 10), c(11, 11), c(10, 11), c(10, 10))))))
  # o spdep avisa do caso antes de a função parar: aviso esperado
  suppressWarnings(expect_error(criar_vizinhos_queen(rbind(g, ilha)), "sem vizinho: 999999"))
})

test_that("dois blocos desconectados param com erro", {
  a <- grade(2)
  b <- grade(2)
  b$cod6 <- sprintf("%06d", 11:14)
  sf::st_geometry(b) <- sf::st_geometry(b) + c(10, 10)
  # o spdep avisa do caso antes de a função parar: aviso esperado
  suppressWarnings(expect_error(criar_vizinhos_queen(rbind(a, b)), "2 blocos desconectados"))
})

test_that("cod6 repetido para com erro", {
  g <- grade(2)
  g$cod6[2] <- g$cod6[1]
  expect_error(criar_vizinhos_queen(g), "cod6 repetido")
})

test_that("pesos estilo W: cada linha soma 1 e divide igualmente entre os vizinhos", {
  w <- criar_pesos(criar_vizinhos_queen(grade(3)))
  expect_equal(w$style, "W")
  expect_equal(vapply(w$weights, sum, numeric(1)), rep(1, 9))
  expect_equal(w$weights[[5]], rep(1 / 8, 8))  # centro: 8 vizinhos, 1/8 cada
  expect_equal(w$weights[[1]], rep(1 / 3, 3))  # canto: 3 vizinhos
})

test_that("resumo lista os vizinhos pelo nome", {
  g <- grade(3)
  r <- resumir_vizinhanca(criar_vizinhos_queen(g), g)
  expect_equal(r$n_vizinhos[r$cod6 == "000001"], 3)
  expect_equal(r$vizinhos[r$cod6 == "000001"], "Q2; Q4; Q5")
})

# ---- integração com a malha real ----

test_that("malha real do RJ: 456 ligações Queen, 1 bloco, todo município com vizinho", {
  withr::local_dir(raiz_projeto)
  skip_if_not(file.exists("dados/externos/RJ_Municipios_2022.zip"), "malha não baixada")
  m <- ler_malha_municipal()
  nb <- criar_vizinhos_queen(m)
  expect_equal(length(nb), 92)
  expect_equal(contar_ligacoes(nb), 456)
  expect_equal(spdep::n.comp.nb(nb)$nc, 1)
  expect_gte(min(spdep::card(nb)), 1)
  # dois pares que a malha simplificada do geobr perdia (ADR-0006)
  viz <- function(a) attr(nb, "region.id")[nb[[which(attr(nb, "region.id") == a)]]]
  expect_true("330555" %in% viz("330455"))  # Rio de Janeiro — Seropédica
  expect_true("330510" %in% viz("330285"))  # Mesquita — São João de Meriti
  # a vizinhança é simétrica: se A é vizinho de B, B é vizinho de A
  expect_true(spdep::is.symmetric.nb(nb, verbose = FALSE))
})
