# Testes da paleta única (CS-046): uma cor por vírus em todo o projeto, sem colisão com o LISA.

test_that("cada agente tem uma cor, na ordem de AGENTES, e as três são diferentes", {
  expect_equal(names(CORES_AGENTE), AGENTES)
  expect_equal(length(unique(tolower(CORES_AGENTE))), 3)
  expect_true(all(grepl("^#[0-9a-fA-F]{6}$", CORES_AGENTE)))
})

test_that("nenhuma cor de vírus reaparece no LISA nem nas rampas de outro vírus", {
  expect_length(intersect(tolower(CORES_AGENTE), tolower(PALETA_LISA)), 0)
  for (ag in AGENTES) {
    outras <- setdiff(AGENTES, ag)
    expect_length(intersect(tolower(rampa_agente(ag, 7)), tolower(CORES_AGENTE[outras])), 0)
  }
  expect_false(tolower(COR_NEUTRA) %in% tolower(c(CORES_AGENTE, PALETA_LISA)))
})

test_that("a rampa de cada vírus vai do claro ao escuro (claridade estritamente decrescente)", {
  for (ag in AGENTES) {
    L <- farver::convert_colour(t(grDevices::col2rgb(rampa_agente(ag, 7))), "rgb", "lab")[, "l"]
    expect_true(all(diff(L) < 0), info = ag)
    expect_gt(L[1], 90)   # o passo mais claro fica perto do branco: "quase zero"
  }
})

test_that("a legenda do LISA mantém as 9 categorias nomeadas e cores distintas", {
  expect_length(PALETA_LISA, 9)
  expect_equal(length(unique(tolower(PALETA_LISA))), 9)
  expect_true("Não significativo" %in% names(PALETA_LISA))
})

test_that("nenhuma cor escrita à mão fora de funcoes_mapas.R (nem magma/viridis)", {
  arquivos <- c(list.files(file.path(raiz_projeto, "R"), pattern = "\\.R$", full.names = TRUE),
                list.files(raiz_projeto, pattern = "^(0[0-9]_.*|app)\\.R$", full.names = TRUE))
  arquivos <- arquivos[basename(arquivos) != "funcoes_mapas.R"]
  achados <- character(0)
  for (a in arquivos) {
    linhas <- readLines(a, encoding = "UTF-8", warn = FALSE)
    codigo <- sub("#[^'\"]*$", "", linhas)   # ignora comentários no fim da linha
    hit <- grepl("\"#[0-9a-fA-F]{6}\"|magma|viridis", codigo)
    achados <- c(achados, sprintf("%s:%d", basename(a), which(hit)))
  }
  expect_identical(achados, character(0))
})

test_that("guia de cores e escalas montam", {
  expect_s3_class(ggplot2::ggplot_build(grafico_guia_cores()), "ggplot_built")
  expect_length(rampa_agente("vsr", 5), 5)
  expect_error(rampa_agente("dengue"), "sem rampa")
  # A escala liga o rótulo legível à cor do vírus: SARS-CoV-2 sai sempre com a cor dele.
  d <- data.frame(x = 1:3, y = 1:3, agente_rotulo = factor(ROTULOS_AGENTE[AGENTES], levels = ROTULOS_AGENTE))
  b <- ggplot2::ggplot_build(ggplot2::ggplot(d, ggplot2::aes(x, y, colour = agente_rotulo)) + ggplot2::geom_point() + escala_cor_agente())
  expect_equal(tolower(b$data[[1]]$colour), tolower(unname(CORES_AGENTE[AGENTES])))
})
