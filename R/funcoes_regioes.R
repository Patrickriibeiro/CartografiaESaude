# Escala de região de saúde (CS-030).
#
# A tabela município → região vem do geobr (IPEA), que republica a divisão do
# Ministério da Saúde. Só a TABELA é usada: a geometria regional sai de dissolver
# a malha oficial do IBGE (ADR-0006), para que as fronteiras regionais sejam
# exatamente a soma das municipais usadas no resto da análise.

# Nomes canônicos pelo código da região. O geobr 2023+ traz os nomes com
# acentuação corrompida ("Baixada Litorã¢Nea"); o código é a chave, o nome é nosso.
# Composição conferida em 2026-09-25 contra as páginas "Retratos Municipais" do
# TabNet da SES-RJ (91 municípios listados, todos na mesma região do geobr; a
# capital não aparece na lista da página e o geobr a põe na Metropolitana I).
REGIOES_SAUDE_RJ <- c(
  "33001" = "Baía da Ilha Grande",
  "33002" = "Baixada Litorânea",
  "33003" = "Centro-Sul",
  "33004" = "Médio Paraíba",
  "33005" = "Metropolitana I",
  "33006" = "Metropolitana II",
  "33007" = "Noroeste",
  "33008" = "Norte",
  "33009" = "Serrana"
)

#' Baixa a tabela de regiões de saúde do geobr e registra no manifesto.
#' O arquivo cobre o Brasil inteiro (com geometria simplificada que não usamos),
#' por isso vai para dados/brutos, fora do git, como os bancos do SIVEP.
obter_regioes_saude <- function(fontes = ler_fontes()) {
  r <- fontes$regioes_saude
  baixar_e_registrar(r$url, r$destino, descricao = r$descricao, versao = r$versao)
}

#' Tabela município → região de saúde do RJ: cod6, cod_regiao, regiao.
#' Lê só as colunas de atributo do parquet (a geometria fica no disco).
#' Para se não houver exatamente 92 municípios em 9 regiões, ou se aparecer
#' região sem nome canônico.
ler_regioes_saude <- function(fontes = ler_fontes(), n_municipios = 92L,
                              n_regioes = length(REGIOES_SAUDE_RJ)) {
  r <- fontes$regioes_saude
  verificar_manifesto(r$destino)
  x <- as.data.frame(arrow::read_parquet(r$destino, col_select = c("code_muni", "code_health_region")))
  # code_muni vem como número (double): format() evita "3.3e+06" e casas decimais.
  cod7 <- format(x$code_muni, scientific = FALSE, trim = TRUE)
  x <- x[substr(cod7, 1, 2) == PREFIXO_UF_RJ, ]
  cod7 <- cod7[substr(cod7, 1, 2) == PREFIXO_UF_RJ]
  tabela <- data.frame(
    cod6 = substr(cod7, 1, 6),
    cod_regiao = format(x$code_health_region, scientific = FALSE, trim = TRUE),
    stringsAsFactors = FALSE
  )
  validar_regioes(tabela, n_municipios, n_regioes)
}

#' Contrato da tabela município → região. Separado da leitura para ser testável
#' sem o arquivo de 21 MB.
validar_regioes <- function(tabela, n_municipios = 92L, n_regioes = length(REGIOES_SAUDE_RJ)) {
  if (anyDuplicated(tabela$cod6)) stop("Município em mais de uma região", call. = FALSE)
  if (nrow(tabela) != n_municipios) {
    stop("Tabela de regiões com ", nrow(tabela), " municípios; esperado ", n_municipios, call. = FALSE)
  }
  sem_nome <- setdiff(tabela$cod_regiao, names(REGIOES_SAUDE_RJ))
  if (length(sem_nome) > 0) {
    stop("Região sem nome canônico: ", paste(sem_nome, collapse = ", "), call. = FALSE)
  }
  if (length(unique(tabela$cod_regiao)) != n_regioes) {
    stop(length(unique(tabela$cod_regiao)), " regiões; esperado ", n_regioes, call. = FALSE)
  }
  tabela$regiao <- unname(REGIOES_SAUDE_RJ[tabela$cod_regiao])
  tabela[order(tabela$cod6), c("cod6", "cod_regiao", "regiao")]
}

#' Dissolve a malha municipal em regiões: um polígono por região, união das
#' geometrias dos seus municípios. A união é feita em SIRGAS 2000 / UTM 23S
#' (metros, geometria plana) e volta para o sistema original: em graus o sf
#' usaria a geometria esférica (s2), que pode deixar frestas entre vizinhos.
#' Para se algum município da malha ficar sem região ou vice-versa.
dissolver_regioes <- function(malha, regioes) {
  if (!setequal(malha$cod6, regioes$cod6)) {
    stop("Malha e tabela de regiões não têm os mesmos municípios", call. = FALSE)
  }
  crs <- sf::st_crs(malha)
  m <- sf::st_transform(malha, 31983)
  cod <- regioes$cod_regiao[match(m$cod6, regioes$cod6)]
  codigos <- sort(unique(cod))
  geometrias <- lapply(codigos, function(k) sf::st_union(sf::st_geometry(m)[cod == k]))
  out <- sf::st_sf(
    cod_regiao = codigos,
    regiao = unname(REGIOES_SAUDE_RJ[codigos]),
    n_municipios = as.integer(table(cod)[codigos]),
    area_km2 = vapply(codigos, function(k) sum(m$area_km2[cod == k]), numeric(1), USE.NAMES = FALSE),
    geometry = sf::st_transform(do.call(c, geometrias), crs)
  )
  if (!all(sf::st_is_valid(out))) out <- sf::st_make_valid(out)
  out
}

