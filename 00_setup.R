# 00_setup.R — prepara o ambiente de toda execução
# Carregado por todos os scripts numerados. Não baixa dados nem calcula nada.
# Os parâmetros do estudo (ANOS_ESTUDO, PREFIXO_UF_RJ...) estão em
# R/funcoes_utilitarias.R e chegam junto com as funções.

# Carrega as funções do projeto (R/funcoes_*.R)
for (arquivo in list.files("R", pattern = "^funcoes_.*\\.R$", full.names = TRUE)) {
  source(arquivo, encoding = "UTF-8", local = TRUE)  # no ambiente de quem chamou
}

criar_diretorios()
