# Testes do download e do preparo do SIVEP (CS-005, CS-006). Sem rede.
# Os dados abaixo são FABRICADOS: poucas linhas com o formato real do PARQUET
# (datas como timestamp à meia-noite UTC, códigos como texto ou decimal).

# banco_sintetico(), escrever_banco_sivep() e utc() estão em helper-projeto.R.


test_that("semana_epidemiologica segue o calendário do Ministério, inclusive semana 53", {
  datas <- as.Date(c("2022-01-02", "2022-01-01", "2023-12-31", "2024-12-29",
                     "2025-12-27", "2025-12-28", "2026-01-03", "2026-01-04", NA))
  s <- semana_epidemiologica(datas)
  expect_equal(s$ano_epi,    c(2022L, 2021L, 2024L, 2025L, 2025L, 2025L, 2025L, 2026L, NA))
  expect_equal(s$semana_epi, c(1L,    52L,   1L,    1L,    52L,   53L,   53L,   1L,    NA))
})

test_that("bancos_sivep lê a configuração e recusa ano ausente", {
  f <- list(sivep = list(bancos = list(
    list(ano = 2023, url = "https://x/INFLUD23-v.parquet", versao = "v"),
    list(ano = 2022, url = "https://x/INFLUD22-v.parquet", versao = "v"))))
  b <- bancos_sivep(fontes = f)
  expect_equal(b$ano, c(2022L, 2023L))
  expect_equal(b$destino[1], file.path("dados", "brutos", "INFLUD22-v.parquet"))
  expect_error(bancos_sivep(2024, fontes = f), "Ano sem banco")
})

test_that("a configuração real tem os 4 anos do estudo em PARQUET, com versão", {
  b <- bancos_sivep(2022:2025, fontes = yaml::read_yaml(file.path(raiz_projeto, "config", "fontes.yml")))
  expect_equal(nrow(b), 4)
  expect_true(all(grepl("\\.parquet$", b$url)))
  expect_true(all(nzchar(b$versao)))
})

test_that("preparo fica só com residentes do RJ e mantém o código como texto", {
  projeto_temporario()
  f <- banco_sintetico(data.frame(
    CO_MUN_RES = c("330455", "355030", "330010", "313670"),
    SG_UF = c("RJ", "SP", "RJ", "MG"),
    DT_SIN_PRI = utc(c("2022-03-06", "2022-03-06", "2022-05-10", "2022-05-10")),
    SEM_PRI = c("10", "10", "19", "19")
  ))
  d <- preparar_sivep(2022, fontes = f)
  expect_equal(nrow(d), 2)
  expect_equal(d$CO_MUN_RES, c("330455", "330010"))
  expect_type(d$CO_MUN_RES, "character")
})

test_that("data à meia-noite UTC vira o mesmo dia, em qualquer fuso da máquina", {
  projeto_temporario()
  withr::local_timezone("America/Sao_Paulo")
  f <- banco_sintetico(data.frame(
    CO_MUN_RES = "330455", SG_UF = "RJ",
    DT_SIN_PRI = utc("2022-01-02"), DT_NOTIFIC = utc("2022-01-05"), SEM_PRI = "01"
  ))
  tipo <- arrow::read_parquet("dados/brutos/INFLUD22-teste.parquet",
                              as_data_frame = FALSE)$schema$DT_SIN_PRI$type$ToString()
  expect_equal(tipo, "timestamp[ns]")  # mesmo tipo do banco real
  d <- preparar_sivep(2022, fontes = f)
  expect_equal(d$DT_SIN_PRI, as.Date("2022-01-02"))  # no fuso local seria 2022-01-01
  expect_equal(d$DT_NOTIFIC, as.Date("2022-01-05"))
  expect_equal(d$semana_epi, 1L)
  expect_equal(d$ano_epi, 2022L)
})

