# Funções de visualização cartográfica (CS-019).

ROTULOS_AGENTE <- c(sarscov2 = "SARS-CoV-2", influenza = "Influenza", vsr = "VSR")

# ---------------------------------------------------------------------------
# Paleta única do projeto (CS-046). ÚNICO lugar com cores: o resto do código só
# referencia estas constantes (um teste procura cor escrita à mão fora daqui).
#
# Regra: uma cor por vírus em TODOS os gráficos, e nenhuma cor de vírus reaparece
# com outro significado. Antes, o vermelho era SARS-CoV-2 nas séries e Alto-Alto no
# LISA, e o azul era influenza nas séries e Baixo-Baixo no LISA.
# Cores dos vírus: posições 4, 5 e 6 da paleta categórica validada da skill dataviz.
# Validação (OKLab ΔE×100, todos os pares, modo claro): pior par entre vírus 16,2 sob
# daltonismo (meta ≥ 8) e 19,6 em visão normal (piso 15). Amarelo e magenta têm
# contraste < 3:1 no branco: por isso linhas mais grossas, legenda sempre presente e
# tabela com os mesmos dados (regra de alívio da skill).
# ---------------------------------------------------------------------------
CORES_AGENTE <- c(sarscov2 = "#eda100", influenza = "#e87ba4", vsr = "#008300")

# Rampa sequencial de cada vírus (mapas de incidência): quase branco -> cor do vírus
# -> tom escuro do mesmo matiz, interpolada no espaço Lab. O matiz diz o vírus; a
# claridade diz a magnitude.
EXTREMOS_RAMPA_AGENTE <- list(
  sarscov2  = c("#fdf6e3", "#eda100", "#5c3a00"),
  influenza = c("#fcf0f5", "#e87ba4", "#7a1c45"),
  vsr       = c("#eef7ee", "#008300", "#003010")
)

# Mapa de referência das 9 regiões de saúde (CS-050): tons pastel (ColorBrewer Set3),
# que não se confundem com as cores fortes dos vírus. Com 9 categorias nenhuma paleta
# separa todos os pares sob daltonismo: a identidade vem também do NOME escrito em cada
# região e da tabela região -> municípios (codificação secundária).
PALETA_REGIOES <- c("33001" = "#8dd3c7", "33002" = "#ffffb3", "33003" = "#bebada", "33004" = "#fdb462",
                    "33005" = "#80b1d3", "33006" = "#fccde5", "33007" = "#b3de69", "33008" = "#fb8072",
                    "33009" = "#bc80bd")

# Cor de marca que não representa vírus nenhum (total de SRAG, histograma, proporção).
COR_NEUTRA <- "#52514e"

# Paleta do LISA em dois níveis (ADR-0004): cor cheia = confirmado após FDR,
# cor clara = indicativo (significativo só sem correção). Vermelho/azul seguem a
# convenção do GeoDa para Alto-Alto/Baixo-Baixo; os discrepantes usam roxo e cinza,
# que não são cores de vírus. Validação das 4 classes confirmadas entre si: pior par
# 9,5 sob daltonismo e 15,5 em visão normal; cada confirmado × seu indicativo ≥ 20;
# cinza indicativo × "não significativo" 16,0.
PALETA_LISA <- c(
  "Alto-Alto (confirmado)"   = "#d7301f", "Alto-Alto (indicativo)"   = "#fc9272",
  "Baixo-Baixo (confirmado)" = "#2166ac", "Baixo-Baixo (indicativo)" = "#92c5de",
  "Alto-Baixo (confirmado)"  = "#542788", "Alto-Baixo (indicativo)"  = "#b2abd2",
  "Baixo-Alto (confirmado)"  = "#4d4d4d", "Baixo-Alto (indicativo)"  = "#bababa",
  "Não significativo"        = "#eeeeee"
)

#' n cores da rampa sequencial de um vírus, da mais clara (perto de zero) à mais escura.
rampa_agente <- function(agente, n = 7) {
  if (!agente %in% names(EXTREMOS_RAMPA_AGENTE)) stop("Agente sem rampa: ", agente, call. = FALSE)
  grDevices::colorRampPalette(EXTREMOS_RAMPA_AGENTE[[agente]], space = "Lab")(n)
}

