# Teste do esqueleto (CS-002): a árvore do PDF existe e criar_diretorios é idempotente.

test_that("scripts numerados do PDF existem", {
  esperados <- c(sprintf("%02d_%s.R", 0:7, c("setup", "etl_sivep", "indicadores",
    "cartografia", "pesos_espaciais", "moran_lisa", "visualizacoes", "exportacao")),
    "run.R", "app.R", "08_relatorio.qmd", "_quarto.yml")
  expect_true(all(file.exists(file.path(raiz_projeto, esperados))))
})

test_that("as bibliotecas de funções existem (seis do PDF + regiões, CS-030, + séries, CS-032, + leitos, CS-034)", {
  esperados <- paste0("funcoes_", c("validacao", "sivep", "indicadores",
    "espaciais", "mapas", "utilitarias", "regioes", "series", "leitos", "padronizacao", "abnt"), ".R")
  expect_true(all(file.exists(file.path(raiz_projeto, "R", esperados))))
})

test_that("todo arquivo .R do projeto é R sintaticamente válido", {
  # Cicatriz de 2026-09-25: o 00_setup.R foi commitado com "\." (escape inválido)
  # e o teste de estrutura só conferia se o arquivo existia.
  arquivos <- c(list.files(raiz_projeto, pattern = "\\.R$", full.names = TRUE),
                list.files(file.path(raiz_projeto, "R"), pattern = "\\.R$", full.names = TRUE))
  for (a in arquivos) {
    expect_no_error(parse(a, encoding = "UTF-8"), message = basename(a))
  }
  expect_gte(length(arquivos), 16)
})

test_that("00_setup.R executa, carrega as funções e cria os diretórios", {
  projeto_temporario()
  file.copy(file.path(raiz_projeto, "00_setup.R"), ".")
  dir.create("R")
  file.copy(list.files(file.path(raiz_projeto, "R"), full.names = TRUE), "R")
  ambiente <- new.env()
  sys.source("00_setup.R", envir = ambiente, keep.source = FALSE)
  expect_true(exists("registrar_fonte", envir = ambiente, inherits = FALSE))
  expect_equal(ambiente$ANOS_ESTUDO, 2022:2025)
  expect_equal(ambiente$EPSG_SIRGAS2000, 4674)
  expect_true(dir.exists("resultados/estatistica"))
})

test_that("criar_diretorios é idempotente", {
  projeto_temporario()
  p1 <- criar_diretorios()
  p2 <- criar_diretorios()
  expect_identical(p1, p2)
  expect_true(all(dir.exists(p1)))
  expect_length(p1, 9)   # 9ª: resultados/documentos (CS-057)
})

test_that("COMECE-AQUI.md e o projeto do RStudio acompanham o pipeline (CS-059)", {
  guia <- file.path(raiz_projeto, "COMECE-AQUI.md")
  rproj <- file.path(raiz_projeto, "CartografiaESaude.Rproj")
  expect_true(file.exists(guia))
  expect_true(file.exists(rproj))
  expect_equal(readLines(rproj, n = 1), "Version: 1.0")
  expect_true(any(grepl("^RestoreWorkspace: No$", readLines(rproj))))   # sem .RData fantasma entre sessões
  texto <- paste(readLines(guia, encoding = "UTF-8", warn = FALSE), collapse = "\n")
  # toda etapa do pipeline aparece no guia, e todo script citado no guia existe
  etapas <- list.files(raiz_projeto, pattern = "^0[1-8]_.*\\.(R|qmd)$")
  for (e in etapas) expect_true(grepl(e, texto, fixed = TRUE), info = paste(e, "fora do COMECE-AQUI.md"))
  citados <- unique(regmatches(texto, gregexpr("0[0-9]_[a-z_]+\\.(R|qmd)", texto))[[1]])
  expect_true(all(file.exists(file.path(raiz_projeto, citados))), info = paste(citados, collapse = ", "))
})
