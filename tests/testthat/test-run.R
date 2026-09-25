# Testes do executor do pipeline (CS-023). Etapas FABRICADAS em pasta temporária.

test_that("etapas rodam em ordem, cada uma isolada, e o log tem uma linha por etapa", {
  projeto_temporario()
  ordem <- character(0)
  etapas <- list(a = function() ordem <<- c(ordem, "a"), b = function() ordem <<- c(ordem, "b"))
  log <- suppressMessages(executar_etapas(etapas, "log.txt"))
  expect_equal(ordem, c("a", "b"))
  expect_equal(log$status, c("ok", "ok"))
  t <- readLines("log.txt")
  expect_true(any(grepl("^a +[0-9.]+ +ok$", t)))
  expect_true(any(grepl("^TOTAL", t)))
})

test_that("para na primeira falha, não roda as seguintes e grava o erro no log", {
  projeto_temporario()
  rodou_c <- FALSE
  etapas <- list(a = function() NULL, b = function() stop("quebrou aqui"), c = function() rodou_c <<- TRUE)
  expect_error(suppressMessages(executar_etapas(etapas, "log.txt")), "parou em b: quebrou aqui")
  expect_false(rodou_c)
  expect_true(any(grepl("ERRO: quebrou aqui", readLines("log.txt"))))
})

test_that("etapa de script roda num ambiente próprio: variáveis não vazam para a próxima", {
  projeto_temporario()
  writeLines("x_da_etapa_1 <- 42", "s1.R")
  writeLines("if (exists('x_da_etapa_1', inherits = TRUE)) stop('vazou')", "s2.R")
  expect_no_error(suppressMessages(executar_etapas(list(s1 = etapa_script("s1.R"), s2 = etapa_script("s2.R")), "log.txt")))
  expect_false(exists("x_da_etapa_1", envir = globalenv()))
})

test_that("limpar_derivados apaga saídas, preserva .gitkeep e não toca em brutos", {
  projeto_temporario()
  dir.create("resultados/mapas/sub", recursive = TRUE)
  writeLines("", "resultados/mapas/.gitkeep")
  writeLines("x", "resultados/mapas/a.png"); writeLines("x", "resultados/mapas/sub/b.png")
  writeLines("x", "dados/brutos/INFLUD.parquet")
  n <- limpar_derivados(c("resultados/mapas", "dados/processados"))
  expect_equal(n, 2)
  expect_true(file.exists("resultados/mapas/.gitkeep"))
  expect_false(dir.exists("resultados/mapas/sub"))
  expect_true(file.exists("dados/brutos/INFLUD.parquet"))
})

test_that("o run.R real lista as 7 etapas numeradas, todas existentes", {
  run <- readLines(file.path(raiz_projeto, "run.R"), encoding = "UTF-8")
  scripts <- regmatches(run, regexpr("\"0[1-7]_[a-z_]+\\.R\"", run))
  scripts <- unique(gsub("\"", "", scripts))
  expect_equal(scripts, sprintf("%02d_%s.R", 1:7, c("etl_sivep", "indicadores", "cartografia",
    "pesos_espaciais", "moran_lisa", "visualizacoes", "exportacao")))
  expect_true(all(file.exists(file.path(raiz_projeto, scripts))))
})
