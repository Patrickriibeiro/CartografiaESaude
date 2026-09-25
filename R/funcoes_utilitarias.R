# Funções utilitárias do projeto.

#' Cria a árvore de diretórios de dados e resultados, se ainda não existir.
#' Idempotente: rodar duas vezes não muda nada.
criar_diretorios <- function() {
  pastas <- c(
    file.path("dados", c("brutos", "intermediarios", "processados", "externos")),
    file.path("resultados", c("tabelas", "mapas", "estatistica", "objetos"))
  )
  for (p in pastas) dir.create(p, recursive = TRUE, showWarnings = FALSE)
  invisible(pastas)
}

# A implementar:
# salvar_resultado()   — CS-020
# registrar_fonte()    — CS-003 (manifesto de proveniência com SHA-256)
# verificar_manifesto()— CS-003