#' Escala de preenchimento sequencial do vírus: contínua ou por classes (discreta).
escala_incidencia <- function(agente, name, discreta = FALSE, n_classes = 5, ...) {
  if (discreta) {
    ggplot2::scale_fill_manual(values = rampa_agente(agente, n_classes), name = name, drop = FALSE, ...)
  } else {
    ggplot2::scale_fill_gradientn(colours = rampa_agente(agente, 7), name = name, ...)
  }
}

#' Escala de cor por vírus, pelos rótulos legíveis ("SARS-CoV-2", "Influenza", "VSR").
escala_cor_agente <- function(aesthetic = "colour", name = NULL) {
  ggplot2::scale_colour_manual(values = stats::setNames(unname(CORES_AGENTE), ROTULOS_AGENTE[names(CORES_AGENTE)]),
                               name = name, aesthetics = aesthetic)
}
NOMES_QUADRANTE <- c(HH = "Alto-Alto", LL = "Baixo-Baixo", HL = "Alto-Baixo", LH = "Baixo-Alto")

#' Tema comum dos mapas: sem eixos, legenda à direita, título curto.
tema_mapa <- function(base_size = 10) {
  ggplot2::theme_void(base_size = base_size) +
    ggplot2::theme(
      plot.title = ggplot2::element_text(face = "bold", size = base_size + 2),
      plot.subtitle = ggplot2::element_text(colour = "grey30"),
      plot.caption = ggplot2::element_text(colour = "grey40", size = base_size - 2, hjust = 0),
      legend.title = ggplot2::element_text(size = base_size - 1),
      legend.text = ggplot2::element_text(size = base_size - 2),
      plot.background = ggplot2::element_rect(fill = "white", colour = NA),
      plot.margin = ggplot2::margin(8, 8, 8, 8)
    )
}

#' Categoria do LISA para a legenda, a partir de quadrante e nível.
categoria_lisa <- function(quadrante, nivel) {
  cat <- ifelse(nivel == "ns", "Não significativo",
                paste0(NOMES_QUADRANTE[quadrante], " (", nivel, ")"))
  if (any(is.na(cat)) || !all(cat %in% names(PALETA_LISA))) {
    stop("Combinação de quadrante e nível fora da paleta", call. = FALSE)
  }
  factor(cat, levels = names(PALETA_LISA))
}

#' Classes por quantil (quintis por padrão) com rótulos legíveis "a – b".
#' Quebras repetidas (muitos valores iguais) são fundidas.
classes_quantil <- function(x, n = 5, digitos = 1) {
  quebras <- unique(stats::quantile(x, probs = seq(0, 1, length.out = n + 1), names = FALSE))
  if (length(quebras) < 2) quebras <- c(min(x), max(x) + 1e-9)
  fmt <- function(v) formatC(v, format = "f", digits = digitos, decimal.mark = ",", big.mark = ".")
  rotulos <- paste(fmt(utils::head(quebras, -1)), "–", fmt(quebras[-1]))
  cut(x, breaks = quebras, labels = rotulos, include.lowest = TRUE)
}

#' Hachura: linhas diagonais recortadas pelos polígonos, feitas com sf (o
#' ggplot2 não tem hachura). `espacamento` na unidade das coordenadas (graus).
hachurar <- function(poligonos, espacamento = 0.02, angulo = 45) {
  if (nrow(poligonos) == 0) return(sf::st_sf(geometry = sf::st_sfc(crs = sf::st_crs(poligonos))))
  bb <- sf::st_bbox(poligonos)
  largura <- (bb[["xmax"]] - bb[["xmin"]]) + (bb[["ymax"]] - bb[["ymin"]])
  inclinacao <- tan(angulo * pi / 180)
  deslocamentos <- seq(-largura, largura, by = espacamento)
  linhas <- lapply(deslocamentos, function(d) {
    x0 <- bb[["xmin"]] - largura; x1 <- bb[["xmax"]] + largura
    sf::st_linestring(rbind(c(x0, bb[["ymin"]] + d + (x0 - bb[["xmin"]]) * inclinacao),
                            c(x1, bb[["ymin"]] + d + (x1 - bb[["xmin"]]) * inclinacao)))
  })
  grade <- sf::st_sfc(linhas, crs = sf::st_crs(poligonos))
  recorte <- suppressWarnings(sf::st_intersection(grade, sf::st_union(sf::st_geometry(poligonos))))
  recorte <- recorte[!sf::st_is_empty(recorte)]
  sf::st_sf(geometry = recorte)
}