test_that("códigos viram inteiro; vazio vira NA; texto estranho para o preparo", {
  projeto_temporario()
  f <- banco_sintetico(data.frame(
    CO_MUN_RES = c("330455", "330010"), SG_UF = "RJ",
    DT_SIN_PRI = utc(c("2022-03-06", "2022-03-07")),
    PCR_SARS2 = c("1", ""), CLASSI_FIN = c("5", NA)
  ))
  d <- preparar_sivep(2022, fontes = f)
  expect_identical(d$PCR_SARS2, c(1L, NA))
  expect_identical(d$CLASSI_FIN, c(5L, NA))

  expect_error(para_inteiro(c("1", "X"), "PCR_VSR"), "não numéricos em PCR_VSR: X")
})

test_that("ficha fora do ano epidemiológico do banco para o preparo", {
  projeto_temporario()
  f <- banco_sintetico(data.frame(
    CO_MUN_RES = "330455", SG_UF = "RJ", DT_SIN_PRI = utc("2023-06-01")
  ), ano = 2022L)
  expect_error(preparar_sivep(2022, fontes = f), "ano epidemiológico diferente")
})

test_that("código 33 com UF diferente de RJ para o preparo", {
  projeto_temporario()
  f <- banco_sintetico(data.frame(
    CO_MUN_RES = "330455", SG_UF = "SP", DT_SIN_PRI = utc("2022-06-01")
  ))
  expect_error(preparar_sivep(2022, fontes = f), "SG_UF != RJ")
})

test_that("preparo recusa banco adulterado depois do registro", {
  projeto_temporario()
  f <- banco_sintetico(data.frame(
    CO_MUN_RES = "330455", SG_UF = "RJ", DT_SIN_PRI = utc("2022-06-01")
  ))
  write("lixo", "dados/brutos/INFLUD22-teste.parquet", append = TRUE)
  expect_error(preparar_sivep(2022, fontes = f), "SHA-256 divergente")
})

test_that("diagnóstico conta semana divergente e sintoma após digitação", {
  d <- data.frame(
    ano_banco = 2025L, CO_MUN_RES = c("330455", "330010"), CO_MUN_NOT = c("330455", "330455"),
    SEM_PRI = c("01", "10"), semana_epi = c(53L, 10L),
    DT_SIN_PRI = as.Date(c("2025-12-28", "2025-03-05")),
    DT_DIGITA = as.Date(c("2026-01-10", "2025-03-01")),
    CLASSI_FIN = c(NA, 5L),
    PCR_RESUL = c(5L, 1L),   # 5 = aguardando resultado: não conta como testado
    RES_AN = c(NA, 2L),
    HOSPITAL = c(2L, NA)
  )
  g <- diagnosticar_sivep(d)
  expect_equal(g$fichas_rj, 2)
  expect_equal(g$sem_pri_diverge, 1)
  expect_equal(g$sintomas_apos_digitacao, 1)
  expect_equal(g$classi_fin_vazio, 1)
  expect_equal(g$com_resultado_de_teste, 1)
  expect_equal(g$nao_internado, 1)
  expect_equal(g$internacao_ignorada_ou_vazia, 1)
  expect_equal(g$residencia_diferente_notificacao, 1)
})

test_that("download retoma de onde parou e o arquivo final é idêntico à origem", {
  origem <- withr::local_tempfile(fileext = ".bin")
  writeBin(as.raw(0:255), origem)
  url <- url_arquivo(origem)
  projeto_temporario()
  dir.create("dados/externos", recursive = TRUE)
  writeBin(as.raw(0:99), "dados/externos/x.bin.parcial")  # simula queda aos 100 bytes

  baixar_arquivo(url, "dados/externos/x.bin")
  expect_identical(readBin("dados/externos/x.bin", "raw", 1000), as.raw(0:255))
  expect_false(file.exists("dados/externos/x.bin.parcial"))
})

test_that("download que falha preserva o parcial e explica como retomar", {
  projeto_temporario()
  expect_error(
    suppressMessages(baixar_arquivo("file:///nao/existe.bin", "dados/externos/y.bin",
                                    tentativas = 2, espera_s = 0)),
    "próxima execução retoma"
  )
  expect_false(file.exists("dados/externos/y.bin"))
})
