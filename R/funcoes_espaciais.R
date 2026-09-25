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

# ---------------------------------------------------------------------------
# Vizinhança e pesos espaciais (CS-016)
# ---------------------------------------------------------------------------

#' Vizinhança por contiguidade Queen de 1ª ordem: são vizinhos os polígonos que
#' compartilham qualquer ponto de fronteira (Rook exigiria um trecho de aresta).
#'
#' O código cod6 de cada município vai para o atributo region.id da vizinhança,
#' para que dados sejam alinhados à matriz PELA CHAVE, nunca pela posição.
#' Para com erro se houver município sem vizinho ou mais de um bloco conexo:
#' nos dois casos o Moran fica mal definido, e o RJ não tem ilha-município.
criar_vizinhos_queen <- function(malha, queen = TRUE) {
  if (anyDuplicated(malha$cod6)) stop("cod6 repetido na malha", call. = FALSE)
  nb <- spdep::poly2nb(malha, queen = queen, row.names = malha$cod6)

  sem_vizinho <- malha$cod6[spdep::card(nb) == 0]
  if (length(sem_vizinho) > 0) {
    stop("Município(s) sem vizinho: ", paste(sem_vizinho, collapse = ", "), call. = FALSE)
  }
  componentes <- spdep::n.comp.nb(nb)$nc
  if (componentes != 1) {
    stop("A vizinhança tem ", componentes, " blocos desconectados; esperado 1", call. = FALSE)
  }
  nb
}

#' Pesos padronizados por linha (estilo "W"): cada município divide peso 1
#' igualmente entre os vizinhos, então a média ponderada dos vizinhos é a média
#' simples deles. zero.policy = FALSE: vizinho vazio é erro, não peso zero.
criar_pesos <- function(nb) {
  spdep::nb2listw(nb, style = "W", zero.policy = FALSE)
}

#' Número de ligações (cada par de vizinhos conta 2 vezes, uma em cada sentido,
#' como em sum(card(nb))).
contar_ligacoes <- function(nb) sum(spdep::card(nb))

#' Tabela de vizinhos por município, para conferência e para o relatório.
resumir_vizinhanca <- function(nb, malha) {
  ids <- attr(nb, "region.id")
  nomes <- malha$nome[match(ids, malha$cod6)]
  data.frame(
    cod6 = ids,
    nome = nomes,
    n_vizinhos = spdep::card(nb),
    vizinhos = vapply(nb, function(v) paste(sort(nomes[v]), collapse = "; "), character(1)),
    stringsAsFactors = FALSE
  )
}

# ---------------------------------------------------------------------------
# Moran global e LISA (CS-017, ADR-0004)
# ---------------------------------------------------------------------------

N_PERMUTACOES <- 9999L   # resolução de p = 1e-4, abaixo do limiar mais exigente do FDR (0,05/92)
ALFA_LISA <- 0.05

#' Reordena `df` na ordem dos pesos (region.id = cod6). Para se faltar ou
#' sobrar município: alinhar por posição, e não pela chave, é o erro silencioso
#' que o CS-016 previu.
alinhar_a_pesos <- function(df, pesos, chave = "cod6") {
  ids <- attr(pesos, "region.id")
  if (is.null(ids)) stop("Pesos sem region.id: gere-os com criar_vizinhos_queen()", call. = FALSE)
  if (anyDuplicated(df[[chave]])) stop("Chave repetida ao alinhar aos pesos", call. = FALSE)
  if (!setequal(df[[chave]], ids)) {
    stop("Municípios do dado e dos pesos não coincidem (", length(setdiff(ids, df[[chave]])),
         " faltando, ", length(setdiff(df[[chave]], ids)), " sobrando)", call. = FALSE)
  }
  df[match(ids, df[[chave]]), , drop = FALSE]
}

#' Moran global I por permutação (Monte Carlo). H1 = autocorrelação positiva
#' (alternativa "greater"), que é a hipótese H1 da proposta. Semente fixa.
calcular_moran <- function(x, pesos, nsim = N_PERMUTACOES, semente = SEMENTE,
                           alternativa = "greater") {
  if (anyNA(x)) stop("NA na variável do Moran", call. = FALSE)
  if (length(x) != length(pesos$neighbours)) stop("Tamanho da variável difere dos pesos", call. = FALSE)
  set.seed(semente)
  m <- spdep::moran.mc(x, pesos, nsim = nsim, alternative = alternativa, zero.policy = FALSE)
  data.frame(I = unname(m$statistic), p_perm = m$p.value, nsim = nsim,
             esperado_I = -1 / (length(x) - 1), alternativa = alternativa)
}

#' Quadrante do diagrama de Moran: valor e média dos vizinhos, centrados na média.
#' HH = alto cercado de altos; LL = baixo cercado de baixos; HL e LH = discrepantes.
quadrante_moran <- function(x, pesos) {
  z <- x - mean(x)
  lag <- spdep::lag.listw(pesos, z, zero.policy = FALSE)
  q <- ifelse(z >= 0, ifelse(lag >= 0, "HH", "HL"), ifelse(lag >= 0, "LH", "LL"))
  data.frame(z = z, lag_z = lag, quadrante = q, stringsAsFactors = FALSE)
}

