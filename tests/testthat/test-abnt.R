# Testes das tabelas no padrão ABNT (CS-051). Dados FABRICADOS.

test_that("números em português: milhar com ponto, vírgula decimal, casas preservadas, NA vira travessão", {
  expect_equal(formatar_numero_br(c(1234567L, 5L, NA)), c("1.234.567", "5", "–"))
  expect_equal(formatar_numero_br(c(1.5, 1234.25, 0.0001)), c("1,5000", "1.234,2500", "0,0001"))
  expect_equal(formatar_numero_br(c(0.5, 10)), c("0,5", "10,0"))
  expect_equal(formatar_numero_br(c("Niterói", NA)), c("Niterói", "–"))
})

test_that("rótulos de coluna ganham acentos, siglas e unidades", {
  expect_equal(rotulo_coluna(c("codigo_ibge", "taxa_bruta_pop2024_100mil", "casos_sarscov2", "p_permutacao", "pct_encerradas_ate_30_dias")),
               c("Código IBGE", "Taxa bruta pop. 2024 por 100 mil", "Casos SARS-CoV-2", "p (permutação)", "% encerradas até 30 dias"))
})

test_that("tabela em Markdown: cabeçalho, alinhamento por tipo e barra vertical escapada", {
  md <- tabela_markdown(data.frame(municipio = c("A|B", "C"), casos = c(1200L, 3L), taxa = c(1.5, 2.25), stringsAsFactors = FALSE))
  expect_equal(md[1], "| Município | Casos | Taxa |")
  expect_equal(md[2], "|:---|---:|---:|")
  expect_equal(md[3], "| A\\|B | 1.200 | 1,50 |")
  expect_length(md, 4)
})

test_that("série mensal: semanas somadas pelo mês do domingo inicial, uma coluna por agente", {
  s <- data.frame(recorte = "Estado do Rio de Janeiro", agente = rep(c("VSR", "Influenza"), each = 3),
                  inicio_da_semana = rep(c("2025-01-26", "2025-02-02", "2025-02-09"), 2), casos = 1:6)
  m <- resumir_serie_mensal(s)
  expect_equal(m$mes, c("01/2025", "02/2025"))
  expect_equal(m$VSR, c(1L, 5L))
  expect_equal(m$Influenza, c(4L, 11L))
})

test_that("o .docx sai com uma tabela por item, cabeçalho repetido, paisagem e bordas ABNT", {
  q <- caminho_quarto()
  skip_if(!nzchar(q), "Quarto (pandoc) não instalado")
  projeto_temporario()
  tabs <- list(list(dados = data.frame(a = 1:3, b = c("x", "y", "z")), titulo = "Primeira", fonte = "Teste"),
               list(dados = data.frame(c = c(0.5, 1.25)), titulo = "Segunda", fonte = "Teste", nota = "Nota de teste"))
  f <- montar_docx_abnt(tabs, file.path(getwd(), "t.docx"), "Documento de teste", quarto = q, data_referencia = "2026-01-01")
  h1 <- unname(tools::md5sum(f))
  f2 <- montar_docx_abnt(tabs, file.path(getwd(), "t2.docx"), "Documento de teste", quarto = q, data_referencia = "2026-01-01")
  expect_equal(unname(tools::md5sum(f2)), h1)   # reprodutível: mesma entrada, mesmos bytes
  expect_equal(contar_tabelas_docx(f), 2L)
  utils::unzip(f, files = c("word/document.xml", "word/styles.xml"), exdir = "x")
  d <- paste(readLines("x/word/document.xml", encoding = "UTF-8", warn = FALSE), collapse = "")
  s <- paste(readLines("x/word/styles.xml", encoding = "UTF-8", warn = FALSE), collapse = "")
  expect_equal(lengths(regmatches(d, gregexpr("tblHeader", d, fixed = TRUE))), 2L)   # cabeçalho repete na quebra de página
  expect_true(grepl('w:orient="landscape"', d, fixed = TRUE))
  expect_true(grepl("Tabela 1 – Primeira", d, fixed = TRUE) && grepl("Tabela 2 – Segunda", d, fixed = TRUE))
  expect_true(grepl("Nota: Nota de teste", d, fixed = TRUE))
  estilo <- regmatches(s, regexpr('<w:style [^>]*w:styleId="Table".*?</w:style>', s, perl = TRUE))
  expect_true(grepl("<w:tblBorders>", estilo, fixed = TRUE))           # traço no topo e no fim
  expect_false(grepl("insideV|insideH", estilo))                      # nenhuma linha vertical nem interna
  expect_true(grepl('w:type="firstRow"', estilo, fixed = TRUE))        # traço sob o cabeçalho
})
