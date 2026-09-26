# Testes da série semanal (CS-032) e das fichas não encerradas (CS-035). Dados FABRICADOS.

test_that("a semana começa no domingo: sábado volta 6 dias, domingo fica", {
  d <- as.Date(c("2025-12-28", "2026-01-03", "2025-12-31", "2022-01-01"))
  expect_equal(inicio_semana_epi(d), as.Date(c("2025-12-28", "2025-12-28", "2025-12-28", "2021-12-26")))
})

test_that("o calendário do estudo tem 209 semanas, com a 53 de 2025", {
  s <- semanas_do_estudo(2022:2025)
  expect_equal(as.vector(table(s$ano_epi)), c(52L, 52L, 52L, 53L))
  expect_equal(nrow(s), 209)
  expect_equal(range(s$inicio_semana), as.Date(c("2022-01-02", "2025-12-28")))
  ult <- s[s$inicio_semana == as.Date("2025-12-28"), ]
  expect_equal(c(ult$ano_epi, ult$semana_epi), c(2025L, 53L))
})

regioes_exemplo <- data.frame(cod6 = c("330010", "330020", "330030"), cod_regiao = c("33001", "33001", "33002"),
                              regiao = c("Baía da Ilha Grande", "Baía da Ilha Grande", "Baixada Litorânea"),
                              stringsAsFactors = FALSE)

test_that("série semanal: zero explícito, estado = soma das regiões, semana 53 no lugar certo", {
  casos <- data.frame(
    CO_MUN_RES = c("330010", "330020", "330030", "330030"),
    agente = factor(c("vsr", "vsr", "vsr", "influenza"), levels = AGENTES),
    # 30/12/2025 é da semana 53 de 2025; o SEM_PRI do banco diria "01".
    DT_SIN_PRI = as.Date(c("2025-03-04", "2025-03-06", "2025-03-05", "2025-12-30")),
    stringsAsFactors = FALSE)
  s <- serie_semanal(casos, regioes_exemplo, anos = 2025L)
  expect_equal(nrow(s), (1 + 2) * 3 * 53)   # estado + 2 regiões, 3 agentes, 53 semanas
  est <- s[s$recorte == "Estado do Rio de Janeiro" & s$agente == "vsr", ]
  expect_equal(est$casos[est$inicio_semana == as.Date("2025-03-02")], 3L)
  expect_equal(sum(est$casos), 3L)
  big <- s[s$recorte == "Baía da Ilha Grande" & s$agente == "vsr", ]
  expect_equal(sum(big$casos), 2L)
  flu <- s[s$recorte == "Baixada Litorânea" & s$agente == "influenza" & s$casos > 0, ]
  expect_equal(c(flu$ano_epi, flu$semana_epi), c(2025L, 53L))
  expect_equal(sum(s$casos == 0), nrow(s) - 5)   # só 5 células com caso (3 regionais + 2 do estado)
})

test_that("série para se o município não tem região ou o caso cai fora do calendário", {
  c1 <- data.frame(CO_MUN_RES = "339999", agente = factor("vsr", levels = AGENTES),
                   DT_SIN_PRI = as.Date("2025-03-04"), stringsAsFactors = FALSE)
  expect_error(serie_semanal(c1, regioes_exemplo, anos = 2025L), "sem região")
  c2 <- data.frame(CO_MUN_RES = "330010", agente = factor("vsr", levels = AGENTES),
                   DT_SIN_PRI = as.Date("2023-03-04"), stringsAsFactors = FALSE)
  expect_error(serie_semanal(c2, regioes_exemplo, anos = 2025L), "fora das semanas")
})

test_that("as campanhas da configuração real cobrem os 4 anos, entre março e abril", {
  cmp <- ler_campanhas_influenza(yaml::read_yaml(file.path(raiz_projeto, "config", "fontes.yml")))
  expect_equal(cmp$ano, 2022:2025)
  expect_true(all(format(cmp$inicio, "%m") %in% c("03", "04")))
  expect_equal(as.integer(format(cmp$inicio, "%Y")), cmp$ano)
  expect_true(all(grepl("^https://", cmp$fonte)))
})

test_that("não encerradas: CLASSI_FIN vazio por ano e por semana", {
  x <- data.frame(ano_banco = c(2024L, 2024L, 2025L, 2025L, 2025L, 2025L),
                  semana_epi = c(1L, 2L, 1L, 1L, 52L, 53L),
                  CLASSI_FIN = c(5L, NA, 1L, NA, 4L, NA))
  a <- resumir_nao_encerrados(x)
  expect_equal(a$ano, c(2024L, 2025L))
  expect_equal(a$nao_encerradas, c(1L, 2L))
  expect_equal(a$proporcao, c(0.5, 0.5))
  s <- nao_encerrados_por_semana(x, 2025L)
  expect_equal(s$semana_epi, c(1L, 52L, 53L))
  expect_equal(s$fichas, c(2L, 1L, 1L))
  expect_equal(s$proporcao, c(0.5, 0, 1))
  expect_error(nao_encerrados_por_semana(x, 2022L), "Sem fichas")
})

