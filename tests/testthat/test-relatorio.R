# Teste do relatório (CS-022): nenhum número de resultado digitado à mão.
# Trilha §3.3, invariante 2: todo número do relatório vem de resultados/ pelo
# código embutido. Este teste retira do .qmd o que é código, caminho e citação e
# procura números que sobraram no texto.

# Retira do texto tudo o que pode legitimamente conter dígitos. "(?s)" faz o
# ponto casar quebra de linha: sem ele, blocos de várias linhas não saem (erro
# da 1ª versão deste teste).
texto_digitado <- function(linhas) {
  s <- paste(linhas, collapse = "\n")
  s <- sub("(?s)^---\n.*?\n---\n", "", s, perl = TRUE)              # cabeçalho YAML
  s <- gsub("(?s)```\\{r[^}]*\\}.*?```", "", s, perl = TRUE)        # blocos de código
  s <- gsub("`r [^`]*`", "", s, perl = TRUE)                        # código embutido
  s <- gsub("`[^`]*`", "", s, perl = TRUE)                          # nomes de arquivo e código em linha
  s <- gsub("(?s)<!--.*?-->", "", s, perl = TRUE)                   # comentários
  s <- gsub("\\]\\([^)]*\\)", "]", s, perl = TRUE)                  # caminhos de imagem e link
  s <- gsub("\\{#[^}]*\\}", "", s, perl = TRUE)                     # atributos {#fig-x width=...}
  s <- gsub("@[A-Za-z_0-9]+", "", s, perl = TRUE)                   # citações
  linhas <- strsplit(s, "\n")[[1]]
  linhas[!grepl("^\\s*#", linhas)]                                  # títulos
}

# Números "soltos": não colados a letra, hífen ou dois-pontos (CoV-2, ADR-0004,
# R2, H1, EPSG:4674, 1ª). Anos (19xx/20xx) e a unidade "100 mil" são permitidos.
numeros_digitados <- function(linhas) {
  achados <- regmatches(linhas, gregexpr("(?<![\\p{L}\\d_\\-:./])\\d+(?:[.,]\\d+)*(?![\\p{L}\\dª°_\\-])",
                                         linhas, perl = TRUE))
  x <- unlist(achados)
  ok_ano <- grepl("^(19|20)\\d\\d$", x)
  ok_100mil <- x == "100" & any(grepl("100 mil", linhas))
  x[!(ok_ano | ok_100mil)]
}

test_that("o detector acha número digitado e ignora o que é legítimo", {
  exemplo <- c("---", "title: x 12", "---", "Foram 37.562 casos e `r fi(n)` fichas.",
               "```{r}", "x <- 99", "```", "SARS-CoV-2, ADR-0004, H1, R2, EPSG:4674, 1ª ordem, [@anselin1995].",
               "Em 2024, por 100 mil hab.", "## 4.2 Título", "![leg](resultados/mapas/lisa_vsr_2024.png){#fig-x width=85%}")
  expect_equal(numeros_digitados(texto_digitado(exemplo)), "37.562")
})

test_that("08_relatorio.qmd não tem número de resultado digitado no texto", {
  qmd <- readLines(file.path(raiz_projeto, "08_relatorio.qmd"), encoding = "UTF-8", warn = FALSE)
  achados <- numeros_digitados(texto_digitado(qmd))
  expect_identical(achados, character(0), info = paste("números digitados:", paste(achados, collapse = ", ")))
})

test_that("todo ADR de docs/decisoes/ é citado no relatório e na proposta v2 (CS-052)", {
  adrs <- sub("^(ADR-[0-9]{4}).*", "\\1", list.files(file.path(raiz_projeto, "docs", "decisoes"), pattern = "^ADR-[0-9]{4}.*\\.md$"))
  expect_gte(length(adrs), 7)
  qmd <- paste(readLines(file.path(raiz_projeto, "08_relatorio.qmd"), encoding = "UTF-8", warn = FALSE), collapse = "\n")
  prop <- paste(readLines(file.path(raiz_projeto, "docs", "proposta-v2.md"), encoding = "UTF-8", warn = FALSE), collapse = "\n")
  for (a in adrs) {
    expect_true(grepl(a, qmd, fixed = TRUE), info = paste(a, "ausente do relatório"))
    expect_true(grepl(a, prop, fixed = TRUE), info = paste(a, "ausente da proposta v2"))
  }
  expect_true(grepl("# Decisões de método", qmd, fixed = TRUE))
})

test_that("toda figura e citação do relatório existe", {
  qmd <- paste(readLines(file.path(raiz_projeto, "08_relatorio.qmd"), encoding = "UTF-8", warn = FALSE), collapse = "\n")
  figuras <- regmatches(qmd, gregexpr("\\]\\((resultados/[^)]+\\.png)\\)", qmd, perl = TRUE))[[1]]
  figuras <- sub("^\\]\\(", "", sub("\\)$", "", figuras))
  expect_gt(length(figuras), 0)
  bib <- paste(readLines(file.path(raiz_projeto, "referencias.bib"), encoding = "UTF-8"), collapse = "\n")
  chaves <- unique(sub("^@", "", regmatches(qmd, gregexpr("@[a-z_]+[0-9]*[a-z_0-9]*", qmd))[[1]]))
  chaves <- chaves[!chaves %in% c("fig", "tbl")]
  for (k in chaves) expect_match(bib, paste0("\\{", k, ","), info = k)
  skip_if_not(file.exists(file.path(raiz_projeto, "resultados", "mapas", "painel_lisa.png")), "mapas não gerados")
  expect_true(all(file.exists(file.path(raiz_projeto, figuras))))
})
