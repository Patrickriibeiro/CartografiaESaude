# Funções do SIVEP-Gripe: download, preparo e classificação por agente.

#' Baixa o dicionário de dados oficial do SIVEP-Gripe (CS-004) e o registra no
#' manifesto. Segunda chamada não rebaixa: confere o hash e sai.
obter_dicionario_sivep <- function(fontes = ler_fontes()) {
  d <- fontes$sivep$dicionario
  baixar_e_registrar(d$url, d$destino, descricao = d$descricao, versao = d$versao)
}

# A implementar:
# baixar_sivep()               — CS-005 (download direto do portal; NÃO microdatasus, ver ADR-0001)
# preparar_sivep()             — CS-006
# classificar_agente()         — CS-008
# aplicar_criterios_inclusao() — CS-008 (regra do ADR-0002)
