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

# ---- contorno do estado (CS-055) e painéis por vírus (CS-056) ----

quatro_anos <- function(agente = "vsr") {
  do.call(rbind, lapply(2022:2025, function(a) {
    d <- dados_falsos_mapa(); d$agente <- agente; d$ano_rotulo <- a
    if (a != 2024) d$nivel[1] <- "ns"   # só 2024 tem confirmado
    d
  }))
}

test_that("contorno do estado: um registro, mesma área e mesmo sistema da malha", {
  m <- malha_falsa(4)
  k <- contorno_estado(m)
  expect_equal(nrow(k), 1)
  expect_equal(sf::st_crs(k), sf::st_crs(m))
  expect_equal(as.numeric(sf::st_area(k)), sum(as.numeric(sf::st_area(m))), tolerance = 1e-6)
  # 16 quadrados colados viram 1 polígono sem buraco (a união não deixou fresta)
  p <- sf::st_cast(sf::st_geometry(k), "POLYGON")
  expect_length(p, 1)
  expect_equal(lengths(p), 1L)
})

test_that("mapas de incidência e de LISA desenham o contorno do estado", {
  d <- dados_falsos_mapa()
  expect_true(tem_contorno(mapa_incidencia(d, "sarscov2", 2022)))
  expect_true(tem_contorno(mapa_lisa(d, "vsr", 2024)))
  expect_false(tem_contorno(ggplot2::ggplot(d) + ggplot2::geom_sf()))  # o detector não acha contorno onde não há
})

test_that("painel de incidência por vírus: 4 anos em 2 × 2, rampa do vírus, contorno", {
  x <- quatro_anos("sarscov2")
  g <- painel_incidencia_agente(x, "sarscov2", contorno_estado(malha_falsa()))
  b <- ggplot2::ggplot_build(g)
  expect_equal(nrow(b$layout$layout), 4)
  expect_equal(max(b$layout$layout$ROW), 2)
  expect_equal(max(b$layout$layout$COL), 2)
  expect_match(g$labels$title, "SARS-CoV-2, 2022–2025")
  expect_true(tem_contorno(g))
  # o valor mais alto sai no passo mais escuro da rampa do SARS-CoV-2 (azul)
  cores <- b$data[[1]]$fill[b$data[[1]]$PANEL == 1]
  expect_equal(tolower(cores[which.max(x$incid_eb_100k[x$ano_rotulo == 2022])]), tolower(rampa_agente("sarscov2", 7)[7]))
  expect_error(painel_incidencia_agente(quatro_anos("vsr"), "sarscov2", contorno_estado(malha_falsa())), "outro vírus")
})

test_that("painel LISA por vírus: 4 anos, 9 classes na legenda, confirmados no título de cada ano", {
  g <- painel_lisa_agente(quatro_anos("vsr"), "vsr", contorno_estado(malha_falsa()))
  b <- ggplot2::ggplot_build(g)
  expect_equal(nrow(b$layout$layout), 4)
  expect_equal(nrow(ggplot2::get_guide_data(g, "fill")), 9)
  paineis <- as.character(b$layout$layout$painel)
  expect_equal(paineis, c("2022 · nenhum confirmado", "2023 · nenhum confirmado",
                          "2024 · 1 confirmado(s) após FDR", "2025 · nenhum confirmado"))
  expect_true(tem_contorno(g))
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

test_that("os 24 mapas individuais, os 2 painéis 3 × 4 e os 6 painéis por vírus foram gerados", {
  withr::local_dir(raiz_projeto)
  skip_if_not(dir.exists("resultados/mapas") && length(list.files("resultados/mapas", "\\.png$")) > 0,
              "06_visualizacoes.R não rodou")
  f <- list.files("resultados/mapas", "\\.png$")
  expect_equal(sum(grepl("^incidencia_", f)), 12)
  expect_equal(sum(grepl("^lisa_", f)), 12)
  expect_true(all(c("painel_lisa.png", "painel_incidencia.png") %in% f))
  expect_true(all(sprintf("painel_%s_%s.png", rep(c("incidencia", "lisa"), each = 3), AGENTES) %in% f))
})
