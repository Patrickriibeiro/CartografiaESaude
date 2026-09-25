# Testes da padronização por idade (CS-033). Dados FABRICADOS, contas à mão.

# Resposta SIDRA 9514 falsa: 2 municípios, todas as 23 categorias (1ª linha = rótulos).
sidra_9514_falso <- function(destino, valores_por_mun) {
  cats <- c(names(CATEGORIAS_IDADE_9514), CATEGORIA_TOTAL_9514)
  linhas <- list(data.frame(D1C = "Município (Código)", D1N = "Município", D6C = "Idade (Código)", D6N = "Idade", V = "Valor"))
  for (m in names(valores_por_mun)) {
    v <- valores_por_mun[[m]]
    linhas[[length(linhas) + 1]] <- data.frame(D1C = m, D1N = paste("Mun", m), D6C = cats, D6N = cats, V = as.character(v[cats]))
  }
  dir.create(dirname(destino), recursive = TRUE, showWarnings = FALSE)
  jsonlite::write_json(do.call(rbind, linhas), destino)
  registrar_fonte(destino, url = "https://exemplo/9514", descricao = "FABRICADO")
  destino
}

# Município com 100 pessoas em cada uma das 22 categorias detalhadas, menos <1 = 30
# (então 0-4 = 100 inclui os 30 de <1; 1-4 = 70). Total = soma das 21 quinquenais = 2100.
valores_base <- function() {
  v <- stats::setNames(rep("100", length(CATEGORIAS_IDADE_9514)), names(CATEGORIAS_IDADE_9514))
  v["6557"] <- "30"
  v[CATEGORIA_TOTAL_9514] <- "2100"
  v
}

test_that("ler_populacao_idade monta as 11 faixas, trata '-' como zero e confere o total", {
  projeto_temporario()
  v2 <- valores_base(); v2["6653"] <- "-"; v2[CATEGORIA_TOTAL_9514] <- "2000"   # 100 anos ou mais = zero
  f <- sidra_9514_falso("dados/externos/x.json", list("3300100" = valores_base(), "3300209" = v2))
  p <- ler_populacao_idade(f, n_municipios = 2)
  expect_equal(nrow(p), 22)
  a <- p[p$cod6 == "330010", ]
  expect_equal(a$faixa, FAIXAS_ETARIAS$faixa)
  expect_equal(a$populacao, c(30, 70, 100, 200, 200, 200, 200, 200, 200, 200, 500))
  expect_equal(sum(a$populacao), 2100)
  expect_equal(p$populacao[p$cod6 == "330020" & p$faixa == "80+"], 400)
})

test_that("ler_populacao_idade para em sigilo ('X'), total que não fecha e categoria faltante", {
  projeto_temporario()
  vx <- valores_base(); vx["93084"] <- "X"
  f <- sidra_9514_falso("dados/externos/x.json", list("3300100" = vx))
  expect_error(ler_populacao_idade(f, n_municipios = 1), "não numérico")
  vt <- valores_base(); vt[CATEGORIA_TOTAL_9514] <- "2101"
  f <- sidra_9514_falso("dados/externos/y.json", list("3300100" = vt))
  expect_error(ler_populacao_idade(f, n_municipios = 1), "difere do total")
  # Arquivo criado ANTES da chamada (avaliação preguiçosa: como argumento, seria
  # registrado no manifesto só depois de verificar_manifesto() já tê-lo lido).
  f <- sidra_9514_falso("dados/externos/z.json", list("3300100" = valores_base()))
  expect_error(ler_populacao_idade(f, n_municipios = 92), "1 municípios; esperado 92")
})

test_that("idade em anos: dias e meses viram 0, anos ficam; NA e >120 param", {
  expect_equal(idade_em_anos(c(15L, 11L, 3L, 115L, 400L), c(1L, 2L, 3L, 3L, 1L)), c(0L, 0L, 3L, 115L, 1L))
  expect_error(idade_em_anos(c(1L, NA), c(3L, 3L)), "1 caso\\(s\\) sem idade")
  expect_error(idade_em_anos(c(130L), c(3L)), "acima de 120")
  expect_error(idade_em_anos(c(5L), c(4L)), "TP_IDADE fora")
})