test_that("os gráficos montam", {
  casos <- data.frame(CO_MUN_RES = "330010", agente = factor("vsr", levels = AGENTES),
                      DT_SIN_PRI = as.Date("2025-03-04"), stringsAsFactors = FALSE)
  s <- serie_semanal(casos, regioes_exemplo, anos = 2025L)
  cmp <- data.frame(ano = 2025L, inicio = as.Date("2025-04-07"), fonte = "x")
  expect_s3_class(ggplot2::ggplot_build(grafico_serie_semanal(s, "Baía da Ilha Grande", cmp)), "ggplot_built")
  expect_error(grafico_serie_semanal(s, "Atlântida", cmp), "sem dados")
  ne <- data.frame(ano = 2025L, semana_epi = 1:3, fichas = c(10L, 20L, 5L), nao_encerradas = c(0L, 1L, 1L),
                   proporcao = c(0, 0.05, 0.2))
  expect_s3_class(ggplot2::ggplot_build(grafico_nao_encerrados(ne, "teste")), "ggplot_built")
})

test_that("ano epidemiológico: limites, 53 semanas em 2025 e meio do ano a no máximo 2 dias de 1º de julho", {
  l <- limites_ano_epi(2022:2025)
  expect_equal(l$inicio, as.Date(c("2022-01-02", "2023-01-01", "2023-12-31", "2024-12-29")))
  expect_equal(l$fim, as.Date(c("2022-12-31", "2023-12-30", "2024-12-28", "2026-01-03")))
  expect_equal(l$semanas, c(52L, 52L, 52L, 53L))
  expect_equal(l$dias, 7L * l$semanas)
  expect_equal(weekdays(l$inicio), rep(weekdays(as.Date("2022-01-02")), 4))   # sempre domingo
  expect_lte(max(abs(as.numeric(as.Date(paste0(l$ano, "-07-01")) - l$meio))), 2)
})

test_that("tempo até o encerramento: mediana, p90, % em 30/60/90 dias e datas inconsistentes (CS-048)", {
  s <- as.Date("2024-03-01")
  x <- data.frame(ano_banco = 2024L, DT_SIN_PRI = s,
                  DT_ENCERRA = s + c(10, 20, 40, 100, -5, NA),
                  DT_DIGITA = s + c(1, 2, 3, 4, 5, 6),
                  CLASSI_FIN = c(1L, 5L, 4L, 4L, 1L, NA))
  t <- tempo_encerramento(x)
  expect_equal(t$fichas, 6L)
  expect_equal(t$encerradas_com_data, 5L)
  expect_equal(t$encerramento_antes_dos_sintomas, 1L)          # -5 dias fica fora das medidas
  expect_equal(t$dias_encerramento_mediana, stats::median(c(10, 20, 40, 100)))
  expect_equal(t$pct_encerradas_30d, 100 * 2 / 6)               # sobre TODAS as fichas
  expect_equal(t$pct_encerradas_90d, 100 * 3 / 6)
  expect_equal(t$dias_digitacao_mediana, 3.5)
})

test_that("comparar_versoes expressa cada contagem em % da versão mais recente do mesmo ano (CS-048)", {
  r <- data.frame(ano = c(2025L, 2025L, 2024L, 2024L), versao = c("09-03-2026", "14-09-2026", "26-06-2025", "23-03-2026"),
                  data_versao = as.Date(c("2026-03-09", "2026-09-14", "2025-06-26", "2026-03-23")),
                  dias_apos_fim_do_ano = c(65L, 254L, 180L, 450L), fichas = c(90L, 100L, 50L, 50L), fora_do_ano = 0L,
                  encerradas = c(80L, 95L, 50L, 50L), casos_sarscov2 = c(9L, 10L, 5L, 5L), casos_influenza = c(20L, 20L, 1L, 1L),
                  casos_vsr = c(3L, 4L, 2L, 2L))
  c <- comparar_versoes(r)
  expect_equal(c$referencia, c(FALSE, TRUE, FALSE, TRUE))       # 2024 antes de 2025, por data
  expect_equal(c$pct_fichas[c$ano == 2025], c(90, 100))
  expect_equal(c$pct_casos_vsr[c$ano == 2025], c(75, 100))
  expect_equal(c$pct_casos_sarscov2[c$ano == 2024], c(100, 100))
  expect_s3_class(ggplot2::ggplot_build(grafico_versoes(c, 2025)), "ggplot_built")
  expect_error(grafico_versoes(c[c$ano == 2025 & c$referencia, ], 2025), "Menos de duas versões")
})

test_that("resumir_versao conta os mesmos casos que o caminho normal do pipeline (CS-048)", {
  projeto_temporario()
  f <- bancos_da_fixture()
  b <- bancos_sivep(2022, fontes = f)
  r <- resumir_versao(b$destino, 2022L, "23-03-2026")
  sv <- preparar_sivep(2022, fontes = f)
  esperado <- contar_casos_agente(aplicar_criterios_inclusao(classificar_agente(sv, REGRA_CASO)))
  for (ag in AGENTES) expect_equal(r[[paste0("casos_", ag)]], esperado$casos[esperado$agente == ag & esperado$ano == 2022], info = ag)
  expect_equal(r$fichas, nrow(sv))
  expect_equal(r$dias_apos_fim_do_ano, as.integer(as.Date("2026-03-23") - as.Date("2022-12-31")))
})

test_that("as versões anteriores da configuração real apontam para o S3 do portal e para dados/brutos/versoes (CS-048)", {
  v <- versoes_anteriores(yaml::read_yaml(file.path(raiz_projeto, "config", "fontes.yml")))
  expect_gte(nrow(v), 2)
  expect_true(all(startsWith(v$url, "https://s3.sa-east-1.amazonaws.com/ckan.saude.gov.br/SRAG/")))
  expect_true(all(mapply(function(u, ver) grepl(ver, u, fixed = TRUE), v$url, v$versao)))
  expect_true(all(startsWith(v$destino, file.path("dados", "brutos", "versoes"))))
})
