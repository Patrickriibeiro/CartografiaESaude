# Funções espaciais: malha municipal (CS-014) e estatística espacial.

#' Baixa a malha municipal oficial do IBGE (zip) e registra no manifesto.
obter_malha_municipal <- function(fontes = ler_fontes()) {
  m <- fontes$ibge$malha_municipal
  baixar_e_registrar(m$url, m$destino, descricao = m$descricao, versao = m$versao)
}

#' Lê a malha municipal do RJ direto do zip conferido, em SIRGAS 2000.
#'
#' Usa a malha oficial do IBGE em resolução completa, não a simplificada do
#' geobr: a simplificação apaga 8 pares de fronteiras no RJ (ADR-0006).
#' Devolve sf com cod7, cod6 (chave de junção com o SIVEP), nome e área, e para
#' se a malha não tiver exatamente os municípios esperados.
ler_malha_municipal <- function(fontes = ler_fontes(), n_esperado = 92L) {
  m <- fontes$ibge$malha_municipal
  verificar_manifesto(m$destino)
  caminho <- paste0("/vsizip/", normalizePath(m$destino, winslash = "/"), "/", m$camada)
  x <- sf::st_read(caminho, quiet = TRUE, options = "ENCODING=UTF-8")

  if (is.na(sf::st_crs(x)$epsg) || sf::st_crs(x)$epsg != EPSG_SIRGAS2000) {
    x <- sf::st_transform(x, EPSG_SIRGAS2000)
  }
  invalidas <- sum(!sf::st_is_valid(x))
  if (invalidas > 0) {
    message(invalidas, " geometria(s) inválida(s) corrigida(s) com st_make_valid()")
    x <- sf::st_make_valid(x)
  }

  malha <- sf::st_sf(
    cod7 = as.character(x$CD_MUN),
    cod6 = substr(as.character(x$CD_MUN), 1, 6),
    nome = x$NM_MUN,
    area_km2 = as.numeric(x$AREA_KM2),
    geometry = sf::st_geometry(x)
  )
  malha <- malha[order(malha$cod6), ]

  padrao <- paste0("^", PREFIXO_UF_RJ, "[0-9]{5}$")
  if (nrow(malha) != n_esperado) {
    stop("Malha com ", nrow(malha), " feições; esperado ", n_esperado, call. = FALSE)
  }
  if (!all(grepl(padrao, malha$cod7))) stop("Código IBGE fora do padrão na malha", call. = FALSE)
  if (anyDuplicated(malha$cod6)) stop("cod6 repetido na malha", call. = FALSE)
  if (!all(sf::st_is_valid(malha))) stop("Geometria inválida após correção", call. = FALSE)
  malha
}

# A implementar:
# criar_vizinhos_queen() — CS-016
# criar_pesos()          — CS-016
# calcular_moran()       — CS-017
# calcular_lisa()        — CS-017
# classificar_lisa()     — CS-017