#' Mapa coroplético da incidência de um agente × ano.
#' `dados`: sf com a coluna `variavel`; classes por quintil DO PRÓPRIO MAPA, então
#' as cores não são comparáveis entre anos (para isso, a série com a estimativa
#' 2024, ADR-0003).
mapa_incidencia <- function(dados, agente, ano, variavel = "incid_eb_100k",
                            titulo_variavel = "Taxa suavizada por 100 mil hab.") {
  dados$classe <- classes_quantil(dados[[variavel]])
  ggplot2::ggplot(dados) +
    ggplot2::geom_sf(ggplot2::aes(fill = classe), colour = "white", linewidth = 0.15) +
    escala_incidencia(agente, name = titulo_variavel, discreta = TRUE, n_classes = nlevels(dados$classe)) +
    ggplot2::labs(
      title = sprintf("SRAG por %s, %d", ROTULOS_AGENTE[[agente]], ano),
      subtitle = "Incidência por município de residência (Bayes empírico), classes por quintil",
      caption = "Fontes: SIVEP-Gripe (critério do ADR-0002), IBGE (população e Malha Municipal 2022)."
    ) +
    tema_mapa()
}

#' Mapa LISA de um agente × ano, com dois níveis e hachura nos instáveis.
#' `dados`: sf com quadrante, nivel, instavel e nome. Os confirmados vão por nome no
#' subtítulo; `rotular = TRUE` também os escreve no mapa (desligado por padrão desde o
#' CS-047: Itaboraí e Tanguá se sobrepunham e o texto preto sumia no vermelho).
mapa_lisa <- function(dados, agente, ano, rotular = FALSE) {
  dados$categoria <- categoria_lisa(dados$quadrante, dados$nivel)
  instaveis <- dados[dados$instavel, ]
  confirmados <- dados[dados$nivel == "confirmado", ]
  n_conf <- nrow(confirmados); n_ind <- sum(dados$nivel == "indicativo")
  # Os confirmados vão por nome no subtítulo: rótulos no mapa podem se sobrepor
  # (Tanguá e Itaboraí no VSR 2024), e nenhum confirmado pode sumir.
  lista_conf <- if (n_conf == 0) "nenhum confirmado após correção FDR" else
    paste0("confirmados após FDR: ", paste(sprintf("%s (%s)", confirmados$nome,
                                                   NOMES_QUADRANTE[confirmados$quadrante]),
                                           collapse = ", "))
  lista_conf <- paste0(toupper(substring(lista_conf, 1, 1)), substring(lista_conf, 2), ".")
  subtitulo <- paste(c(strwrap(lista_conf, width = 105),
                       sprintf("%d indicativo(s) sem correção (%s esperados por acaso).", n_ind,
                               formatC(nrow(dados) * ALFA_LISA, format = "f", digits = 1, decimal.mark = ","))),
                     collapse = "\n")

  g <- ggplot2::ggplot(dados) +
    ggplot2::geom_sf(ggplot2::aes(fill = categoria), colour = "white", linewidth = 0.15,
                     show.legend = TRUE) +
    ggplot2::geom_sf(data = hachurar(instaveis), colour = "grey25", linewidth = 0.25) +
    ggplot2::geom_sf(data = instaveis, fill = NA, colour = "grey25", linewidth = 0.3) +
    escala_lisa() +
    ggplot2::labs(
      title = sprintf("Agrupamentos espaciais de SRAG por %s, %d", ROTULOS_AGENTE[[agente]], ano),
      subtitle = subtitulo,
      caption = paste("LISA sobre a taxa suavizada, vizinhança Queen, 9.999 permutações (ADR-0004).",
                      "Hachura: município com um único vizinho, classe instável.")
    ) +
    tema_mapa()
  if (rotular && n_conf > 0) {
    # Sem check_overlap: ele DESCARTA rótulos que colidem (foi assim que Tanguá sumiu).
    g <- g + suppressWarnings(ggplot2::geom_sf_text(
      data = confirmados, ggplot2::aes(label = nome), size = 2.2,
      colour = "black", fontface = "bold", fun.geometry = ponto_interno))
  }
  g
}

#' Ponto garantidamente dentro de cada polígono (para rótulos), calculado em
#' SIRGAS 2000 / UTM 23S (metros) e devolvido no sistema original. Em graus,
#' o sf avisa que o cálculo pode sair errado.
ponto_interno <- function(geometria) {
  sf::st_transform(sf::st_point_on_surface(sf::st_transform(geometria, 31983)), sf::st_crs(geometria))
}