test_that("faixa etária respeita os limites: 0 é <1, 1 e 4 são 1-4, 5 é 5-9, 79 é 70-79, 80 é 80+", {
  f <- faixa_etaria(c(0L, 1L, 4L, 5L, 9L, 10L, 79L, 80L, 115L))
  expect_equal(as.character(f), c("<1", "1-4", "1-4", "5-9", "5-9", "10-19", "70-79", "80+", "80+"))
  expect_equal(levels(f), FAIXAS_ETARIAS$faixa)
})

test_that("método direto: mesmas taxas por idade dão a mesma taxa padronizada, com taxas brutas diferentes", {
  # Município A é "jovem" (90 bebês, 10 idosos); B é "velho" (10 bebês, 90 idosos).
  # Taxa específica igual nos dois: 10 % em <1, 1 % em 80+. Padrão: metade e metade.
  pop_idade <- data.frame(cod6 = rep(c("330010", "330020"), each = 2), faixa = rep(c("<1", "80+"), 2),
                          populacao = c(90, 10, 10, 90))
  populacao <- data.frame(cod6 = c("330010", "330020"), ano = 2024L, populacao = c(100, 100))
  pop_faixas <- montar_populacao_faixas(pop_idade, populacao)
  expect_equal(as.numeric(tapply(pop_faixas$populacao_faixa, pop_faixas$cod6, sum)), c(100, 100))   # tapply devolve array
  casos_faixa <- data.frame(cod6 = rep(c("330010", "330020"), each = 2), agente = "vsr", ano = 2024L,
                            faixa = rep(c("<1", "80+"), 2), casos = c(9L, 0L, 1L, 1L))   # 9/90, 0/10 | 1/10, 1/90
  padrao <- data.frame(faixa = c("<1", "80+"), populacao = c(100, 100), peso = c(0.5, 0.5))
  pad <- padronizar_direto(casos_faixa, pop_faixas, padrao)
  # A: 0,5 × 0,10 + 0,5 × 0 = 0,05; B: 0,5 × 0,10 + 0,5 × (1/90)
  expect_equal(pad$incid_pad_100k[pad$cod6 == "330010"], 0.05 * 1e5)
  expect_equal(pad$incid_pad_100k[pad$cod6 == "330020"], (0.05 + 0.5 / 90) * 1e5)
  expect_equal(pad$incid_faixas_100k, c(9 / 100, 2 / 100) * 1e5)   # brutas: 9 % e 2 %
  # Caso em faixa sem população é erro, não taxa infinita.
  pf0 <- pop_faixas; pf0$populacao_faixa[pf0$cod6 == "330010" & pf0$faixa == "80+"] <- 0
  cf <- casos_faixa; cf$casos[cf$cod6 == "330010" & cf$faixa == "80+"] <- 1L
  expect_error(padronizar_direto(cf, pf0, padrao), "população zero")
})

test_that("população-padrão: pesos somam 1, na ordem das faixas", {
  pop_idade <- data.frame(cod6 = rep(c("a", "b"), each = 11), faixa = rep(FAIXAS_ETARIAS$faixa, 2), populacao = 1:22)
  p <- populacao_padrao(pop_idade)
  expect_equal(p$faixa, FAIXAS_ETARIAS$faixa)
  expect_equal(sum(p$peso), 1)
  expect_equal(p$populacao[1], 1 + 12)
})

test_that("casos por faixa: grade completa com zero e sem perder caso", {
  casos <- data.frame(CO_MUN_RES = c("330010", "330010", "330020"), agente = factor(c("vsr", "vsr", "influenza"), levels = AGENTES),
                      ano_banco = 2024L, NU_IDADE_N = c(2L, 3L, 85L), TP_IDADE = c(2L, 3L, 3L))
  g <- calcular_casos_faixa(casos, c("330010", "330020"), anos = 2024L)
  expect_equal(nrow(g), 2 * 3 * 11)
  expect_equal(sum(g$casos), 3)
  expect_equal(g$casos[g$cod6 == "330010" & g$agente == "vsr" & g$faixa %in% c("<1", "1-4")], c(1L, 1L))
  expect_equal(g$casos[g$cod6 == "330020" & g$agente == "influenza" & g$faixa == "80+"], 1L)
})
