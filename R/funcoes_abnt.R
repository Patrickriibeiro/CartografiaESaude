# Tabelas no padrão ABNT em Word (CS-051).
#
# A ABNT NBR 14724 (trabalhos acadêmicos) manda apresentar tabelas conforme as Normas de
# Apresentação Tabular do IBGE: título ACIMA ("Tabela N – título"), fonte ABAIXO, só três
# traços horizontais (topo, sob o cabeçalho e fim), nenhuma linha vertical e nenhuma linha
# entre as linhas do corpo. Números em português: vírgula decimal, ponto de milhar.
#
# O .docx é gerado pelo pandoc que vem com o Quarto (o mesmo do relatório), a partir de um
# Markdown com as tabelas e de um documento de referência cujo estilo "Table" tem as bordas
# ABNT. Tentativa descartada: flextable + officer — a gravação do officer cresce mais que
# linearmente com o tamanho (50 s para 1.104 linhas; ~5 min o documento todo).

#' Formata uma coluna numérica em português sem perder casas: inteiros com ponto de
#' milhar; decimais com vírgula e o mesmo número de casas que o valor já tem (até 6).
#' NA vira travessão, como nas tabelas do IBGE.
formatar_numero_br <- function(x) {
  if (!is.numeric(x)) return(ifelse(is.na(x), "–", as.character(x)))
  ok <- !is.na(x)
  if (all(x[ok] == round(x[ok]))) {
    out <- formatC(x, format = "d", big.mark = ".", decimal.mark = ",")
  } else {
    casas <- vapply(x[ok], function(v) {
      s <- sub("0+$", "", formatC(abs(v), format = "f", digits = 6))
      nchar(sub("^[^.]*\\.?", "", s))
    }, integer(1))
    d <- min(6L, max(casas))
    out <- formatC(x, format = "f", digits = d, big.mark = ".", decimal.mark = ",")
  }
  out[!ok] <- "–"
  trimws(out)
}

# Palavras que os nomes de coluna (sem acento, para o Excel e o R) escrevem sem acento.
ACENTOS_ROTULO <- c(
  codigo = "código", municipio = "município", municipios = "municípios", regiao = "região", regioes = "regiões",
  saude = "saúde", populacao = "população", notificacao = "notificação", residencia = "residência",
  epidemiologico = "epidemiológico", epidemiologica = "epidemiológica", inicio = "início", versao = "versão",
  nivel = "nível", unico = "único", variavel = "variável", vizinhanca = "vizinhança", permutacao = "permutação",
  permutacoes = "permutações", padrao = "padrão", nao = "não", proporcao = "proporção", razao = "razão",
  ate = "até", apos = "após", mes = "mês"
)

# Rótulos inteiros que não saem bem da regra geral.
ROTULOS_ESPECIAIS <- c(
  p_permutacao = "p (permutação)", p_corrigido_fdr = "p corrigido (FDR)", I_de_Moran = "I de Moran",
  I_esperado_sem_padrao = "I esperado sem padrão espacial", fichas_de_srag = "Fichas de SRAG",
  taxa_padronizada_idade_100mil = "Taxa padronizada por idade por 100 mil", rho_de_spearman = "rho de Spearman",
  dias_ate_encerrar_mediana = "Dias até encerrar (mediana)", dias_ate_encerrar_p90 = "Dias até encerrar (percentil 90)",
  dias_ate_digitar_mediana = "Dias até digitar (mediana)", proporcao_pct = "Proporção (%)"
)

