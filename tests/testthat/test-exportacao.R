# Testes da exportação para planilha (CS-020). Sem rede.

test_that("CSV começa com o BOM do UTF-8 e usa ';' e ',' do Excel pt-BR", {
  projeto_temporario()
  df <- data.frame(municipio = c("Niterói", "São João de Meriti"), taxa = c(12.5, 0.25), casos = c(3L, NA))
  f <- salvar_resultado(df, "teste", pasta = "saida")
  bytes <- readBin(f, "raw", 3)
  expect_identical(bytes, as.raw(c(0xEF, 0xBB, 0xBF)))
  linhas <- readLines(f, encoding = "UTF-8", warn = FALSE)
  expect_match(linhas[2], ";12,5;")
  expect_match(linhas[3], ";0,25;$")  # NA vira célula vazia
})

test_that("ida e volta preserva acentos, decimais e número de linhas", {
  projeto_temporario()
  df <- data.frame(municipio = c("Niterói", "Armação dos Búzios"), taxa = c(12.5, 0.25))
  f <- salvar_resultado(df, "teste", pasta = "saida")
  volta <- ler_resultado(f)
  expect_equal(volta$municipio, df$municipio)
  expect_equal(as.numeric(sub(",", ".", volta$taxa)), df$taxa)
  expect_equal(nrow(volta), 2)
})

test_that("texto com ';' e aspas é protegido, não quebra colunas", {
  projeto_temporario()
  df <- data.frame(a = "x; y \"z\"", b = 1)
  f <- salvar_resultado(df, "teste", pasta = "saida")
  volta <- ler_resultado(f)
  expect_equal(ncol(volta), 2)
  expect_equal(volta$a, "x; y \"z\"")
})

test_that("o carimbo registra data, regra de caso e formato", {
  projeto_temporario()
  dir.create("saida")
  f <- escrever_carimbo("saida", "linha extra")
  t <- readLines(f, encoding = "UTF-8", warn = FALSE)
  expect_true(any(grepl("^Gerado em: \\d{4}-\\d{2}-\\d{2}", t)))
  expect_true(any(grepl(REGRA_CASO, t, fixed = TRUE)))
  expect_true(any(grepl("separador ';'", t, fixed = TRUE)))
  expect_true("linha extra" %in% t)
})

# ---- integração (pulado se o script não rodou) ----

test_that("exportação real: 4 CSV com as linhas esperadas e o LEIA-ME", {
  withr::local_dir(raiz_projeto)
  p <- "resultados/tabelas/exportacao"
  skip_if_not(file.exists(file.path(p, "LEIA-ME.txt")), "07_exportacao.R não rodou")
  expect_equal(nrow(ler_resultado(file.path(p, "indicadores_municipais.csv"))), 1104)
  expect_equal(nrow(ler_resultado(file.path(p, "lisa_municipios.csv"))), 1104)
  expect_equal(nrow(ler_resultado(file.path(p, "moran_global.csv"))), 36)
  expect_equal(nrow(ler_resultado(file.path(p, "incidencia_estado.csv"))), 12)
  expect_true("Niterói" %in% ler_resultado(file.path(p, "lisa_municipios.csv"))$municipio)
})