#' Moran local (LISA) por permutação condicional. Devolve, por unidade: Ii,
#' p_perm (bicaudal, da simulação), quadrante e n_vizinhos. Semente fixa via
#' iseed, que é o mecanismo reprodutível do spdep para as permutações locais.
calcular_lisa <- function(x, pesos, nsim = N_PERMUTACOES, semente = SEMENTE) {
  if (anyNA(x)) stop("NA na variável do LISA", call. = FALSE)
  lm <- spdep::localmoran_perm(x, pesos, nsim = nsim, alternative = "two.sided",
                               zero.policy = FALSE, iseed = semente)
  q <- quadrante_moran(x, pesos)
  data.frame(
    cod6 = attr(pesos, "region.id"),
    valor = x, z = q$z, lag_z = q$lag_z,
    Ii = unname(lm[, "Ii"]),
    p_perm = unname(lm[, "Pr(z != E(Ii)) Sim"]),
    quadrante = q$quadrante,
    n_vizinhos = spdep::card(pesos$neighbours),
    stringsAsFactors = FALSE
  )
}

#' Classifica o LISA em dois níveis (ADR-0004):
#'   confirmado — significativo após correção de Benjamini-Hochberg (FDR) em alfa;
#'   indicativo — significativo só sem correção (p_perm < alfa);
#'   ns         — não significativo.
#' `instavel` marca municípios com um único vizinho (CS-039): a classe deles
#' compara com um só município e é mantida, mas sinalizada.
classificar_lisa <- function(lisa, alfa = ALFA_LISA, metodo = "BH") {
  lisa$p_fdr <- stats::p.adjust(lisa$p_perm, method = metodo)
  lisa$nivel <- ifelse(lisa$p_fdr < alfa, "confirmado",
                       ifelse(lisa$p_perm < alfa, "indicativo", "ns"))
  lisa$classe <- ifelse(lisa$nivel == "ns", "ns", lisa$quadrante)
  lisa$instavel <- lisa$n_vizinhos == 1L
  lisa
}

#' Roda Moran global e LISA para cada agente × ano de `ind`, sobre `variavel`.
#' Devolve list(global = data.frame, lisa = data.frame).
executar_moran_lisa <- function(ind, pesos, variavel = "incid_eb_100k",
                                nsim = N_PERMUTACOES, semente = SEMENTE, alfa = ALFA_LISA,
                                rotulo_vizinhanca = "queen") {
  combos <- unique(ind[, c("agente", "ano")])
  combos <- combos[order(combos$agente, combos$ano), ]
  globais <- list(); locais <- list()
  for (k in seq_len(nrow(combos))) {
    ag <- combos$agente[k]; a <- combos$ano[k]
    x <- alinhar_a_pesos(ind[ind$agente == ag & ind$ano == a, ], pesos)
    g <- calcular_moran(x[[variavel]], pesos, nsim, semente)
    l <- classificar_lisa(calcular_lisa(x[[variavel]], pesos, nsim, semente), alfa)
    globais[[k]] <- cbind(agente = ag, ano = a, variavel = variavel,
                          vizinhanca = rotulo_vizinhanca, g, stringsAsFactors = FALSE)
    locais[[k]] <- cbind(agente = ag, ano = a, variavel = variavel, l, stringsAsFactors = FALSE)
  }
  list(global = do.call(rbind, globais), lisa = do.call(rbind, locais))
}

#' Contagens por agente × ano: significativos antes e depois do FDR, por
#' classe, e quantos instáveis entre eles. É a tabela do relatório.
resumir_lisa <- function(lisa, alfa = ALFA_LISA) {
  do.call(rbind, lapply(split(lisa, list(lisa$agente, lisa$ano), drop = TRUE), function(x) {
    conf <- x$nivel == "confirmado"; ind <- x$nivel == "indicativo"
    data.frame(
      agente = x$agente[1], ano = x$ano[1], n = nrow(x),
      esperado_por_acaso = nrow(x) * alfa,
      sig_sem_correcao = sum(conf | ind),
      sig_fdr = sum(conf),
      HH_confirmado = sum(conf & x$quadrante == "HH"), LL_confirmado = sum(conf & x$quadrante == "LL"),
      HH_indicativo = sum(ind & x$quadrante == "HH"), LL_indicativo = sum(ind & x$quadrante == "LL"),
      HL_LH_sig = sum((conf | ind) & x$quadrante %in% c("HL", "LH")),
      instaveis_sig = sum((conf | ind) & x$instavel),
      stringsAsFactors = FALSE)
  }))
}

#' Concordância entre duas classificações LISA (ex.: suavizada × bruta), por
#' agente × ano: proporção de municípios com a mesma classe.
comparar_lisa <- function(lisa_a, lisa_b, rotulos = c("suavizada", "bruta")) {
  chave <- c("agente", "ano", "cod6")
  j <- merge(lisa_a[, c(chave, "classe")], lisa_b[, c(chave, "classe")], by = chave,
             suffixes = paste0("_", rotulos))
  do.call(rbind, lapply(split(j, list(j$agente, j$ano), drop = TRUE), function(x) {
    ca <- x[[paste0("classe_", rotulos[1])]]; cb <- x[[paste0("classe_", rotulos[2])]]
    data.frame(agente = x$agente[1], ano = x$ano[1],
               concordancia = mean(ca == cb),
               sig_em_ambas = sum(ca != "ns" & cb != "ns"),
               sig_so_na_primeira = sum(ca != "ns" & cb == "ns"),
               sig_so_na_segunda = sum(ca == "ns" & cb != "ns"),
               stringsAsFactors = FALSE)
  }))
}

# calcular_lisa()        — CS-017
# classificar_lisa()     — CS-017