#' Rótulo legível de coluna: "taxa_bruta_pop2024_100mil" -> "Taxa bruta pop. 2024 por 100 mil";
#' acentos repostos palavra a palavra; alguns rótulos inteiros vêm de ROTULOS_ESPECIAIS.
rotulo_coluna <- function(nome) {
  vapply(nome, function(n) {
    if (n %in% names(ROTULOS_ESPECIAIS)) return(ROTULOS_ESPECIAIS[[n]])
    palavras <- strsplit(n, "_", fixed = TRUE)[[1]]
    palavras <- ifelse(palavras %in% names(ACENTOS_ROTULO), ACENTOS_ROTULO[palavras], palavras)
    r <- paste(palavras, collapse = " ")
    trocas <- c("100mil" = "por 100 mil", "pop2024" = "pop. 2024", "\\bpct\\b" = "%", "ic95" = "IC 95 %",
                "\\bibge\\b" = "IBGE", "\\bsarscov2\\b" = "SARS-CoV-2", "\\bvsr\\b" = "VSR",
                "\\buti\\b" = "UTI", "\\bsus\\b" = "SUS", "\\brj\\b" = "RJ")
    for (k in names(trocas)) r <- gsub(k, trocas[[k]], r)
    paste0(toupper(substring(r, 1, 1)), substring(r, 2))
  }, character(1), USE.NAMES = FALSE)
}

#' Tabela em Markdown (pipe table): números formatados e alinhados à direita, texto à
#' esquerda; "|" dentro de célula é escapado.
tabela_markdown <- function(df) {
  cel <- as.data.frame(lapply(df, formatar_numero_br), stringsAsFactors = FALSE, check.names = FALSE)
  esc <- function(v) gsub("|", "\\|", v, fixed = TRUE)
  numericas <- vapply(df, is.numeric, logical(1))
  cab <- paste0("| ", paste(esc(rotulo_coluna(names(df))), collapse = " | "), " |")
  sep <- paste0("|", paste(ifelse(numericas, "---:", ":---"), collapse = "|"), "|")
  corpo <- do.call(paste, c(lapply(cel, esc), sep = " | "))
  c(cab, sep, paste0("| ", corpo, " |"))
}

#' Caminho do executável do Quarto, ou "" se não houver (máquina sem Quarto, CI).
caminho_quarto <- function() {
  q <- Sys.which("quarto")
  if (!nzchar(q) && file.exists("C:/Program Files/Quarto/bin/quarto.exe")) q <- "C:/Program Files/Quarto/bin/quarto.exe"
  unname(q)
}

