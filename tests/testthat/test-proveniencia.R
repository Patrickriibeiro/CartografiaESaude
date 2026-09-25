# Testes do manifesto de proveniência (CS-003). Sem rede: tudo em pasta temporária.

test_that("registrar_fonte grava uma linha com hash, tamanho e caminho relativo", {
  projeto_temporario()
  escrever_arquivo("dados/brutos/a.csv", c("x,y", "1,2"))
  registrar_fonte("dados/brutos/a.csv", url = "https://exemplo/a.csv",
                  descricao = "teste", versao = "v1")
  m <- ler_manifesto()
  expect_equal(nrow(m), 1)
  expect_equal(m$arquivo, "dados/brutos/a.csv")
  expect_equal(m$sha256, sha256_arquivo("dados/brutos/a.csv"))
  expect_equal(nchar(m$sha256), 64)
  expect_equal(m$bytes, as.character(file.size("dados/brutos/a.csv")))
  expect_match(m$baixado_em, "^\\d{4}-\\d{2}-\\d{2}T\\d{2}:\\d{2}:\\d{2}Z$")
})

test_that("registrar o mesmo arquivo duas vezes não duplica a linha", {
  projeto_temporario()
  escrever_arquivo("dados/brutos/a.csv", "1")
  registrar_fonte("dados/brutos/a.csv", "u", "d")
  expect_message(registrar_fonte("dados/brutos/a.csv", "u", "d"), "Já registrado")
  expect_equal(nrow(ler_manifesto()), 1)
})

test_that("conteúdo novo com o mesmo nome exige substituir = TRUE", {
  projeto_temporario()
  escrever_arquivo("dados/brutos/a.csv", "versão 1")
  registrar_fonte("dados/brutos/a.csv", "u", "d")
  hash_antigo <- ler_manifesto()$sha256

  escrever_arquivo("dados/brutos/a.csv", "versão 2")
  expect_error(registrar_fonte("dados/brutos/a.csv", "u", "d"), "mudou desde o registro")
  expect_equal(ler_manifesto()$sha256, hash_antigo)  # o erro não alterou nada

  registrar_fonte("dados/brutos/a.csv", "u", "d", substituir = TRUE)
  m <- ler_manifesto()
  expect_equal(nrow(m), 1)
  expect_false(identical(m$sha256, hash_antigo))
})

test_that("verificar_manifesto passa com arquivo íntegro", {
  projeto_temporario()
  escrever_arquivo("dados/brutos/a.csv", "1")
  registrar_fonte("dados/brutos/a.csv", "u", "d")
  expect_silent(verificar_manifesto())
  expect_silent(verificar_manifesto("dados/brutos/a.csv"))
})

test_that("verificar_manifesto falha se um byte do arquivo mudou", {
  projeto_temporario()
  escrever_arquivo("dados/brutos/a.csv", "1,2,3")
  registrar_fonte("dados/brutos/a.csv", "u", "d")
  escrever_arquivo("dados/brutos/a.csv", "1,2,4")
  expect_error(verificar_manifesto(), "SHA-256 divergente")
  expect_error(verificar_manifesto("dados/brutos/a.csv"), "SHA-256 divergente")
})

test_that("verificar_manifesto falha com bruto não registrado", {
  projeto_temporario()
  escrever_arquivo("dados/brutos/intruso.csv", "1")
  expect_error(verificar_manifesto(), "sem registro no manifesto")
  expect_error(verificar_manifesto("dados/brutos/intruso.csv"), "sem registro")
})

test_that("verificar_manifesto falha se o arquivo registrado sumiu do disco", {
  projeto_temporario()
  escrever_arquivo("dados/brutos/a.csv", "1")
  registrar_fonte("dados/brutos/a.csv", "https://exemplo/a.csv", "d")
  file.remove("dados/brutos/a.csv")
  expect_error(verificar_manifesto(), "ausente no disco.*exemplo/a.csv")
})

test_that("o manifesto sobrevive à ida e volta com versão vazia e acentos", {
  projeto_temporario()
  escrever_arquivo("dados/brutos/b.csv", "1")
  escrever_arquivo("dados/brutos/a.csv", "2")
  registrar_fonte("dados/brutos/b.csv", "u", "População estimada, município")
  registrar_fonte("dados/brutos/a.csv", "u", "Dicionário", versao = "2025-09")
  m <- ler_manifesto()
  expect_equal(m$arquivo, c("dados/brutos/a.csv", "dados/brutos/b.csv"))  # ordenado
  expect_equal(m$descricao[2], "População estimada, município")
  expect_true(is.na(m$versao[2]))
  bytes <- readBin("dados/MANIFESTO.md", "raw", file.size("dados/MANIFESTO.md"))
  expect_false(any(bytes == as.raw(13)))  # nenhum \r: sem CRLF no Windows
})

test_that("campo com barra vertical é recusado, porque quebraria a tabela", {
  projeto_temporario()
  escrever_arquivo("dados/brutos/a.csv", "1")
  expect_error(registrar_fonte("dados/brutos/a.csv", "u", "a | b"), "não cabe na tabela")
  expect_false(file.exists("dados/MANIFESTO.md"))
})

test_that("arquivo fora do projeto não entra no manifesto", {
  fora <- withr::local_tempfile(fileext = ".csv")
  writeLines("1", fora)
  projeto_temporario()
  expect_error(registrar_fonte(fora, "u", "d"), "fora do projeto")
})

test_that("baixar_e_registrar baixa uma vez e depois usa o cache conferido", {
  origem <- withr::local_tempfile(fileext = ".txt")
  writeLines("conteúdo remoto", origem)
  url <- paste0("file:///", normalizePath(origem, winslash = "/"))
  projeto_temporario()

  baixar_e_registrar(url, "dados/externos/x.txt", descricao = "d")
  expect_true(file.exists("dados/externos/x.txt"))
  expect_equal(nrow(ler_manifesto()), 1)
  expect_false(file.exists("dados/externos/x.txt.parcial"))

  writeLines("mudou na origem", origem)  # se rebaixasse, o conteúdo mudaria
  expect_message(baixar_e_registrar(url, "dados/externos/x.txt", "d"), "Em cache")
  expect_equal(readLines("dados/externos/x.txt", encoding = "UTF-8"), "conteúdo remoto")
})

test_that("baixar_e_registrar recusa cache adulterado em vez de sobrescrever", {
  origem <- withr::local_tempfile(fileext = ".txt")
  writeLines("original", origem)
  url <- paste0("file:///", normalizePath(origem, winslash = "/"))
  projeto_temporario()
  baixar_e_registrar(url, "dados/externos/x.txt", "d")
  writeLines("adulterado", "dados/externos/x.txt")
  expect_error(baixar_e_registrar(url, "dados/externos/x.txt", "d"), "SHA-256 divergente")
})
