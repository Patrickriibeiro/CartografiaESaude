# Testes das quatro funções de validação do PDF (CS-009). Dados FABRICADOS.

test_that("validar_variaveis passa com todas as colunas e para dizendo quais faltam", {
  expect_invisible(validar_variaveis(c("a", "b", "c"), c("a", "c")))
  expect_error(validar_variaveis(c("a", "b"), c("a", "CO_MUN_RES", "DT_SIN_PRI"), "INFLUD22.parquet"),
               "2 coluna\\(s\\) faltando em INFLUD22.parquet: CO_MUN_RES, DT_SIN_PRI")
})

test_that("validar_variaveis é chamada na leitura do banco: coluna renomeada para com mensagem clara", {
  projeto_temporario()
  f <- banco_sintetico(data.frame(CO_MUN_RES = "330455", SG_UF = "RJ",
                                  DT_SIN_PRI = utc("2022-03-06"), SEM_PRI = "10"))
  # Reescreve o banco sem CO_MUN_NOT, como faria uma versão nova do Ministério.
  arq <- "dados/brutos/INFLUD22-teste.parquet"
  # mmap = FALSE: com o arquivo mapeado na memória, o Windows recusa sobrescrevê-lo (erro 1224).
  t <- arrow::read_parquet(arq, mmap = FALSE); t$CO_MUN_NOT <- NULL
  arrow::write_parquet(t, arq)
  registrar_fonte(arq, url = "https://exemplo/x", descricao = "FABRICADO", substituir = TRUE)
  expect_error(preparar_sivep(2022, fontes = f), "coluna\\(s\\) faltando em INFLUD22-teste.parquet: CO_MUN_NOT")
})

test_that("validar_codigos_ibge aceita 6 dígitos do RJ como texto e recusa o resto", {
  expect_invisible(validar_codigos_ibge(c("330455", "330010")))
  expect_error(validar_codigos_ibge(c("330455", "3304557")), "1 valor\\(es\\) de código fora do padrão .*: 3304557")
  expect_error(validar_codigos_ibge(c("330455", "355030"), "CO_MUN_RES"), "CO_MUN_RES fora do padrão.*355030")
  expect_error(validar_codigos_ibge(330455), "não é texto \\(numeric\\)")
  expect_error(validar_codigos_ibge(c("330455", NA)), "1 valor\\(es\\) vazio\\(s\\)")
  expect_invisible(validar_codigos_ibge(c("330455", NA), permitir_na = TRUE))
})

test_that("validar_municipios_rj aceita os da lista e recusa código no padrão que não existe", {
  lista <- c("330010", "330455")
  expect_invisible(validar_municipios_rj(c("330455", "330455", NA), lista))
  # 339999 tem o formato certo, mas não é município: sumiria numa junção sem aviso.
  expect_error(validar_municipios_rj(c("330455", "339999"), lista, "CO_MUN_RES"),
               "CO_MUN_RES fora da lista de municípios: 339999")
})

test_that("validar_datas usa a janela do ano EPIDEMIOLÓGICO, não do civil", {
  # Semana 53 de 2025 (30/12/2025) é do banco de 2025; 31/12/2023 é da semana 1 de 2024.
  expect_invisible(validar_datas(as.Date(c("2025-12-30", "2024-12-29")), 2025L))
  expect_invisible(validar_datas(as.Date("2023-12-31"), 2024L))
  # 01/01/2022 é da semana 52 de 2021: um corte "data >= 2022-01-01" a aceitaria.
  expect_error(validar_datas(as.Date("2022-01-01"), 2022L), "1 fichas com ano epidemiológico diferente.*2022-01-01")
  # Anos impossíveis, como os registrados em outro projeto sobre este banco.
  expect_error(validar_datas(as.Date(c("1695-05-10", "5202-01-20", "2022-03-06")), 2022L),
               "2 fichas com ano epidemiológico diferente.*1695-05-10, 5202-01-20")
})

test_that("validar_datas para em data vazia e em tipo errado", {
  expect_error(validar_datas(as.Date(c("2022-03-06", NA)), 2022L), "1 fichas sem DT_SIN_PRI")
  expect_error(validar_datas("2022-03-06", 2022L), "não é Date \\(character\\)")
})

test_that("ano do banco por linha: cada ficha é conferida com o seu próprio banco", {
  d <- as.Date(c("2022-03-06", "2023-03-06"))
  expect_invisible(validar_datas(d, c(2022L, 2023L)))
  expect_error(validar_datas(d, c(2023L, 2023L)), "1 fichas com ano epidemiológico diferente")
})