#' Soma casos e população dos municípios por região × agente × ano e recalcula
#' as taxas. Taxa regional = soma dos casos / soma da população, nunca a média
#' das taxas municipais (a média daria o mesmo peso a Rio de Janeiro e a Macuco).
agregar_por_regiao <- function(ind, regioes) {
  if (!all(ind$cod6 %in% regioes$cod6)) stop("Município do indicador sem região", call. = FALSE)
  d <- ind
  d$cod_regiao <- regioes$cod_regiao[match(d$cod6, regioes$cod6)]
  por <- stats::aggregate(cbind(casos, populacao, populacao_unica) ~ cod_regiao + agente + ano,
                          data = d, FUN = sum)
  por$regiao <- unname(REGIOES_SAUDE_RJ[por$cod_regiao])
  por$n_municipios <- as.integer(table(regioes$cod_regiao)[por$cod_regiao])
  por$incid_100k <- por$casos / por$populacao * 1e5
  por$incid_100k_pop2024 <- por$casos / por$populacao_unica * 1e5
  if (sum(por$casos) != sum(ind$casos)) stop("Agregação regional perdeu casos", call. = FALSE)
  por <- por[order(por$agente, por$ano, por$cod_regiao),
             c("cod_regiao", "regiao", "n_municipios", "agente", "ano", "casos", "populacao",
               "populacao_unica", "incid_100k", "incid_100k_pop2024")]
  rownames(por) <- NULL
  por
}

#' Vizinhança Queen entre regiões, com o código da região como region.id.
#' Reaproveita criar_vizinhos_queen(), que para se houver região isolada.
criar_vizinhos_regionais <- function(regioes_sf) {
  x <- regioes_sf
  x$cod6 <- x$cod_regiao  # criar_vizinhos_queen() usa a coluna cod6 como identificador
  criar_vizinhos_queen(x)
}

#' Moran global por agente × ano na escala regional, sobre a taxa BRUTA: com
#' regiões de 254 mil a 9,7 milhões de habitantes (Censo 2022), a instabilidade que o Bayes
#' empírico corrige nos municípios pequenos não existe aqui.
#' Com n = 9 o teste tem pouco poder e o LISA não é calculado (ADR-0004 exige
#' correção por múltiplos testes; com 9 unidades ela anula quase tudo): o
#' resultado é descritivo, e o relatório diz isso.
executar_moran_regional <- function(ind_regional, pesos, variavel = "incid_100k",
                                    nsim = N_PERMUTACOES, semente = SEMENTE) {
  combos <- unique(ind_regional[, c("agente", "ano")])
  combos <- combos[order(combos$agente, combos$ano), ]
  out <- lapply(seq_len(nrow(combos)), function(k) {
    x <- ind_regional[ind_regional$agente == combos$agente[k] & ind_regional$ano == combos$ano[k], ]
    x <- alinhar_a_pesos(x, pesos, chave = "cod_regiao")
    cbind(agente = combos$agente[k], ano = combos$ano[k], variavel = variavel, escala = "regiao",
          n = nrow(x), calcular_moran(x[[variavel]], pesos, nsim, semente), stringsAsFactors = FALSE)
  })
  out <- do.call(rbind, out)
  rownames(out) <- NULL
  out
}

