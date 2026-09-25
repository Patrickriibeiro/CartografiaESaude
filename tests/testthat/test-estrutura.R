# Teste do esqueleto (CS-002): a árvore do PDF existe e criar_diretorios é idempotente.

raiz <- normalizePath(file.path(testthat::test_path(), "..", ".."))

test_that("scripts numerados do PDF existem", {
  esperados <- c(sprintf("%02d_%s.R", 0:7, c("setup", "etl_sivep", "indicadores",
    "cartografia", "pesos_espaciais", "moran_lisa", "visualizacoes", "exportacao")),
    "run.R", "app.R", "08_relatorio.qmd", "_quarto.yml")
  expect_true(all(file.exists(file.path(raiz, esperados))))
})

test_that("as seis bibliotecas de funções existem", {
  esperados <- paste0("funcoes_", c("validacao", "sivep", "indicadores",
    "espaciais", "mapas", "utilitarias"), ".R")
  expect_true(all(file.exists(file.path(raiz, "R", esperados))))
})

test_that("criar_diretorios é idempotente", {
  source(file.path(raiz, "R", "funcoes_utilitarias.R"), encoding = "UTF-8")
  tmp <- withr::local_tempdir()
  withr::with_dir(tmp, {
    p1 <- criar_diretorios()
    p2 <- criar_diretorios()
    expect_identical(p1, p2)
    expect_true(all(dir.exists(p1)))
    expect_length(p1, 8)
  })
})