#' Documento de referência do pandoc com o estilo de tabela ABNT: parte do padrão do
#' próprio pandoc e troca (1) o estilo "Table" — traço no topo e no fim da tabela,
#' traço sob o cabeçalho, cabeçalho em negrito, Arial 9; (2) a fonte padrão — Arial 10;
#' (3) a página — A4 em paisagem, margens de 3 cm (superior e esquerda) e 2 cm (NBR 14724).
#' `texto = TRUE` (CS-057, documento corrido como a proposta): A4 em retrato, Arial 12,
#' parágrafo justificado com entrelinha 1,5, títulos em preto e negrito, idioma pt-BR
#' (o corretor do Word passa a conferir português).
criar_referencia_abnt <- function(quarto, destino, data_referencia = "2000-01-01", texto = FALSE) {
  base <- tempfile(fileext = ".docx")
  saida <- suppressWarnings(system2(quarto, c("pandoc", "-o", shQuote(base), "--print-default-data-file", "reference.docx"),
                                    stdout = TRUE, stderr = TRUE))
  if (!file.exists(base)) stop("pandoc não gerou o documento de referência: ", paste(saida, collapse = " "), call. = FALSE)
  pasta <- tempfile(); utils::unzip(base, exdir = pasta)

  arq_estilos <- file.path(pasta, "word", "styles.xml")
  s <- paste(readLines(arq_estilos, encoding = "UTF-8", warn = FALSE), collapse = "\n")
  traco <- '<w:%s w:val="single" w:sz="8" w:space="0" w:color="000000"/>'
  estilo_tabela <- paste0(
    '<w:style w:type="table" w:default="1" w:styleId="Table"><w:name w:val="Table"/><w:basedOn w:val="TableNormal"/>',
    '<w:qFormat/><w:rPr><w:rFonts w:ascii="Arial" w:hAnsi="Arial" w:cs="Arial"/><w:sz w:val="18"/><w:szCs w:val="18"/></w:rPr>',
    '<w:tblPr><w:tblInd w:w="0" w:type="dxa"/><w:tblBorders>', sprintf(traco, "top"), sprintf(traco, "bottom"),
    '</w:tblBorders><w:tblCellMar><w:top w:w="0" w:type="dxa"/><w:left w:w="80" w:type="dxa"/>',
    '<w:bottom w:w="0" w:type="dxa"/><w:right w:w="80" w:type="dxa"/></w:tblCellMar></w:tblPr>',
    '<w:tblStylePr w:type="firstRow"><w:rPr><w:b/></w:rPr><w:tcPr><w:tcBorders>', sprintf(traco, "top"), sprintf(traco, "bottom"),
    '</w:tcBorders><w:vAlign w:val="bottom"/></w:tcPr></w:tblStylePr></w:style>')
  antes <- nchar(s)
  # (?s): o estilo ocupa várias linhas, e sem ele o "." não casa quebra de linha.
  s <- sub('(?s)<w:style w:type="table" w:default="1" w:styleId="Table">.*?</w:style>', estilo_tabela, s, perl = TRUE)
  s <- sub('<w:rFonts w:asciiTheme="minorHAnsi"[^>]*/>', '<w:rFonts w:ascii="Arial" w:hAnsi="Arial" w:eastAsia="Arial" w:cs="Arial"/>', s, perl = TRUE)
  corpo <- if (texto) "24" else "20"   # meios-pontos: 12 pt no texto, 10 pt no documento de tabelas
  s <- sub('(?s)(<w:rPrDefault>.*?)<w:sz w:val="24" />\\s*<w:szCs w:val="24" />',
           sprintf('\\1<w:sz w:val="%s"/><w:szCs w:val="%s"/>', corpo, corpo), s, perl = TRUE)
  if (!grepl('w:styleId="Table"><w:name w:val="Table"/>', s, fixed = TRUE) || !grepl('w:ascii="Arial"', s, fixed = TRUE)) {
    stop("O documento de referência do pandoc mudou de formato; o estilo ABNT não foi aplicado", call. = FALSE)
  }
  if (texto) s <- estilos_texto_abnt(s)
  writeLines(s, arq_estilos, useBytes = TRUE)

  arq_doc <- file.path(pasta, "word", "document.xml")
  d <- paste(readLines(arq_doc, encoding = "UTF-8", warn = FALSE), collapse = "\n")
  tamanho <- if (texto) '<w:pgSz w:w="11906" w:h="16838"/>' else '<w:pgSz w:w="16838" w:h="11906" w:orient="landscape"/>'
  pagina <- paste0(tamanho,
                   '<w:pgMar w:top="1701" w:right="1134" w:bottom="1134" w:left="1701" w:header="709" w:footer="709" w:gutter="0"/>')
  d <- sub("</w:sectPr>", paste0(pagina, "</w:sectPr>"), d, fixed = TRUE)
  writeLines(d, arq_doc, useBytes = TRUE)

  arquivos <- list.files(pasta, recursive = TRUE, all.files = TRUE)
  # Data fixa nos arquivos: o pandoc copia algumas partes da referência para o .docx final
  # com a data de modificação delas, e sem isto o resultado mudaria a cada execução.
  Sys.setFileTime(file.path(pasta, arquivos), as.POSIXct(paste(data_referencia, "12:00:00"), tz = "UTC"))
  if (file.exists(destino)) file.remove(destino)
  zip::zip(normalizePath(destino, winslash = "/", mustWork = FALSE), files = arquivos, root = pasta, mode = "mirror")
  invisible(destino)
}

