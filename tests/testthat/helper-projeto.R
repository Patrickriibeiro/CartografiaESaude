# Carregado automaticamente pelo testthat antes dos testes (arquivos helper-*.R).
# Define a raiz do projeto e carrega todas as funções de R/.

raiz_projeto <- normalizePath(file.path(testthat::test_path(), "..", ".."),
                              winslash = "/")

for (arquivo in list.files(file.path(raiz_projeto, "R"), pattern = "^funcoes_.*\\.R$",
                           full.names = TRUE)) {
  source(arquivo, encoding = "UTF-8")
}

#' Cria um projeto descartável numa pasta temporária e entra nele.
#' Tudo o que o teste escrever some no fim do teste.
projeto_temporario <- function(env = parent.frame()) {
  tmp <- withr::local_tempdir(.local_envir = env)
  withr::local_dir(tmp, .local_envir = env)
  dir.create(file.path("dados", "brutos"), recursive = TRUE)
  tmp
}

escrever_arquivo <- function(caminho, conteudo) {
  dir.create(dirname(caminho), recursive = TRUE, showWarnings = FALSE)
  writeLines(conteudo, caminho)
  caminho
}

utc <- function(x) as.POSIXct(x, tz = "UTC")

#' Grava um banco PARQUET com as colunas do SIVEP, no MESMO tipo do banco real,
#' e registra no manifesto. `linhas` traz só as colunas que o teste quer
#' preencher; as demais ficam vazias.
escrever_banco_sivep <- function(linhas, arquivo) {
  base <- as.data.frame(
    setNames(replicate(length(COLUNAS_SIVEP), rep(NA_character_, nrow(linhas)),
                       simplify = FALSE), COLUNAS_SIVEP),
    stringsAsFactors = FALSE
  )
  for (col in COLUNAS_DATA_SIVEP) base[[col]] <- as.POSIXct(rep(NA, nrow(linhas)), tz = "UTC")
  for (col in intersect(names(linhas), COLUNAS_SIVEP)) base[[col]] <- linhas[[col]]
  # O banco real guarda timestamp[ns] SEM fuso; o R gravaria timestamp[us, tz=UTC].
  # Sem este cast o teste do fuso exercita um tipo que não existe nos dados reais.
  tabela <- arrow::arrow_table(base)
  for (col in COLUNAS_DATA_SIVEP) tabela[[col]] <- tabela[[col]]$cast(arrow::timestamp("ns"))
  dir.create(dirname(arquivo), recursive = TRUE, showWarnings = FALSE)
  arrow::write_parquet(tabela, arquivo)
  registrar_fonte(arquivo, url = paste0("https://exemplo/", basename(arquivo)),
                  descricao = "FABRICADO para teste")
}

#' Um banco sintético de um ano; devolve a configuração de fontes apontando para ele.
banco_sintetico <- function(linhas, ano = 2022L) {
  arquivo <- sprintf("dados/brutos/INFLUD%02d-teste.parquet", ano %% 100)
  escrever_banco_sivep(linhas, arquivo)
  list(sivep = list(bancos = list(list(
    ano = ano, url = paste0("https://exemplo/", basename(arquivo)), versao = "teste"
  ))))
}

#' Lê a base sintética do CS-010 (tests/testthat/fixtures/sivep_sintetico.csv).
#' Tudo vem como texto, como nos bancos reais; datas viram timestamp UTC.
ler_fixture_sivep <- function() {
  f <- utils::read.csv(file.path(raiz_projeto, "tests", "testthat", "fixtures", "sivep_sintetico.csv"),
                       colClasses = "character", na.strings = "", encoding = "UTF-8")
  # O CSV traz só as colunas que os cenários usam; as demais existem vazias no banco real.
  for (col in setdiff(COLUNAS_SIVEP, names(f))) f[[col]] <- NA_character_
  for (col in COLUNAS_DATA_SIVEP) f[[col]] <- utc(f[[col]])
  f$ano <- as.integer(f$ano)
  f$esperado_codeteccao <- as.logical(f$esperado_codeteccao)
  f
}

#' Grava a base sintética como 4 bancos anuais e devolve a configuração de fontes.
bancos_da_fixture <- function(f = ler_fixture_sivep()) {
  bancos <- lapply(sort(unique(f$ano)), function(a) {
    arquivo <- sprintf("dados/brutos/INFLUD%02d-fixture.parquet", a %% 100)
    escrever_banco_sivep(f[f$ano == a, ], arquivo)
    list(ano = a, url = paste0("https://exemplo/", basename(arquivo)), versao = "fixture")
  })
  list(sivep = list(bancos = bancos))
}

#' Tipa a base sintética como o preparo faria, sem passar pelo PARQUET, para
#' comparar a classificação linha a linha com a resposta esperada.
tipar_fixture <- function(f = ler_fixture_sivep()) {
  for (col in COLUNAS_CODIGO_SIVEP) f[[col]] <- para_inteiro(f[[col]], col)
  f$ano_banco <- f$ano
  f
}
