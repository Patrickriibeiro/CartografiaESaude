# Testes da escala de região de saúde (CS-030).
# Grade sintética 3 × 3 de quadrados de 10 km em UTM 23S, levada a SIRGAS 2000
# como a malha real. Cada COLUNA é uma região: 33001 | 33002 | 33003.
# Resposta à mão: 3 regiões, vizinhas só 33001–33002 e 33002–33003 (4 ligações).

malha_sintetica <- function() {
  quadrados <- list(); cod6 <- character(0); coluna <- integer(0)
  for (i in 0:2) for (j in 0:2) {
    x0 <- 600000 + j * 10000; y0 <- 7500000 + i * 10000
    quadrados[[length(quadrados) + 1]] <- sf::st_polygon(list(rbind(
      c(x0, y0), c(x0 + 10000, y0), c(x0 + 10000, y0 + 10000), c(x0, y0 + 10000), c(x0, y0))))
    cod6 <- c(cod6, sprintf("3300%02d", length(quadrados)))
    coluna <- c(coluna, j)
  }
  m <- sf::st_sf(cod6 = cod6, nome = paste0("M", seq_along(cod6)), area_km2 = 100,
                 geometry = sf::st_sfc(quadrados, crs = 31983))
  m <- sf::st_transform(m, EPSG_SIRGAS2000)
  list(malha = m, regioes = data.frame(cod6 = cod6, cod_regiao = sprintf("3300%d", coluna + 1),
                                       stringsAsFactors = FALSE))
}

test_that("validar_regioes põe o nome canônico e para em tabela quebrada", {
  s <- malha_sintetica()
  r <- validar_regioes(s$regioes, n_municipios = 9, n_regioes = 3)
  expect_equal(unique(r$regiao), c("Baía da Ilha Grande", "Baixada Litorânea", "Centro-Sul"))
  expect_error(validar_regioes(s$regioes, n_municipios = 92, n_regioes = 3), "9 municípios; esperado 92")
  expect_error(validar_regioes(s$regioes, n_municipios = 9, n_regioes = 9), "3 regiões; esperado 9")
  dup <- rbind(s$regioes, s$regioes[1, ])
  expect_error(validar_regioes(dup, n_municipios = 10, n_regioes = 3), "mais de uma região")
  estranha <- s$regioes; estranha$cod_regiao[1] <- "35001"
  expect_error(validar_regioes(estranha, n_municipios = 9, n_regioes = 4), "sem nome canônico: 35001")
})

test_that("ler_regioes_saude lê o código numérico do parquet sem notação científica e filtra o RJ", {
  projeto_temporario()
  dir.create("dados/brutos", recursive = TRUE, showWarnings = FALSE)
  # Como no geobr: códigos em double; um município de SP que tem de ficar de fora.
  tab <- data.frame(code_muni = c(3300100, 3300209, 3304557, 3550308),
                    name_muni = c("A", "B", "C", "São Paulo"),
                    code_health_region = c(33001, 33001, 33005, 35016))
  arrow::write_parquet(tab, "dados/brutos/hr.parquet")
  registrar_fonte("dados/brutos/hr.parquet", url = "https://exemplo/hr", descricao = "FABRICADO")
  fontes <- list(regioes_saude = list(destino = "dados/brutos/hr.parquet"))
  r <- ler_regioes_saude(fontes, n_municipios = 3, n_regioes = 2)
  expect_equal(r$cod6, c("330010", "330020", "330455"))
  expect_equal(r$cod_regiao, c("33001", "33001", "33005"))
  expect_equal(r$regiao[3], "Metropolitana I")
})

test_that("dissolver dá uma feição por região, com a área e o número de municípios somados", {
  s <- malha_sintetica()
  rs <- dissolver_regioes(s$malha, s$regioes)
  expect_equal(nrow(rs), 3)
  expect_equal(rs$n_municipios, c(3L, 3L, 3L))
  expect_equal(rs$area_km2, c(300, 300, 300))
  expect_true(all(sf::st_is_valid(rs)))
  # Sem frestas: a coluna dissolvida é UM polígono, com a área de 3 quadrados.
  expect_equal(as.character(sf::st_geometry_type(rs)), rep("POLYGON", 3))
  area <- as.numeric(sf::st_area(sf::st_transform(rs, 31983))) / 1e6
  expect_equal(area, c(300, 300, 300), tolerance = 1e-6)
  expect_equal(sf::st_crs(rs), sf::st_crs(s$malha))
})

test_that("dissolver para se malha e tabela não têm os mesmos municípios", {
  s <- malha_sintetica()
  expect_error(dissolver_regioes(s$malha, s$regioes[-1, ]), "mesmos municípios")
})

