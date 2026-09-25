# Leitos SUS do CNES por município (CS-034, OE10 opcional).

# Grafias antigas usadas pelo CNES para municípios do RJ -> nome da malha do IBGE.
# Conferido em 2026-09-25: com estes dois, os 92 casam em 2022-2025, e em 2025 a
# junção por nome concorda com a coluna CO_IBGE em todas as linhas.
ALIAS_MUNICIPIOS_CNES <- c("PARATI" = "PARATY", "TRAJANO DE MORAIS" = "TRAJANO DE MORAES")

COLUNAS_LEITOS <- c("COMP", "UF", "MUNICIPIO", "CNES", "LEITOS_SUS", "UTI_TOTAL_SUS")

#' Baixa os arquivos anuais de leitos listados em config/fontes.yml e registra
#' no manifesto (dados/brutos, fora do git: são do Brasil inteiro).
obter_leitos <- function(fontes = ler_fontes()) {
  for (f in fontes$leitos_cnes$arquivos) {
    baixar_e_registrar(f$url, f$destino, descricao = sprintf("CNES, Hospitais e Leitos, %d (todas as UF, 12 competências)", f$ano),
                       versao = basename(f$url))
  }
  invisible(TRUE)
}

#' Nome de coluna normalizado: maiúsculas, tudo que não é letra/dígito vira "_".
#' "UTI TOTAL - SUS" (2022) e "UTI_TOTAL_SUS" (2023+) viram o mesmo nome.
normalizar_coluna <- function(x) gsub("^_|_$", "", gsub("_+", "_", gsub("[^A-Z0-9]", "_", toupper(x))))

#' Nome de município comparável: sem acento, maiúsculas, espaços simples.
normalizar_nome_municipio <- function(x) {
  gsub(" +", " ", trimws(toupper(gsub("[^A-Za-z ]", " ", iconv(x, "UTF-8", "ASCII//TRANSLIT")))))
}

#' Nome do CNES -> cod6 da malha, com os apelidos acima. Para se algum nome não
#' casar: um município "perdido" ficaria com zero leito sem aviso.
cod6_por_nome_cnes <- function(nomes, malha) {
  n <- normalizar_nome_municipio(nomes)
  n <- ifelse(n %in% names(ALIAS_MUNICIPIOS_CNES), ALIAS_MUNICIPIOS_CNES[n], n)
  cod <- malha$cod6[match(n, normalizar_nome_municipio(malha$nome))]
  if (anyNA(cod)) stop("Município do CNES sem correspondência na malha: ", exemplos(unique(nomes[is.na(cod)])), call. = FALSE)
  unname(cod)
}

#' Lê um arquivo anual e devolve os leitos de julho por município do RJ:
#' cod6, ano, estabelecimentos, leitos_sus, uti_sus — os 92 municípios, com zero
#' onde não há estabelecimento.
ler_leitos_ano <- function(item, malha, mes = "07") {
  verificar_manifesto(item$destino)
  # Dentro do zip a leitura é por conexão. read.csv IGNORA fileEncoding quando
  # recebe conexão, e unz(encoding =) não converteu os acentos no teste (NITERÓI
  # chegava com o byte 0xD3 do latin-1 sem conversão). Por isso: lê as linhas cruas e converte com iconv(),
  # explícito, parando se algum byte não for válido na codificação declarada.
  x <- if (is.null(item$arquivo_no_zip)) {
    utils::read.csv(item$destino, fileEncoding = item$codificacao, sep = item$separador,
                    colClasses = "character", check.names = FALSE, na.strings = "")
  } else {
    con <- unz(item$destino, item$arquivo_no_zip)
    linhas <- readLines(con, warn = FALSE)
    close(con)
    convertidas <- iconv(linhas, from = item$codificacao, to = "UTF-8")
    if (anyNA(convertidas)) {
      stop(sum(is.na(convertidas)), " linha(s) de ", item$arquivo_no_zip, " inválidas em ", item$codificacao,
           call. = FALSE)
    }
    utils::read.csv(text = convertidas, sep = item$separador, colClasses = "character",
                    check.names = FALSE, na.strings = "")
  }
  names(x) <- normalizar_coluna(names(x))
  validar_variaveis(names(x), COLUNAS_LEITOS, basename(item$destino))   # CS-009
  comp <- paste0(item$ano, mes)
  if (!comp %in% x$COMP) stop("Competência ", comp, " ausente em ", basename(item$destino), call. = FALSE)
  rj <- x[x$UF == "RJ" & x$COMP == comp, ]
  if (nrow(rj) == 0) stop("Nenhum estabelecimento do RJ em ", comp, call. = FALSE)
  if (anyDuplicated(rj$CNES)) stop("Estabelecimento repetido na competência ", comp, call. = FALSE)
  rj$cod6 <- cod6_por_nome_cnes(rj$MUNICIPIO, malha)
  if ("CO_IBGE" %in% names(rj)) {
    div <- sum(substr(rj$CO_IBGE, 1, 6) != rj$cod6)
    if (div > 0) stop(div, " estabelecimentos com nome e CO_IBGE discordantes", call. = FALSE)
  }
  leitos <- suppressWarnings(as.numeric(rj$LEITOS_SUS)); uti <- suppressWarnings(as.numeric(rj$UTI_TOTAL_SUS))
  if (anyNA(leitos) || anyNA(uti)) stop("Contagem de leitos não numérica em ", comp, call. = FALSE)
  por <- data.frame(cod6 = sort(malha$cod6), ano = as.integer(item$ano), stringsAsFactors = FALSE)
  por$estabelecimentos <- as.integer(table(factor(rj$cod6, levels = por$cod6)))
  por$leitos_sus <- as.numeric(tapply(leitos, factor(rj$cod6, levels = por$cod6), sum, default = 0))
  por$uti_sus <- as.numeric(tapply(uti, factor(rj$cod6, levels = por$cod6), sum, default = 0))
  por
}