#' Estilos de texto corrido (CS-057) sobre o styles.xml do pandoc: corpo justificado com
#' entrelinha 1,5 (line="360" = 1,5 × 240) e 6 pt depois; títulos em Arial preto negrito
#' (o padrão do pandoc é azul, fonte de tema e 20 pt); idioma pt-BR. Para se algum alvo
#' não for encontrado: um estilo que não casou deixaria o Word sem formatação, em silêncio.
estilos_texto_abnt <- function(s) {
  n0 <- nchar(s)
  corpo <- '(?s)(<w:style w:type="paragraph" w:styleId="BodyText">.*?)<w:spacing w:before="180" w:after="180" />'
  if (!grepl(corpo, s, perl = TRUE)) stop("Estilo BodyText do pandoc mudou de formato", call. = FALSE)
  s <- sub(corpo, '\\1<w:spacing w:before="0" w:after="120" w:line="360" w:lineRule="auto"/><w:jc w:val="both"/>', s, perl = TRUE)
  tamanhos <- c("1" = "28", "2" = "24", "3" = "24")   # meios-pontos: 14, 12 e 12 pt
  for (n in names(tamanhos)) {
    padrao <- sprintf('(?s)<w:style w:type="paragraph" w:styleId="Heading%s">.*?</w:style>', n)
    bloco <- regmatches(s, regexpr(padrao, s, perl = TRUE))
    if (length(bloco) != 1) stop("Estilo Heading", n, " do pandoc não encontrado", call. = FALSE)
    novo <- gsub('<w:color [^>]*/>', '<w:color w:val="000000"/>', bloco, perl = TRUE)
    novo <- gsub('<w:rFonts [^>]*/>', '<w:rFonts w:ascii="Arial" w:hAnsi="Arial" w:cs="Arial"/><w:b/>', novo, perl = TRUE)
    novo <- gsub('<w:sz w:val="\\d+" */>\\s*<w:szCs w:val="\\d+" */>',
                 sprintf('<w:sz w:val="%s"/><w:szCs w:val="%s"/>', tamanhos[[n]], tamanhos[[n]]), novo, perl = TRUE)
    s <- sub(bloco, novo, s, fixed = TRUE)
  }
  s <- sub('w:lang w:val="en-US"', 'w:lang w:val="pt-BR"', s, fixed = TRUE)
  if (!grepl('w:line="360"', s, fixed = TRUE) || !grepl('w:lang w:val="pt-BR"', s, fixed = TRUE) || nchar(s) == n0) {
    stop("Estilos de texto ABNT não aplicados", call. = FALSE)
  }
  s
}

#' Documento Word de texto corrido a partir de um Markdown (CS-057: a proposta v2 para a
#' analista editar). Fórmulas $...$ viram equações do Word, editáveis; tabelas saem com o
#' estilo ABNT. Sem Quarto, avisa e devolve NULL. Reprodutível como montar_docx_abnt().
montar_docx_texto <- function(arquivo_md, caminho, quarto = caminho_quarto(),
                              data_referencia = data_versao_mais_recente()) {
  if (!nzchar(quarto)) {
    message("Quarto (pandoc) não encontrado: ", basename(caminho), " não gerado")
    return(invisible(NULL))
  }
  referencia <- criar_referencia_abnt(quarto, tempfile(fileext = ".docx"), data_referencia, texto = TRUE)
  epoch <- format(as.numeric(as.POSIXct(paste(data_referencia, "12:00:00"), tz = "UTC")), scientific = FALSE)
  if (file.exists(caminho)) file.remove(caminho)   # sem isto, um pandoc que falha deixaria o arquivo velho passar
  # markdown do pandoc sem subscrito/sobrescrito: "~190 colunas" é aproximação, não subscrito.
  saida <- withr::with_envvar(c(SOURCE_DATE_EPOCH = epoch), suppressWarnings(
    system2(quarto, c("pandoc", shQuote(arquivo_md), "-f", "markdown-subscript-superscript", "-t", "docx",
                      "--reference-doc", shQuote(referencia), "-o", shQuote(caminho)), stdout = TRUE, stderr = TRUE)))
  if (!file.exists(caminho)) stop("pandoc não gerou ", caminho, ": ", paste(saida, collapse = " "), call. = FALSE)
  invisible(caminho)
}