#' Escala do LISA com as 9 categorias na legenda, mesmo as ausentes do mapa.
#' Atenção (ggplot2 4.x): a escala sozinha não basta; a camada de preenchimento
#' precisa de show.legend = TRUE, senão as categorias sem dado saem sem quadrado
#' de cor (erro encontrado no CS-019).
escala_lisa <- function() {
  ggplot2::scale_fill_manual(values = PALETA_LISA, limits = names(PALETA_LISA),
                             drop = FALSE, name = "Moran local (LISA)")
}

# ---------------------------------------------------------------------------
# Painel interativo (CS-021)
# ---------------------------------------------------------------------------

ARQUIVOS_PAINEL <- c(
  malha = file.path("dados", "processados", "municipios_rj.rds"),
  indicadores = file.path("dados", "processados", "indicadores_municipais.parquet"),
  moran_lisa = file.path("resultados", "estatistica", "moran_lisa.rds")
)

#' Carrega o que o painel usa, só de dados/processados e resultados/. Para com
#' mensagem clara se o pipeline não rodou. A malha é simplificada SÓ para o
#' desenho no navegador (tolerância de 100 m em UTM): a análise usou a completa.
carregar_dados_painel <- function(tolerancia_m = 100) {
  faltam <- ARQUIVOS_PAINEL[!file.exists(ARQUIVOS_PAINEL)]
  if (length(faltam) > 0) {
    stop("Rode o pipeline antes do painel (source(\"run.R\")). Faltam: ",
         paste(faltam, collapse = ", "), call. = FALSE)
  }
  malha <- readRDS(ARQUIVOS_PAINEL[["malha"]])
  desenho <- sf::st_transform(
    sf::st_simplify(sf::st_transform(malha, 31983), preserveTopology = TRUE, dTolerance = tolerancia_m),
    4326)  # o leaflet desenha em WGS 84
  list(
    malha = desenho[, c("cod6", "nome")],
    ind = as.data.frame(arrow::read_parquet(ARQUIVOS_PAINEL[["indicadores"]])),
    lisa = readRDS(ARQUIVOS_PAINEL[["moran_lisa"]])$principal$lisa
  )
}

#' Recorte de um agente × ano, já com categoria LISA e popup.
dados_painel <- function(base, agente, ano) {
  d <- dados_mapa(base$malha, base$ind, base$lisa, agente, ano)
  d$categoria <- categoria_lisa(d$quadrante, d$nivel)
  d$classe_incidencia <- classes_quantil(d$incid_eb_100k)
  d$popup <- popup_painel(d)
  d
}

#' Popup com os 6 campos do aceite do CS-021.
popup_painel <- function(d) {
  num <- function(x, dig = 1) formatC(x, format = "f", digits = dig, decimal.mark = ",", big.mark = ".")
  int <- function(x) formatC(x, format = "d", big.mark = ".", decimal.mark = ",")
  instavel <- ifelse(d$instavel, "<br><i>Um único vizinho: classe instável.</i>", "")
  sprintf(paste0("<b>%s</b><br>Casos: %s<br>População: %s<br>Taxa bruta: %s por 100 mil",
                 "<br>Taxa suavizada: %s por 100 mil<br>Moran local: %s%s"),
          htmltools::htmlEscape(d$nome), int(d$casos), int(d$populacao), num(d$incid_100k),
          num(d$incid_eb_100k), as.character(categoria_lisa(d$quadrante, d$nivel)), instavel)
}

#' Mapa leaflet de um recorte, na camada "incidencia" ou "lisa".
mapa_painel <- function(d, camada = c("incidencia", "lisa")) {
  camada <- match.arg(camada)
  if (camada == "incidencia") {
    niveis <- levels(d$classe_incidencia)
    cores <- rampa_agente(unique(d$agente)[1], length(niveis))
    pal <- leaflet::colorFactor(cores, levels = niveis)
    valor <- d$classe_incidencia
    titulo <- "Taxa suavizada<br>por 100 mil hab."
  } else {
    pal <- leaflet::colorFactor(unname(PALETA_LISA), levels = names(PALETA_LISA))
    valor <- d$categoria
    titulo <- "Moran local (LISA)"
  }
  leaflet::leaflet(d) |>
    leaflet::addProviderTiles("CartoDB.Positron") |>
    leaflet::addPolygons(
      fillColor = pal(valor), fillOpacity = 0.85, color = ifelse(d$instavel, "#333333", "white"),
      weight = ifelse(d$instavel, 2.5, 0.6), dashArray = ifelse(d$instavel, "4", NA_character_),
      popup = d$popup, label = d$nome,
      highlightOptions = leaflet::highlightOptions(weight = 2, color = "#000000", bringToFront = TRUE)
    ) |>
    leaflet::addLegend("bottomright", pal = pal, values = valor, title = titulo, opacity = 0.9)
}