test_that("vizinhança das regiões dissolvidas = a implicada pelos municípios", {
  s <- malha_sintetica()
  rs <- dissolver_regioes(s$malha, s$regioes)
  nb_reg <- criar_vizinhos_regionais(rs)
  expect_equal(attr(nb_reg, "region.id"), c("33001", "33002", "33003"))
  expect_equal(pares_de_vizinhanca(nb_reg), c("33001-33002", "33002-33003"))
  expect_equal(contar_ligacoes(nb_reg), 4)
  nb_mun <- criar_vizinhos_queen(s$malha)
  expect_identical(pares_regionais_implicados(nb_mun, s$regioes), pares_de_vizinhanca(nb_reg))
})

test_that("taxa regional é soma dos casos / soma da população, não a média das taxas", {
  s <- malha_sintetica()
  r <- validar_regioes(s$regioes, n_municipios = 9, n_regioes = 3)
  ind <- data.frame(cod6 = s$regioes$cod6, agente = "vsr", ano = 2024L,
                    casos = c(10L, rep(0L, 8)), populacao = c(100, rep(9900, 8)),
                    populacao_unica = c(100, rep(9900, 8)))
  # Região 33001 = municípios 1, 4, 7: 10 casos em 100 + 9.900 + 9.900 habitantes.
  ag <- agregar_por_regiao(ind, r)
  expect_equal(nrow(ag), 3)
  x <- ag[ag$cod_regiao == "33001", ]
  expect_equal(x$casos, 10L)
  expect_equal(x$populacao, 19900)
  expect_equal(x$incid_100k, 10 / 19900 * 1e5)          # 50,25 por 100 mil
  expect_false(isTRUE(all.equal(x$incid_100k, mean(c(10000, 0, 0)))))  # a média daria 3.333
  expect_equal(sum(ag$casos), sum(ind$casos))
  expect_equal(x$regiao, "Baía da Ilha Grande")
  expect_error(agregar_por_regiao(ind, r[-1, ]), "sem região")
})

test_that("Moran regional alinha pela chave da região e devolve uma linha por agente × ano", {
  s <- malha_sintetica()
  r <- validar_regioes(s$regioes, n_municipios = 9, n_regioes = 3)
  pesos <- criar_pesos(criar_vizinhos_regionais(dissolver_regioes(s$malha, r)))
  ind <- data.frame(cod_regiao = rep(c("33003", "33001", "33002"), 2),   # fora de ordem de propósito
                    agente = "vsr", ano = rep(c(2023L, 2024L), each = 3),
                    incid_100k = c(30, 10, 20, 1, 5, 3))
  m <- executar_moran_regional(ind, pesos, nsim = 5)  # spdep limita nsim a n! = 6
  expect_equal(nrow(m), 2)
  expect_equal(m$n, c(3L, 3L))
  expect_equal(m$esperado_I, c(-0.5, -0.5))
  # 2023 em ordem 33001..33003 = 10, 20, 30 (gradiente): I calculado à mão com pesos W.
  z <- c(10, 20, 30) - 20
  w <- rbind(c(0, 1, 0), c(0.5, 0, 0.5), c(0, 1, 0))
  expect_equal(m$I[1], (3 / sum(w)) * sum(z * (w %*% z)) / sum(z^2))
})

test_that("rótulo de cada região cai dentro do seu município mais populoso", {
  s <- malha_sintetica()
  r <- validar_regioes(s$regioes, n_municipios = 9, n_regioes = 3)
  pop <- data.frame(cod6 = s$regioes$cod6, populacao = c(5, 1, 1, 9, 1, 1, 1, 1, 7))
  p <- pontos_rotulo_regioes(s$malha, r, pop)
  expect_equal(p$cod_regiao, c("33001", "33002", "33003"))
  expect_equal(p$cod6_sede, c("330004", "330002", "330009"))
  dentro <- sf::st_within(sf::st_transform(p, 31983),
                          sf::st_transform(s$malha[match(p$cod6_sede, s$malha$cod6), ], 31983), sparse = FALSE)
  expect_true(all(diag(dentro)))
})

test_that("mapa regional monta com um rótulo por região e para se faltar dado", {
  s <- malha_sintetica()
  r <- validar_regioes(s$regioes, n_municipios = 9, n_regioes = 3)
  rs <- dissolver_regioes(s$malha, r)
  ind <- data.frame(cod_regiao = c("33001", "33002", "33003"), agente = "vsr", ano = 2024L,
                    casos = c(1L, 2L, 3L), incid_100k = c(1.25, 2.5, 3.75))
  g <- mapa_regional(rs, ind, "vsr", 2024, malha = s$malha)
  b <- ggplot2::ggplot_build(g)
  rotulos <- unlist(lapply(b$data, function(d) if ("label" %in% names(d)) d$label))
  expect_length(rotulos, 3)
  expect_true(any(grepl("Baixada Litorânea\n2,5", rotulos, fixed = TRUE)))
  expect_error(mapa_regional(rs, ind[-1, ], "vsr", 2024), "incompleta")
})
