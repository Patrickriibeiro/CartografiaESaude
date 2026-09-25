# Funções de validação (CS-009): as quatro do PDF. Falham alto com stop(), nunca
# corrigem em silêncio. Devolvem o próprio argumento de forma invisível, para
# poderem ser encadeadas. O pipeline as usa nos pontos onde antes havia a mesma
# regra escrita à mão (preparar_sivep, completar_municipios...).

#' Mostra no máximo `n` exemplos de valores ruins numa mensagem de erro.
exemplos <- function(x, n = 5) {
  u <- unique(x)
  paste0(paste(utils::head(u, n), collapse = ", "), if (length(u) > n) sprintf(" (e mais %d)", length(u) - n) else "")
}

#' Para se faltar alguma das `colunas` em `nomes` (os nomes de um data.frame ou
#' do esquema de um arquivo). Coluna faltante é o erro de quem troca de versão
#' de banco: sem este teste, o arrow diria só "Can't subset columns".
validar_variaveis <- function(nomes, colunas, onde = "dado") {
  faltam <- setdiff(colunas, nomes)
  if (length(faltam) > 0) {
    stop(length(faltam), " coluna(s) faltando em ", onde, ": ", exemplos(faltam, 10), call. = FALSE)
  }
  invisible(nomes)
}

#' Para se algum código não for um código IBGE de município do RJ com 6
#' dígitos, como TEXTO ("330455"): começa com o prefixo da UF e tem 6 dígitos.
#' Número (330455) também para: lido como número, "3300100" e "0330010" perdem
#' o sentido (ADR-0007). NA para, salvo com `permitir_na = TRUE`.
validar_codigos_ibge <- function(codigos, campo = "código", prefixo_uf = PREFIXO_UF_RJ, permitir_na = FALSE) {
  if (!is.character(codigos)) stop(campo, " não é texto (", class(codigos)[1], "); a chave é texto (ADR-0007)", call. = FALSE)
  na <- is.na(codigos)
  if (any(na) && !permitir_na) stop(sum(na), " valor(es) vazio(s) em ", campo, call. = FALSE)
  padrao <- paste0("^", prefixo_uf, "[0-9]{4}$")
  ruins <- codigos[!na & !grepl(padrao, codigos)]
  if (length(ruins) > 0) {
    stop(length(ruins), " valor(es) de ", campo, " fora do padrão ", padrao, ": ", exemplos(ruins), call. = FALSE)
  }
  invisible(codigos)
}

#' Para se algum código não estiver na lista de municípios do estudo (os 92 da
#' malha e da população). Um código no padrão certo pode não existir, e sumiria
#' numa junção sem aviso.
validar_municipios_rj <- function(codigos, municipios, campo = "Município") {
  fora <- setdiff(unique(codigos[!is.na(codigos)]), municipios)
  if (length(fora) > 0) {
    stop(campo, " fora da lista de municípios: ", exemplos(sort(fora)), call. = FALSE)
  }
  invisible(codigos)
}

#' Para se alguma data estiver vazia ou fora do ano epidemiológico do banco.
#' A janela é o ano EPIDEMIOLÓGICO (CS-036), não o civil: 01/01/2022 é da
#' semana 52 de 2021 e ficaria de fora; 30/12/2025 é da semana 53 de 2025 e
#' fica dentro. Anos impossíveis (1695, 5202 — registrados em outro projeto
#' sobre este banco) caem aqui. Como o ano epidemiológico termina no máximo em
#' 3 de janeiro seguinte, nenhuma data aceita passa da data de versão do banco.
validar_datas <- function(datas, ano_banco, campo = "DT_SIN_PRI") {
  if (!inherits(datas, "Date")) stop(campo, " não é Date (", class(datas)[1], ")", call. = FALSE)
  na <- is.na(datas)
  if (any(na)) stop(sum(na), " fichas sem ", campo, call. = FALSE)
  ano_epi <- semana_epidemiologica(datas)$ano_epi
  fora <- ano_epi != ano_banco
  if (any(fora)) {
    stop(sum(fora), " fichas com ano epidemiológico diferente do ano do banco (", campo, ": ",
         exemplos(format(sort(unique(datas[fora])))), ")", call. = FALSE)
  }
  invisible(datas)
}
