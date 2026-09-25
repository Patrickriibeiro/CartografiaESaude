# Testes dos leitos do CNES (CS-034). Dados FABRICADOS.
# fixtures/leitos_sintetico.zip: CSV latin-1 com ";" e CO_IBGE, como o arquivo real de 2025.

malha_leitos <- data.frame(cod6 = c("330330", "330380", "330455"),
                           nome = c("Niterói", "Paraty", "Rio de Janeiro"), stringsAsFactors = FALSE)

test_that("nomes de coluna dos formatos de 2022 e 2023+ viram o mesmo nome", {
  expect_equal(normalizar_coluna(c("UTI TOTAL - SUS", "UTI_TOTAL_SUS", "LEITOS SUS", "\"COMP\"")),
               c("UTI_TOTAL_SUS", "UTI_TOTAL_SUS", "LEITOS_SUS", "COMP"))
})

test_that("nome do CNES casa com a malha sem acento e com as grafias antigas", {
  expect_equal(cod6_por_nome_cnes(c("NITEROI", "Niterói", "PARATI", "RIO DE JANEIRO"), malha_leitos),
               c("330330", "330330", "330380", "330455"))
  expect_error(cod6_por_nome_cnes(c("NITEROI", "CIDADE INVENTADA"), malha_leitos),
               "sem correspondência na malha: CIDADE INVENTADA")
})

item_zip <- function(dir) {
  destino <- file.path(dir, "Leitos_csv_2025.zip")
  file.copy(file.path(raiz_projeto, "tests", "testthat", "fixtures", "leitos_sintetico.zip"), destino)
  registrar_fonte(destino, url = "https://exemplo/leitos", descricao = "FABRICADO")
  list(ano = 2025L, destino = destino, arquivo_no_zip = "Leitos_2025.csv", codificacao = "latin1", separador = ";")
}

test_that("leitura do zip em latin-1: só julho, só RJ, zero onde não há estabelecimento", {
  projeto_temporario()
  # item criado ANTES da chamada: como argumento direto, item_zip() só rodaria quando
  # usado (avaliação preguiçosa), depois de verificar_manifesto() já ter lido o manifesto.
  it <- item_zip("dados/brutos")
  l <- ler_leitos_ano(it, malha_leitos)
  expect_equal(l$cod6, c("330330", "330380", "330455"))
  expect_equal(l$leitos_sus, c(100, 20, 0))        # junho (999) e Recife (PE) ficam de fora
  expect_equal(l$uti_sus, c(10, 0, 0))
  expect_equal(l$estabelecimentos, c(1L, 1L, 0L))
  expect_equal(l$ano, rep(2025L, 3))
})

test_that("codificação declarada errada para a leitura, em vez de estragar os nomes", {
  projeto_temporario()
  it <- item_zip("dados/brutos"); it$codificacao <- "UTF-8"   # o arquivo é latin-1
  expect_error(ler_leitos_ano(it, malha_leitos), "2 linha.s. de Leitos_2025.csv inválidas em UTF-8")
})

test_that("competência ausente para, em vez de devolver zero leito", {
  projeto_temporario()
  it <- item_zip("dados/brutos")
  expect_error(ler_leitos_ano(it, malha_leitos, mes = "03"), "Competência 202503 ausente")
})

test_that("nome e CO_IBGE discordantes param a leitura", {
  projeto_temporario()
  m <- malha_leitos; m$cod6[m$nome == "Paraty"] <- "330999"   # malha diz outro código para Paraty
  it <- item_zip("dados/brutos")
  expect_error(ler_leitos_ano(it, m), "1 estabelecimentos com nome e CO_IBGE discordantes")
})

test_that("Spearman: relação monotônica perfeita dá rho = 1 e IC [1, 1]; sem relação, IC cruza o zero", {
  cod <- sprintf("3300%02d", 1:20)
  ind <- data.frame(cod6 = rep(cod, 2), agente = rep(c("vsr", "influenza"), each = 20), ano = 2024L,
                    casos = rep(1:20, 2), populacao = 1000)
  leitos <- data.frame(cod6 = cod, ano = 2024L, leitos_sus_100k = (1:20)^2, uti_sus_100k = rep(c(5, 1, 9, 3), 5))
  sp <- correlacionar_leitos(ind, leitos, nboot = 200, semente = 1)
  a <- sp[sp$medida == "leitos_sus_100k", ]
  expect_equal(c(a$rho, a$ic_inf, a$ic_sup), c(1, 1, 1))
  b <- sp[sp$medida == "uti_sus_100k", ]
  expect_true(b$ic_inf < 0 && b$ic_sup > 0)
  expect_equal(sp$municipios, c(20L, 20L))
  # Mesma semente, mesmo IC.
  expect_identical(correlacionar_leitos(ind, leitos, nboot = 200, semente = 1), sp)
})

test_that("resumo regional soma leitos e população antes de dividir", {
  leitos <- data.frame(cod6 = c("330010", "330020"), ano = 2024L, leitos_sus = c(10, 0), uti_sus = c(2, 0),
                       populacao = c(1000, 9000))
  reg <- data.frame(cod6 = c("330010", "330020"), cod_regiao = "33001", regiao = "Baía da Ilha Grande")
  ir <- data.frame(cod_regiao = "33001", ano = 2024L, agente = c("vsr", "influenza"), casos = c(3L, 2L))
  r <- resumir_leitos_regiao(leitos, reg, ir)
  expect_equal(r$leitos_sus_100k, 10 / 10000 * 1e5)   # 100, não a média de 1.000 e 0
  expect_equal(r$taxa_srag_100k, 5 / 10000 * 1e5)
  expect_equal(r$regiao, "Baía da Ilha Grande")
})
