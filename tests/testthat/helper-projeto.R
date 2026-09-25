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