#' Os anos do estudo empilhados, com leitos por 100 mil habitantes pela
#' população do ano (a mesma das taxas de incidência, ADR-0003).
montar_leitos <- function(malha, populacao, fontes = ler_fontes(), anos = ANOS_ESTUDO) {
  itens <- Filter(function(f) f$ano %in% anos, fontes$leitos_cnes$arquivos)
  if (length(itens) != length(anos)) stop("Falta arquivo de leitos para algum ano do estudo", call. = FALSE)
  mes <- fontes$leitos_cnes$competencia_mes
  l <- do.call(rbind, lapply(itens, ler_leitos_ano, malha = malha, mes = mes))
  l <- merge(l, populacao[, c("cod6", "ano", "populacao")], by = c("cod6", "ano"), all.x = TRUE, sort = FALSE)
  if (anyNA(l$populacao)) stop("Linha de leitos sem população", call. = FALSE)
  l$leitos_sus_100k <- l$leitos_sus / l$populacao * 1e5
  l$uti_sus_100k <- l$uti_sus / l$populacao * 1e5
  l <- l[order(l$ano, l$cod6), ]
  rownames(l) <- NULL
  l
}

#' Correlação de Spearman, por ano, entre a taxa de SRAG por residência (os três
#' agentes somados, população do ano) e os leitos por 100 mil, nos municípios.
#' IC de 95 % por bootstrap percentil: reamostra municípios com reposição
#' `nboot` vezes, com semente fixa. Descritivo: correlação não é efeito.
correlacionar_leitos <- function(ind, leitos, nboot = N_PERMUTACOES, semente = SEMENTE,
                                 medidas = c(leitos_sus_100k = "Leitos SUS", uti_sus_100k = "Leitos de UTI SUS")) {
  total <- stats::aggregate(cbind(casos) ~ cod6 + ano, data = ind, FUN = sum)
  pop <- unique(ind[, c("cod6", "ano", "populacao")])
  total <- merge(total, pop, by = c("cod6", "ano"))
  total$taxa_srag_100k <- total$casos / total$populacao * 1e5
  d <- merge(total[, c("cod6", "ano", "taxa_srag_100k")], leitos, by = c("cod6", "ano"))
  out <- list()
  for (a in sort(unique(d$ano))) for (m in names(medidas)) {
    x <- d[d$ano == a, ]
    rho <- stats::cor(x$taxa_srag_100k, x[[m]], method = "spearman")
    set.seed(semente)
    boot <- replicate(nboot, {
      i <- sample.int(nrow(x), replace = TRUE)
      suppressWarnings(stats::cor(x$taxa_srag_100k[i], x[[m]][i], method = "spearman"))
    })
    ic <- stats::quantile(boot, c(0.025, 0.975), na.rm = TRUE, names = FALSE)
    out[[length(out) + 1]] <- data.frame(ano = as.integer(a), medida = m, rotulo = unname(medidas[m]),
                                         municipios = nrow(x), rho = rho, ic_inf = ic[1], ic_sup = ic[2],
                                         reamostras = nboot, stringsAsFactors = FALSE)
  }
  out <- do.call(rbind, out)
  rownames(out) <- NULL
  out
}

