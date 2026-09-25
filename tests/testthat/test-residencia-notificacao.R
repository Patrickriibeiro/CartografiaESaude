# Testes da comparação residência × notificação (CS-031). Dados FABRICADOS.
# banco_sintetico(), utc() e projeto_temporario() estão em helper-projeto.R.

test_that("o complemento lê só notificados no RJ de quem mora fora, inclusive residência vazia", {
  projeto_temporario()
  f <- banco_sintetico(data.frame(
    #            mora RJ,   mora MG→not RJ, mora RJ→not MG, mora ?→not RJ, mora SP→not SP
    CO_MUN_RES = c("330455", "313670",      "330010",       NA,            "355030"),
    CO_MUN_NOT = c("330455", "330630",      "313670",       "330330",      "355030"),
    SG_UF      = c("RJ",     "MG",          "RJ",           NA,            "SP"),
    DT_SIN_PRI = utc(rep("2022-03-06", 5)),
    SEM_PRI = rep("10", 5)
  ))
  fora <- preparar_sivep_notificados_de_fora(2022, fontes = f)
  expect_equal(sort(fora$CO_MUN_NOT), c("330330", "330630"))
  expect_true(any(is.na(fora$CO_MUN_RES)))   # sem o is.na() explícito, o filtro a descartaria
  # E o recorte do estudo continua o mesmo: só os 2 residentes do RJ.
  expect_equal(sort(preparar_sivep(2022, fontes = f)$CO_MUN_RES), c("330010", "330455"))
})

# Cinco casos de residentes e dois de fora, com a resposta calculada à mão.
casos_exemplo <- function() {
  list(
    casos = data.frame(
      CO_MUN_RES = c("330010", "330010", "330010", "330020", "330020"),
      CO_MUN_NOT = c("330010", "330020", "313670", NA,       "330020"),
      agente = factor(c("vsr", "vsr", "vsr", "vsr", "influenza"), levels = AGENTES),
      ano_banco = 2024L, stringsAsFactors = FALSE),
    de_fora = data.frame(
      CO_MUN_RES = c("313670", NA), CO_MUN_NOT = c("330020", "330030"),
      agente = factor(c("vsr", "vsr"), levels = AGENTES), ano_banco = 2024L, stringsAsFactors = FALSE)
  )
}

test_that("cada caso cai numa só casinha de cada lado, com a conta feita à mão", {
  e <- casos_exemplo()
  rn <- comparar_residencia_notificacao(e$casos, e$de_fora, c("330010", "330020", "330030"),
                                        anos = 2024L)
  expect_equal(nrow(rn), 3 * 3)   # 3 municípios × 3 agentes × 1 ano, com zeros explícitos
  por <- resumir_residencia_notificacao(rn)
  a <- por[por$cod6 == "330010", ]; b <- por[por$cod6 == "330020", ]; c <- por[por$cod6 == "330030", ]
  # A: 3 residentes; 1 notificado em A, 1 em B, 1 em MG.
  expect_equal(c(a$casos_res, a$casos_not, a$not_mesmo_municipio, a$res_not_fora_do_rj), c(3, 1, 1, 1))
  # B: 2 residentes (1 sem notificação); recebe 1 de A e 1 de MG.
  expect_equal(c(b$casos_res, b$casos_not, b$not_de_outro_mun_rj, b$not_de_fora_do_rj, b$res_sem_not),
               c(2, 3, 1, 1, 1))
  # C: nenhum residente, 1 notificado de residência desconhecida (fora do RJ).
  expect_equal(c(c$casos_res, c$casos_not), c(0, 1))
  expect_true(is.na(c$razao_not_res))          # sem residente, razão não existe (não é Inf)
  expect_equal(a$razao_not_res, 1 / 3)
  expect_equal(por$cod6, c("330020", "330030", "330010"))   # ordenado pelo saldo: +1, +1, −2
  expect_equal(sum(rn$casos_res), 5); expect_equal(sum(rn$casos_not), 5)
})

test_that("município de notificação do RJ fora da lista para, em vez de sumir", {
  e <- casos_exemplo()
  expect_error(comparar_residencia_notificacao(e$casos, e$de_fora, c("330010", "330020"), anos = 2024L),
               "fora da lista: 330030")
})

test_that("sem nenhum caso de fora, a coluna existe com zeros", {
  e <- casos_exemplo()
  rn <- comparar_residencia_notificacao(e$casos, e$de_fora[0, ], c("330010", "330020", "330030"), anos = 2024L)
  expect_equal(sum(rn$not_de_fora_do_rj), 0)
  expect_equal(sum(rn$casos_not), 3)
})