#' Documento Word com todas as tabelas: uma por página, "Tabela N – título" acima e
#' "Fonte: ..." (e "Nota: ...") abaixo. `tabelas`: lista de list(dados, titulo, fonte, nota).
#' Sem Quarto na máquina, avisa e devolve NULL (como o relatório, é etapa opcional).
#' `data_referencia`: data gravada dentro do .docx (via SOURCE_DATE_EPOCH, convenção de
#' builds reprodutíveis que o pandoc respeita). Sem ela, o arquivo muda a cada execução
#' só por causa do carimbo de hora; o padrão é a versão mais recente do banco do SIVEP.
montar_docx_abnt <- function(tabelas, caminho, titulo_documento, quarto = caminho_quarto(),
                             data_referencia = data_versao_mais_recente()) {
  if (!nzchar(quarto)) {
    message("Quarto (pandoc) não encontrado: tabelas_abnt.docx não gerado")
    return(invisible(NULL))
  }
  quebra <- c("", "```{=openxml}", '<w:p><w:r><w:br w:type="page"/></w:r></w:p>', "```", "")
  md <- c(paste0("**", titulo_documento, "**"), "",
          sprintf("%d tabelas, formatadas conforme a ABNT NBR 14724 e as Normas de Apresentação Tabular do IBGE.", length(tabelas)))
  for (i in seq_along(tabelas)) {
    t <- tabelas[[i]]
    md <- c(md, quebra, sprintf("**Tabela %d – %s**", i, t$titulo), "", tabela_markdown(t$dados), "",
            paste0("Fonte: ", t$fonte), if (!is.null(t$nota)) c("", paste0("Nota: ", t$nota)))
  }
  arq_md <- tempfile(fileext = ".md")
  writeLines(enc2utf8(md), arq_md, useBytes = TRUE)
  referencia <- criar_referencia_abnt(quarto, tempfile(fileext = ".docx"), data_referencia)
  epoch <- format(as.numeric(as.POSIXct(paste(data_referencia, "12:00:00"), tz = "UTC")), scientific = FALSE)
  saida <- withr::with_envvar(c(SOURCE_DATE_EPOCH = epoch), suppressWarnings(
    system2(quarto, c("pandoc", shQuote(arq_md), "-f", "markdown", "-t", "docx",
                      "--reference-doc", shQuote(referencia), "-o", shQuote(caminho)), stdout = TRUE, stderr = TRUE)))
  if (!file.exists(caminho)) stop("pandoc não gerou ", caminho, ": ", paste(saida, collapse = " "), call. = FALSE)
  invisible(caminho)
}

#' Data da versão mais recente dos bancos do SIVEP em config/fontes.yml ("DD-MM-AAAA").
data_versao_mais_recente <- function(fontes = ler_fontes()) {
  v <- vapply(fontes$sivep$bancos, function(b) b$versao, character(1))
  format(max(as.Date(v, format = "%d-%m-%Y")))
}

#' Conta as tabelas de um Markdown: linhas separadoras de cabeçalho ("|---|:---:|") fora de
#' bloco de código.
contar_tabelas_markdown <- function(arquivo_md) {
  l <- readLines(arquivo_md, encoding = "UTF-8", warn = FALSE)
  em_codigo <- cumsum(grepl("^```", l)) %% 2 == 1
  sum(grepl("^\\|( *:?-+:? *\\|)+ *$", l) & !em_codigo)
}

#' Conta as tabelas de um .docx: elementos <w:tbl> no document.xml.
contar_tabelas_docx <- function(caminho) {
  pasta <- tempfile(); utils::unzip(caminho, files = "word/document.xml", exdir = pasta)
  d <- paste(readLines(file.path(pasta, "word", "document.xml"), encoding = "UTF-8", warn = FALSE), collapse = "")
  lengths(regmatches(d, gregexpr("<w:tbl>", d, fixed = TRUE)))
}

#' Série semanal resumida por mês (a íntegra, com 6.270 linhas, fica só no CSV): casos
#' por recorte e mês do domingo que abre a semana, uma coluna por agente.
resumir_serie_mensal <- function(serie) {
  s <- serie
  s$mes <- format(as.Date(s$inicio_da_semana), "%Y-%m")
  a <- stats::aggregate(casos ~ recorte + mes + agente, data = s, FUN = sum)
  w <- stats::reshape(a, idvar = c("recorte", "mes"), timevar = "agente", direction = "wide")
  names(w) <- sub("^casos\\.", "", names(w))
  ordem_recorte <- unique(serie$recorte)
  w <- w[order(match(w$recorte, ordem_recorte), w$mes), ]
  w$mes <- format(as.Date(paste0(w$mes, "-01")), "%m/%Y")
  w <- w[, c("recorte", "mes", intersect(ROTULOS_AGENTE, names(w)))]
  rownames(w) <- NULL
  w
}
