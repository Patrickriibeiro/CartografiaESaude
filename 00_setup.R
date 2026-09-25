# 00_setup.R — prepara o ambiente de toda execução
# Carregado por todos os scripts numerados. Não baixa dados nem calcula nada.

# Carrega as funções do projeto (R/funcoes_*.R)
for (arquivo in list.files("R", pattern = "^funcoes_.*\\.R$", full.names = TRUE)) {
  source(arquivo, encoding = "UTF-8", local = TRUE)  # no ambiente de quem chamou
}

criar_diretorios()

# Parâmetros do estudo (fonte: docs/proposta-v2.md §3.1)
ANOS_ESTUDO <- 2022:2025
PREFIXO_UF_RJ <- "33"
EPSG_SIRGAS2000 <- 4674
SEMENTE <- 20260925
