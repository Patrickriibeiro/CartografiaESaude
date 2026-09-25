# Testes das funções de mapa (CS-019). Malha FABRICADA: quadrados de 0,1 grau
# perto do Rio, em SIRGAS 2000, para exercitar as mesmas conversões da malha real.

malha_falsa <- function(n = 4) {
  q <- list()
  for (i in 0:(n - 1)) for (j in 0:(n - 1)) {
    x0 <- -43.5 + j * 0.1; y0 <- -22.9 + i * 0.1
    q[[length(q) + 1]] <- sf::st_polygon(list(rbind(c(x0, y0), c(x0 + 0.1, y0), c(x0 + 0.1, y0 + 0.1),
                                                    c(x0, y0 + 0.1), c(x0, y0))))
  }
  sf::st_sf(cod6 = sprintf("33%04d", seq_along(q)), nome = paste("Município", seq_along(q)),
            geometry = sf::st_sfc(q, crs = 4674))
}

dados_falsos_mapa <- function(m = malha_falsa()) {
  n <- nrow(m)
  m$incid_eb_100k <- seq(1, 100, length.out = n)
  m$quadrante <- rep(c("HH", "LL", "HL", "LH"), length.out = n)
  m$nivel <- c("confirmado", "indicativo", rep("ns", n - 2))
  m$instavel <- c(FALSE, FALSE, TRUE, rep(FALSE, n - 3))
  m
}

test_that("categoria do LISA junta quadrante e nível; ns ignora o quadrante", {
  c <- categoria_lisa(c("HH", "LL", "HL", "LH"), c("confirmado", "indicativo", "ns", "confirmado"))
  expect_equal(as.character(c), c("Alto-Alto (confirmado)", "Baixo-Baixo (indicativo)",
                                  "Não significativo", "Baixo-Alto (confirmado)"))
  expect_equal(levels(c), names(PALETA_LISA))
  expect_error(categoria_lisa("XX", "confirmado"), "fora da paleta")
})

test_that("classes por quintil: 5 classes, todos classificados, vírgula decimal", {
  x <- c(1.5, 2, 3, 4, 5, 6, 7, 8, 9, 10.25)
  k <- classes_quantil(x)
  expect_equal(nlevels(k), 5)
  expect_false(anyNA(k))
  expect_match(levels(k)[1], "^1,5 – ")
  expect_equal(nlevels(classes_quantil(rep(3, 10))), 1)  # valores todos iguais não quebram
})

test_that("hachura: linhas só dentro do polígono, e vazia quando não há instável", {
  m <- malha_falsa(2)
  h <- hachurar(m[1, ], espacamento = 0.01)
  expect_gt(nrow(h), 5)
  dentro <- sf::st_covered_by(h, sf::st_buffer(sf::st_geometry(m[1, ]), 1e-9), sparse = FALSE)
  expect_true(all(dentro))
  expect_equal(nrow(hachurar(m[0, ])), 0)
})

test_that("ponto do rótulo fica dentro do município e no mesmo sistema de coordenadas", {
  m <- malha_falsa(2)
  p <- ponto_interno(sf::st_geometry(m))
  expect_equal(sf::st_crs(p), sf::st_crs(m))
  expect_true(all(diag(sf::st_within(p, m, sparse = FALSE))))
})

test_that("mapa LISA: 9 categorias na legenda, confirmados no subtítulo", {
  d <- dados_falsos_mapa()
  g <- mapa_lisa(d, "vsr", 2024)
  expect_s3_class(g, "ggplot")
  legenda <- ggplot2::get_guide_data(g, "fill")
  expect_equal(nrow(legenda), 9)
  expect_equal(unname(legenda$fill), unname(PALETA_LISA))
  expect_match(g$labels$subtitle, "Município 1 \\(Alto-Alto\\)")
  expect_match(g$labels$subtitle, "1 indicativo")
  expect_no_error(ggplot2::ggplot_build(g))
})

test_that("mapa LISA sem confirmado diz isso no subtítulo e não rotula", {
  d <- dados_falsos_mapa(); d$nivel[1] <- "ns"
  g <- mapa_lisa(d, "influenza", 2022)
  expect_match(g$labels$subtitle, "Nenhum confirmado")
  expect_no_error(ggplot2::ggplot_build(g))
})

test_that("mapa de incidência monta com 5 classes", {
  g <- mapa_incidencia(dados_falsos_mapa(), "sarscov2", 2022)
  b <- ggplot2::ggplot_build(g)
  expect_equal(length(unique(b$data[[1]]$fill)), 5)
})

test_that("dados_mapa devolve sf com a malha inteira e para se faltar dado", {
  m <- malha_falsa(2)
  ind <- data.frame(cod6 = m$cod6, agente = "vsr", ano = 2024L, incid_eb_100k = 1:4)
  lisa <- data.frame(cod6 = m$cod6, agente = "vsr", ano = 2024L, quadrante = "HH", nivel = "ns",
                     classe = "ns", instavel = FALSE, p_perm = 0.5, p_fdr = 0.5)
  d <- dados_mapa(m, ind, lisa, "vsr", 2024)
  expect_s3_class(d, "sf")                       # merge() comum perderia a classe sf
  expect_equal(nrow(d), 4)
  expect_equal(sf::st_crs(d), sf::st_crs(m))
  expect_error(dados_mapa(m, ind[-1, ], lisa, "vsr", 2024), "incompleta")
})

# ---- integração: os 26 mapas existem (pulado se o script não rodou) ----

test_that("os 24 mapas individuais e os 2 painéis foram gerados", {
  withr::local_dir(raiz_projeto)
  skip_if_not(dir.exists("resultados/mapas") && length(list.files("resultados/mapas", "\\.png$")) > 0,
              "06_visualizacoes.R não rodou")
  f <- list.files("resultados/mapas", "\\.png$")
  expect_equal(sum(grepl("^incidencia_", f)), 12)
  expect_equal(sum(grepl("^lisa_", f)), 12)
  expect_true(all(c("painel_lisa.png", "painel_incidencia.png") %in% f))
})
