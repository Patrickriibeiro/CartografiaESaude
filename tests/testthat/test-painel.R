# Testes do painel Shiny (CS-021). Funções com malha FABRICADA; servidor com os
# dados reais (pulado se o pipeline não rodou).

test_that("popup tem os 6 campos e escapa HTML do nome", {
  d <- data.frame(nome = "São <b>X</b>", casos = 1234L, populacao = 56789L, incid_100k = 2.5,
                  incid_eb_100k = 3.25, quadrante = "HH", nivel = "confirmado", instavel = TRUE)
  p <- popup_painel(d)
  for (campo in c("Casos: 1.234", "População: 56.789", "Taxa bruta: 2,5", "Taxa suavizada: 3,2",
                  "Moran local: Alto-Alto (confirmado)", "classe instável")) {
    expect_match(p, campo, fixed = TRUE)
  }
  expect_match(p, "S&#227;o &lt;b&gt;X&lt;/b&gt;|São &lt;b&gt;X&lt;/b&gt;")
})

test_that("carregar_dados_painel explica o que falta quando o pipeline não rodou", {
  projeto_temporario()
  expect_error(carregar_dados_painel(), "Rode o pipeline antes do painel")
})

test_that("mapa do painel monta nas duas camadas", {
  m <- sf::st_sf(cod6 = c("330010", "330020"), nome = c("A", "B"),
                 geometry = sf::st_sfc(sf::st_polygon(list(rbind(c(-43, -22), c(-42.9, -22), c(-42.9, -21.9), c(-43, -21.9), c(-43, -22)))),
                                       sf::st_polygon(list(rbind(c(-42.9, -22), c(-42.8, -22), c(-42.8, -21.9), c(-42.9, -21.9), c(-42.9, -22)))),
                                       crs = 4326))
  base <- list(malha = m,
               ind = data.frame(cod6 = m$cod6, agente = "vsr", ano = 2024L, casos = c(1L, 5L),
                                populacao = c(1000L, 2000L), incid_100k = c(100, 250), incid_eb_100k = c(120, 240)),
               lisa = data.frame(cod6 = m$cod6, agente = "vsr", ano = 2024L, quadrante = c("HH", "LL"),
                                 nivel = c("confirmado", "ns"), classe = c("HH", "ns"), instavel = c(FALSE, TRUE),
                                 p_perm = c(0.001, 0.5), p_fdr = c(0.01, 0.5)))
  d <- dados_painel(base, "vsr", 2024)
  expect_equal(nrow(d), 2)
  expect_s3_class(mapa_painel(d, "incidencia"), "leaflet")
  expect_s3_class(mapa_painel(d, "lisa"), "leaflet")
})

# ---- servidor com os dados reais ----

test_that("as 12 combinações agente × ano filtram sem erro, com 92 municípios", {
  withr::local_dir(raiz_projeto)
  skip_if_not(all(file.exists(ARQUIVOS_PAINEL)), "pipeline não rodou")
  app <- shiny::shinyAppDir(raiz_projeto)
  shiny::testServer(app, {
    for (ag in AGENTES) for (a in ANOS_ESTUDO) for (cam in c("incidencia", "lisa")) {
      session$setInputs(agente = ag, ano = as.character(a), camada = cam)
      d <- dados()
      expect_equal(nrow(d), 92)
      expect_false(anyNA(d$popup))
      expect_true(all(grepl("Moran local:", d$popup)))
    }
    session$setInputs(agente = "vsr", ano = "2024", camada = "lisa")
    expect_match(paste(output$resumo$html), "Tanguá")
  })
})