#' Leitos e taxa por região de saúde, por ano: descritivo (com 9 regiões não se
#' estima correlação com IC útil).
resumir_leitos_regiao <- function(leitos, regioes, ind_regional) {
  l <- leitos
  l$cod_regiao <- regioes$cod_regiao[match(l$cod6, regioes$cod6)]
  if (anyNA(l$cod_regiao)) stop("Município dos leitos sem região", call. = FALSE)
  r <- stats::aggregate(cbind(leitos_sus, uti_sus, populacao) ~ cod_regiao + ano, data = l, FUN = sum)
  r$leitos_sus_100k <- r$leitos_sus / r$populacao * 1e5
  r$uti_sus_100k <- r$uti_sus / r$populacao * 1e5
  t <- stats::aggregate(casos ~ cod_regiao + ano, data = ind_regional, FUN = sum)
  r <- merge(r, t, by = c("cod_regiao", "ano"))
  r$taxa_srag_100k <- r$casos / r$populacao * 1e5
  r$regiao <- unname(REGIOES_SAUDE_RJ[r$cod_regiao])
  r <- r[order(r$ano, r$cod_regiao), c("cod_regiao", "regiao", "ano", "populacao", "leitos_sus", "uti_sus",
                                       "leitos_sus_100k", "uti_sus_100k", "casos", "taxa_srag_100k")]
  rownames(r) <- NULL
  r
}

#' Dispersão taxa de SRAG × leitos por 100 mil (eixo x em raiz quadrada: muitos
#' municípios têm zero ou poucos leitos), uma coluna por ano, uma linha por tipo
#' de leito; rho e IC escritos em cada painel.
grafico_leitos <- function(ind, leitos, sp) {
  total <- stats::aggregate(casos ~ cod6 + ano, data = ind, FUN = sum)
  d <- merge(total, leitos, by = c("cod6", "ano"))
  d$taxa_srag_100k <- d$casos / d$populacao * 1e5
  longo <- rbind(
    data.frame(ano = d$ano, taxa = d$taxa_srag_100k, leitos = d$leitos_sus_100k, rotulo = "Leitos SUS"),
    data.frame(ano = d$ano, taxa = d$taxa_srag_100k, leitos = d$uti_sus_100k, rotulo = "Leitos de UTI SUS"))
  # Total de leitos em cima, UTI embaixo: a mesma ordem da tabela do relatório.
  niveis <- c("Leitos SUS", "Leitos de UTI SUS")
  longo$rotulo <- factor(longo$rotulo, levels = niveis); sp$rotulo <- factor(sp$rotulo, levels = niveis)
  num <- function(v) formatC(v, format = "f", digits = 2, decimal.mark = ",")
  sp$texto <- sprintf("rho = %s\nIC 95%%: %s a %s", num(sp$rho), num(sp$ic_inf), num(sp$ic_sup))
  ggplot2::ggplot(longo, ggplot2::aes(leitos, taxa)) +
    ggplot2::geom_point(alpha = 0.55, colour = "#3b6e8f", size = 1.3) +
    ggplot2::geom_text(data = sp, ggplot2::aes(x = Inf, y = Inf, label = texto), hjust = 1.05, vjust = 1.2,
                       size = 2.7, colour = "grey20", inherit.aes = FALSE) +
    ggplot2::scale_x_sqrt() +
    ggplot2::facet_grid(rotulo ~ ano, scales = "free_x") +
    ggplot2::labs(title = "Taxa de SRAG por residência × leitos SUS por 100 mil habitantes, por município",
                  subtitle = "Correlação de Spearman com IC por bootstrap. Descritivo: não indica efeito dos leitos sobre a doença.",
                  x = "Leitos por 100 mil hab. (competência de julho; escala raiz quadrada)",
                  y = "SRAG por 100 mil hab. (três agentes)",
                  caption = "Fontes: CNES (Hospitais e Leitos), SIVEP-Gripe (critério do ADR-0002), IBGE.") +
    ggplot2::theme_minimal(base_size = 9) +
    ggplot2::theme(plot.title = ggplot2::element_text(face = "bold"), strip.text = ggplot2::element_text(face = "bold"))
}