#' Junta malha, indicadores e LISA de um agente × ano num sf pronto para os mapas.
dados_mapa <- function(malha, ind, lisa, agente, ano) {
  i <- ind[ind$agente == agente & ind$ano == ano, ]
  l <- lisa[lisa$agente == agente & lisa$ano == ano,
            c("cod6", "quadrante", "nivel", "classe", "instavel", "p_perm", "p_fdr")]
  # merge() num sf só preserva a classe se o sf estiver anexado com library();
  # o projeto usa sf:: sem anexar, então a junção é feita como tabela e a
  # geometria é reposta explicitamente (erro encontrado no CS-019).
  d <- merge(as.data.frame(malha), i, by = "cod6", all.x = TRUE)
  d <- merge(d, l, by = "cod6", all.x = TRUE)
  d <- sf::st_as_sf(d, sf_column_name = "geometry", crs = sf::st_crs(malha))
  if (nrow(d) != nrow(malha) || anyNA(d$incid_eb_100k) || anyNA(d$nivel)) {
    stop("Junção malha × indicadores × LISA incompleta para ", agente, " ", ano, call. = FALSE)
  }
  d
}

#' Guia de cores (CS-046): a cor de cada vírus, a rampa de incidência de cada vírus e
#' as 9 classes do LISA, numa figura só, para abrir a seção de resultados.
grafico_guia_cores <- function(n_rampa = 5) {
  ag <- names(CORES_AGENTE)
  virus <- data.frame(bloco = "Cor de cada vírus (séries, dispersões, painéis)", x = seq_along(ag), y = 1,
                      cor = unname(CORES_AGENTE), rotulo = unname(ROTULOS_AGENTE[ag]), stringsAsFactors = FALSE)
  rampas <- do.call(rbind, lapply(seq_along(ag), function(i) {
    data.frame(bloco = "Mapas de incidência: do mais baixo (claro) ao mais alto (escuro)",
               x = (i - 1) * (n_rampa + 1) + seq_len(n_rampa), y = 1,
               cor = rampa_agente(ag[i], n_rampa), rotulo = ifelse(seq_len(n_rampa) == 3, ROTULOS_AGENTE[[ag[i]]], ""),
               stringsAsFactors = FALSE)
  }))
  lisa <- data.frame(bloco = "Mapas de Moran local (LISA) — as mesmas cores para os três vírus",
                     x = rep(1:5, length.out = length(PALETA_LISA)), y = -((seq_along(PALETA_LISA) - 1) %/% 5),
                     cor = unname(PALETA_LISA), rotulo = names(PALETA_LISA), stringsAsFactors = FALSE)
  d <- rbind(virus, rampas, lisa)
  d$bloco <- factor(d$bloco, levels = unique(d$bloco))
  ggplot2::ggplot(d, ggplot2::aes(x, y)) +
    ggplot2::geom_tile(ggplot2::aes(fill = cor), width = 0.92, height = 0.5, colour = "white") +
    ggplot2::geom_text(ggplot2::aes(y = y - 0.32, label = rotulo), vjust = 1, size = 2.8, colour = "grey15") +
    ggplot2::scale_fill_identity() +
    ggplot2::facet_wrap(~bloco, ncol = 1, scales = "free") +
    ggplot2::scale_y_continuous(expand = ggplot2::expansion(add = c(0.6, 0.35))) +
    ggplot2::labs(title = "Guia de cores do projeto",
                  subtitle = "Cada vírus tem uma cor única; nenhuma cor de vírus é usada no LISA com outro significado.") +
    ggplot2::theme_void(base_size = 10) +
    ggplot2::theme(plot.title = ggplot2::element_text(face = "bold"),
                   plot.subtitle = ggplot2::element_text(colour = "grey30"),
                   strip.text = ggplot2::element_text(face = "bold", hjust = 0, margin = ggplot2::margin(6, 0, 2, 0)),
                   plot.background = ggplot2::element_rect(fill = "white", colour = NA),
                   plot.margin = ggplot2::margin(8, 8, 8, 8))
}
