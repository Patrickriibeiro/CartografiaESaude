# Testes das regras candidatas de caso (CS-007 / ADR-0002).
# Fichas FABRICADAS, uma por situação, com a resposta calculada à mão.

fichas_caso <- function() {
  # cada linha: uma situação; NA = campo não preenchido
  f <- data.frame(
    id = c("covid_esp", "covid_so_criterio", "covid_generico", "covid_clinico",
           "covid_sorologia", "flu_esp", "flu_clinico", "vsr_esp", "outro_virus_sem_vsr",
           "aberta_com_pcr_covid", "covid_e_vsr", "nao_especificado"),
    CLASSI_FIN = c(5L, 5L, 5L, 5L, 5L, 1L, 1L, 2L, 2L, NA, 5L, 4L),
    CRITERIO   = c(1L, 1L, 2L, 3L, 1L, 1L, 2L, 1L, 1L, NA, 1L, NA),
    PCR_SARS2  = c(1L, NA, NA, NA, NA, NA, NA, NA, NA, 1L, 1L, 1L),
    AN_SARS2   = NA_integer_,
    POS_PCRFLU = c(NA, NA, NA, NA, NA, 1L, NA, NA, NA, NA, NA, NA),
    POS_AN_FLU = NA_integer_,
    PCR_VSR    = c(NA, NA, NA, NA, NA, NA, NA, 1L, NA, NA, 1L, NA),
    AN_VSR     = NA_integer_,
    PCR_RESUL  = c(1L, NA, 1L, NA, NA, 1L, NA, 1L, 1L, 1L, 1L, 1L),
    RES_AN     = NA_integer_,
    RES_IGG    = c(NA, NA, NA, NA, 1L, NA, NA, NA, NA, NA, NA, NA),
    RES_IGM    = NA_integer_, RES_IGA = NA_integer_,
    ano_banco  = 2022L,
    stringsAsFactors = FALSE
  )
  f
}

test_that("sinais_caso traduz os campos em lógicos, com NA como FALSE", {
  s <- sinais_caso(fichas_caso())
  expect_equal(sum(s$esp_sarscov2), 4)   # covid_esp, aberta, covid_e_vsr, nao_especificado
  expect_equal(sum(s$esp_vsr), 2)
  expect_equal(sum(s$sorologia), 1)
  expect_equal(sum(s$cf_vazio), 1)
  expect_false(anyNA(unlist(s)))
})

test_that("cada regra conta exatamente as fichas previstas à mão", {
  f <- fichas_caso()
  conta <- function(regra) {
    m <- aplicar_regra_caso(f, regra)
    lapply(m, function(col) f$id[col])
  }
  r1 <- conta("R1_estrita_pdf")
  expect_setequal(r1$sarscov2, c("covid_esp", "covid_e_vsr"))
  expect_setequal(r1$influenza, "flu_esp")
  expect_setequal(r1$vsr, "vsr_esp")

  r2 <- conta("R2_vigilancia")
  expect_setequal(r2$sarscov2, c("covid_esp", "covid_so_criterio", "covid_sorologia", "covid_e_vsr"))
  expect_setequal(r2$influenza, "flu_esp")
  expect_setequal(r2$vsr, "vsr_esp")  # covid_e_vsr NÃO é VSR: classificação é COVID

  r3 <- conta("R3_qualquer_evidencia_lab")
  expect_setequal(r3$sarscov2, c("covid_esp", "covid_so_criterio", "covid_generico", "covid_sorologia", "covid_e_vsr"))

  r4 <- conta("R4_classificacao")
  expect_setequal(r4$sarscov2, c("covid_esp", "covid_so_criterio", "covid_generico", "covid_clinico", "covid_sorologia", "covid_e_vsr"))
  expect_setequal(r4$influenza, c("flu_esp", "flu_clinico"))

  r5 <- conta("R5_laboratorial")
  expect_setequal(r5$sarscov2, c("covid_esp", "aberta_com_pcr_covid", "covid_e_vsr", "nao_especificado"))
  expect_setequal(r5$vsr, c("vsr_esp", "covid_e_vsr"))
})

test_that("só a regra laboratorial pura conta uma ficha em dois agentes", {
  cmp <- comparar_regras_caso(fichas_caso())
  dup <- cmp[cmp$agente == "fichas_em_2_ou_mais_agentes", ]
  expect_equal(dup$casos[dup$regra == "R5_laboratorial"], 1)
  expect_true(all(dup$casos[dup$regra != "R5_laboratorial"] == 0))
  expect_equal(nrow(cmp), length(REGRAS_CASO) * (length(AGENTES) + 1))
})

test_that("a decomposição separa onde está o laboratório das fichas sem campo específico", {
  dec <- decompor_sem_campo_especifico(fichas_caso())
  cov <- dec[dec$agente == "sarscov2", ]
  expect_equal(cov$classificados, 6)
  expect_equal(cov$com_campo_especifico, 2)
  expect_equal(cov$sem_campo_especifico, 4)
  expect_equal(cov$resultado_positivo_generico_ou_sorologia, 2)  # generico, sorologia
  expect_equal(cov$so_criterio_laboratorial_declarado, 1)         # so_criterio
  expect_equal(cov$criterio_clinico_ou_imagem, 1)                 # clinico
  # as partes somam o todo
  expect_equal(cov$sem_campo_especifico,
               cov$resultado_positivo_generico_ou_sorologia + cov$so_criterio_laboratorial_declarado +
                 cov$criterio_clinico_epidemiologico + cov$criterio_clinico_ou_imagem + cov$criterio_vazio)
})

test_that("co-detecção: ficha de COVID com VSR detectado é contada e apontada", {
  cd <- resumir_codeteccao(fichas_caso(), "R2_vigilancia")
  cov <- cd[cd$agente == "sarscov2", ]
  expect_equal(cov$casos, 4)
  expect_equal(cov$com_outro_agente_detectado, 1)
  expect_equal(cd$com_outro_agente_detectado[cd$agente == "vsr"], 0)
})

test_that("regra desconhecida para com a lista de opções", {
  expect_error(aplicar_regra_caso(fichas_caso(), "R9"), "R1_estrita_pdf")
})
