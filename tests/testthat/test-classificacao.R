# Testes da classificação por agente (CS-008) sobre a base sintética (CS-010).
# A resposta esperada de cada ficha foi escrita à mão por cenário, em
# tests/gerar_fixture.R, a partir do ADR-0002; não é calculada pelas funções
# que estes testes conferem.

test_that("a base sintética cobre o que o CS-010 promete, e toda linha é FABRICADA", {
  f <- ler_fixture_sivep()
  expect_gte(nrow(f), 200)
  expect_true(all(f$rotulo == "FABRICADO"))
  expect_equal(length(unique(f$CO_MUN_RES)), 92)
  expect_setequal(unique(f$ano), 2022:2025)
  expect_setequal(unique(stats::na.omit(f$esperado_agente)), AGENTES)
  expect_gt(sum(f$esperado_codeteccao), 0)        # co-detecção
  expect_gt(sum(is.na(f$CLASSI_FIN)), 0)          # ficha não encerrada
  expect_gt(sum(f$CRITERIO %in% c("2", "3")), 0)  # encerramento clínico
})

test_that("cada ficha recebe exatamente o agente esperado (regra aceita, R2)", {
  f <- tipar_fixture()
  obtido <- as.character(classificar_agente(f)$agente)
  # por cenário, para o erro dizer QUAL situação divergiu
  por_cenario <- tapply(seq_along(obtido), f$cenario, function(i) identical(obtido[i], f$esperado_agente[i]))
  expect_true(all(por_cenario), info = paste("cenários divergentes:", paste(names(por_cenario)[!por_cenario], collapse = ", ")))
  expect_identical(obtido, f$esperado_agente)
})

test_that("co-detecção e subtipo da influenza batem com o esperado, ficha a ficha", {
  f <- tipar_fixture()
  f$id <- seq_len(nrow(f))
  casos <- aplicar_criterios_inclusao(classificar_agente(f))
  esperado <- f[match(casos$id, f$id), ]
  expect_equal(nrow(casos), sum(!is.na(f$esperado_agente)))
  expect_identical(casos$codeteccao, esperado$esperado_codeteccao)
  expect_identical(casos$subtipo_influenza, esperado$esperado_subtipo)
  expect_true(all(is.na(casos$subtipo_influenza[casos$agente != "influenza"])))
})

test_that("uma regra que conta a ficha em dois agentes é recusada (atribuição única)", {
  f <- tipar_fixture()
  expect_error(classificar_agente(f, "R5_laboratorial"), "mais de um agente")
})

test_that("aplicar_criterios_inclusao exige a classificação antes", {
  expect_error(aplicar_criterios_inclusao(tipar_fixture()), "classificar_agente")
})

test_that("contagem por agente e ano é a mesma da tabela comparativa do ADR-0002", {
  f <- tipar_fixture()
  casos <- aplicar_criterios_inclusao(classificar_agente(f))
  por_agente <- contar_casos_agente(casos)
  cmp <- comparar_regras_caso(f)
  r2 <- cmp[cmp$regra == REGRA_CASO & cmp$agente %in% AGENTES, ]
  junto <- merge(por_agente, r2, by = c("agente", "ano"), suffixes = c("_cs008", "_adr"))
  expect_equal(nrow(junto), length(AGENTES) * 4)
  expect_equal(junto$casos_cs008, junto$casos_adr)
})

test_that("o caminho inteiro (PARQUET -> preparo -> classificação) roda em menos de 5 s", {
  projeto_temporario()
  f <- ler_fixture_sivep()
  t <- system.time({
    fontes <- bancos_da_fixture(f)
    d <- suppressMessages(preparar_sivep(2022:2025, fontes = fontes))
    casos <- aplicar_criterios_inclusao(classificar_agente(d))
  })[["elapsed"]]
  expect_lt(t, 5)
  expect_equal(nrow(d), nrow(f))
  esperado <- as.data.frame(table(agente = factor(f$esperado_agente, levels = AGENTES), ano = f$ano),
                            stringsAsFactors = FALSE)
  obtido <- contar_casos_agente(casos)
  junto <- merge(obtido, esperado, by = c("agente", "ano"))
  expect_equal(junto$casos, junto$Freq)
  # municípios com caso: exatamente os que têm caso esperado na base
  expect_setequal(unique(casos$CO_MUN_RES), unique(f$CO_MUN_RES[!is.na(f$esperado_agente)]))
  # e pelo menos 32 dos 92 ficam sem nenhum caso (entrada do teste de grade do CS-012)
  expect_gte(92 - length(unique(casos$CO_MUN_RES)), 32)
})
