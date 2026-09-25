# Testes da população (CS-011) e da malha (CS-014).
# População: respostas SIDRA FABRICADAS, no formato real da API, sem rede.
# Malha: teste de integração sobre o arquivo real, pulado se ele não foi baixado.

# Escreve uma resposta SIDRA falsa (1ª linha = rótulos, como a API real).
sidra_falso <- function(destino, ano, valores) {
  cabecalho <- data.frame(D1C = "Município (Código)", D1N = "Município",
                          D3N = "Ano", V = "Valor")
  corpo <- data.frame(D1C = names(valores), D1N = paste("Município", names(valores)),
                      D3N = as.character(ano), V = unname(valores))
  dir.create(dirname(destino), recursive = TRUE, showWarnings = FALSE)
  jsonlite::write_json(rbind(cabecalho, corpo), destino)
  registrar_fonte(destino, url = "https://exemplo/sidra", descricao = "FABRICADO")
}

fontes_pop_falsas <- function() {
  sidra_falso("dados/externos/c2022.json", 2022, c("3300100" = "1000", "3300209" = "500"))
  sidra_falso("dados/externos/e2024.json", 2024, c("3300100" = "1700", "3300209" = "500"))
  sidra_falso("dados/externos/e2025.json", 2025, c("3300100" = "1710", "3300209" = "510"))
  sidra_falso("dados/externos/e2021.json", 2021, c("3300100" = "9999", "3300209" = "9999"))
  item <- function(ano, destino, data, desc) {
    list(ano = ano, tabela = 0, descricao = desc, url = "https://exemplo/sidra",
         destino = destino, data_referencia = data)
  }
  list(ibge = list(populacao = list(
    item(2022, "dados/externos/c2022.json", "2022-08-01", "Censo 2022"),
    item(2024, "dados/externos/e2024.json", "2024-07-01", "Estimativa 2024"),
    item(2025, "dados/externos/e2025.json", "2025-07-01", "Estimativa 2025"),
    item(2021, "dados/externos/e2021.json", "2021-07-01", "Estimativa 2021 (pré-Censo; só diagnóstico)")
  )))
}

test_that("ler_sidra_json descarta a linha de rótulos e cria o cod6", {
  projeto_temporario()
  sidra_falso("dados/externos/x.json", 2022, c("3304557" = "6211223"))
  x <- ler_sidra_json("dados/externos/x.json")
  expect_equal(nrow(x), 1)
  expect_equal(x$cod6, "330455")
  expect_equal(x$populacao, 6211223)
  expect_equal(x$ano_ref, 2022L)
})

test_that("valor especial do SIDRA ('-', '...', 'X') para a leitura", {
  projeto_temporario()
  sidra_falso("dados/externos/x.json", 2022, c("3300100" = "1000", "3300209" = "..."))
  expect_error(ler_sidra_json("dados/externos/x.json"), "não numérico")
})

test_that("2023 é interpolado nas datas de referência reais, não no meio do caminho", {
  projeto_temporario()
  pop <- montar_populacao(2022:2025, "interpolacao", fontes = fontes_pop_falsas())
  expect_equal(nrow(pop), 8)
  p23 <- pop$populacao[pop$ano == 2023 & pop$cod6 == "330010"]
  peso <- as.numeric(as.Date("2023-07-01") - as.Date("2022-08-01")) /
          as.numeric(as.Date("2024-07-01") - as.Date("2022-08-01"))  # 334 / 700
  expect_equal(p23, as.integer(round(1000 + peso * 700)))  # 1334, não 1350
  expect_equal(p23, 1334L)
  expect_match(unique(pop$fonte[pop$ano == 2023]), "peso 0.4771")
})

test_that("método 'anterior' repete o Censo em 2023", {
  projeto_temporario()
  pop <- montar_populacao(2022:2025, "anterior", fontes = fontes_pop_falsas())
  expect_equal(pop$populacao[pop$ano == 2023], pop$populacao[pop$ano == 2022])
})

test_that("a estimativa pré-Censo (2021) nunca entra no denominador", {
  projeto_temporario()
  pop <- montar_populacao(2022:2025, fontes = fontes_pop_falsas())
  expect_false(any(pop$populacao == 9999))
  expect_error(montar_populacao(2021:2022, fontes = fontes_pop_falsas()), "Sem população para 2021")
})

test_that("população sai inteira, sem NA, um registro por município e ano", {
  projeto_temporario()
  pop <- montar_populacao(2022:2025, fontes = fontes_pop_falsas())
  expect_type(pop$populacao, "integer")
  expect_false(anyNA(pop$populacao))
  expect_equal(anyDuplicated(pop[, c("cod6", "ano")]), 0)
  expect_equal(as.vector(table(pop$ano)), c(2, 2, 2, 2))
})

test_that("diagnóstico mede a razão estimativa / Censo por município", {
  projeto_temporario()
  d <- diagnosticar_populacao(fontes = fontes_pop_falsas())
  expect_equal(d$razao_2024_censo[d$cod6 == "330010"], 1.7)
  expect_equal(d$razao_2024_censo[d$cod6 == "330020"], 1)
})

# ---- integração com os arquivos reais (pulados se não baixados) ----

test_that("malha real: 92 municípios válidos, SIRGAS 2000, cod6 único", {
  withr::local_dir(raiz_projeto)
  skip_if_not(file.exists("dados/externos/RJ_Municipios_2022.zip"), "malha não baixada")
  m <- ler_malha_municipal()
  expect_equal(nrow(m), 92)
  expect_equal(sf::st_crs(m)$epsg, 4674L)
  expect_true(all(sf::st_is_valid(m)))
  expect_equal(anyDuplicated(m$cod6), 0)
  expect_true(all(nchar(m$cod6) == 6 & startsWith(m$cod6, "33")))
  expect_true("Niterói" %in% m$nome)  # acentos lidos em UTF-8
  # CS-015: área oficial do RJ ≈ 43.750 km² (tolerância de 2 %)
  expect_equal(sum(m$area_km2), 43750, tolerance = 0.02)
  expect_equal(as.numeric(sum(sf::st_area(m))) / 1e6, 43750, tolerance = 0.02)
})

test_that("malha real casa com as fichas do SIVEP pela chave de 6 dígitos", {
  withr::local_dir(raiz_projeto)
  skip_if_not(file.exists("dados/externos/RJ_Municipios_2022.zip"), "malha não baixada")
  skip_if_not(file.exists("dados/intermediarios/sivep_rj.parquet"), "SIVEP não preparado")
  m <- ler_malha_municipal()
  codigos_sivep <- unique(arrow::read_parquet("dados/intermediarios/sivep_rj.parquet",
                                              col_select = "CO_MUN_RES")$CO_MUN_RES)
  expect_equal(length(codigos_sivep), 92)
  expect_true(all(codigos_sivep %in% m$cod6))
  expect_equal(sum(codigos_sivep %in% m$cod7), 0)  # com 7 dígitos, nada casaria
})

test_that("população real: 92 × 4, soma de 2022 igual ao Censo do estado", {
  withr::local_dir(raiz_projeto)
  skip_if_not(file.exists("dados/externos/sidra_4714_censo_2022_rj.json"), "SIDRA não baixado")
  pop <- montar_populacao()
  expect_equal(nrow(pop), 92 * 4)
  expect_equal(sum(pop$populacao[pop$ano == 2022]), 16055174)
  expect_true(all(pop$cod6[pop$ano == 2022] %in% ler_malha_municipal()$cod6))
})