#' Mapa coroplético de um agente × ano na escala regional: cor pela taxa, nome
#' e taxa escritos em cada região (são só 9, cabem). Fronteiras municipais em
#' cinza claro por baixo, para situar o leitor.
mapa_regional <- function(regioes_sf, ind_regional, agente, ano, malha = NULL, pontos = NULL) {
  i <- ind_regional[ind_regional$agente == agente & ind_regional$ano == ano, ]
  d <- merge(as.data.frame(regioes_sf), i[, c("cod_regiao", "casos", "incid_100k")], by = "cod_regiao")
  d <- sf::st_as_sf(d, sf_column_name = "geometry", crs = sf::st_crs(regioes_sf))
  if (nrow(d) != nrow(regioes_sf) || anyNA(d$incid_100k)) {
    stop("Junção regiões × indicadores incompleta para ", agente, " ", ano, call. = FALSE)
  }
  num <- function(v) formatC(v, format = "f", digits = 1, decimal.mark = ",", big.mark = ".")
  d$rotulo <- paste0(d$regiao, "\n", num(d$incid_100k))
  g <- ggplot2::ggplot(d) +
    ggplot2::geom_sf(ggplot2::aes(fill = incid_100k), colour = NA)
  if (!is.null(malha)) {
    g <- g + ggplot2::geom_sf(data = malha, fill = NA, colour = "white", linewidth = 0.08, alpha = 0.6)
  }
  # Rótulo no ponto dado (sede populacional, ver pontos_rotulo_regioes) ou,
  # sem ele, na maior parte do polígono.
  if (is.null(pontos)) {
    rot <- sf::st_sf(rotulo = d$rotulo, geometry = ponto_na_maior_parte(sf::st_geometry(d)))
  } else {
    rot <- sf::st_sf(rotulo = d$rotulo, geometry = sf::st_geometry(pontos)[match(d$cod_regiao, pontos$cod_regiao)])
  }
  g + ggplot2::geom_sf(fill = NA, colour = "grey15", linewidth = 0.4) +
    ggplot2::geom_sf_label(data = rot, ggplot2::aes(label = rotulo), size = 2.3, lineheight = 0.9,
                           fill = grDevices::adjustcolor("white", 0.8), linewidth = 0,
                           fun.geometry = identity) +  # já são pontos: sem point_on_surface em graus
    ggplot2::scale_fill_viridis_c(option = "magma", direction = -1, begin = 0.1, end = 0.95,
                                  name = "Taxa bruta\npor 100 mil hab.") +
    ggplot2::labs(
      title = sprintf("SRAG por %s por região de saúde, %d", ROTULOS_AGENTE[[agente]], ano),
      subtitle = "Casos somados / população somada dos municípios de cada região",
      caption = paste0("Regiões de saúde: Ministério da Saúde via geobr (IPEA), conferidas com a SES-RJ.
",
                       "Contorno dissolvido da Malha Municipal 2022 (IBGE). Fontes: SIVEP-Gripe, IBGE.")
    ) +
    tema_mapa()
}

#' Pares de regiões vizinhas IMPLICADOS pela vizinhança municipal: duas regiões
#' são vizinhas se algum município de uma toca algum da outra. Serve de prova
#' cruzada da dissolução: a Queen das regiões dissolvidas tem de dar os mesmos
#' pares. Devolve texto "codA-codB" ordenado, um por par.
pares_regionais_implicados <- function(nb_municipal, regioes) {
  ids <- attr(nb_municipal, "region.id")
  r <- regioes$cod_regiao[match(ids, regioes$cod6)]
  if (anyNA(r)) stop("Município da vizinhança sem região", call. = FALSE)
  pares <- unlist(lapply(seq_along(nb_municipal), function(i) {
    v <- nb_municipal[[i]]
    v <- v[r[v] != r[i]]
    vapply(v, function(j) paste(sort(c(r[i], r[j])), collapse = "-"), character(1))
  }))
  sort(unique(pares))
}

#' Os mesmos pares "codA-codB", lidos de uma vizinhança regional.
pares_de_vizinhanca <- function(nb) {
  ids <- attr(nb, "region.id")
  pares <- unlist(lapply(seq_along(nb), function(i) {
    vapply(nb[[i]], function(j) paste(sort(c(ids[i], ids[j])), collapse = "-"), character(1))
  }))
  sort(unique(pares))
}

#' Ponto de rótulo dentro da MAIOR parte de cada polígono. Regiões com ilhas
#' (Baía da Ilha Grande tem 280 partes) teriam o rótulo jogado numa ilha pelo
#' ponto_interno() aplicado ao multipolígono inteiro.
ponto_na_maior_parte <- function(geometria) {
  crs <- sf::st_crs(geometria)
  g <- sf::st_transform(geometria, 31983)
  pontos <- lapply(seq_along(g), function(i) {
    partes <- sf::st_cast(g[i], "POLYGON")
    sf::st_point_on_surface(partes[which.max(sf::st_area(partes))])[[1]]
  })
  sf::st_transform(sf::st_sfc(pontos, crs = sf::st_crs(g)), crs)
}

#' Um ponto de rótulo por região: dentro do município mais populoso dela.
#' Regra fixa, sem ajuste à mão: separa rótulos que o centro geométrico
#' sobreporia (Metropolitana II fica em São Gonçalo, Baixada Litorânea em Cabo
#' Frio) e tira o da Baía da Ilha Grande de cima das ilhas.
pontos_rotulo_regioes <- function(malha, regioes, populacao) {
  p <- populacao[, c("cod6", "populacao")]
  m <- merge(as.data.frame(malha)[, c("cod6", "geometry")], p, by = "cod6")
  m$cod_regiao <- regioes$cod_regiao[match(m$cod6, regioes$cod6)]
  sede <- do.call(rbind, lapply(split(m, m$cod_regiao), function(x) x[which.max(x$populacao), ]))
  sf::st_sf(cod_regiao = sede$cod_regiao, cod6_sede = sede$cod6,
            geometry = ponto_interno(sf::st_sfc(sede$geometry, crs = sf::st_crs(malha))))
}
