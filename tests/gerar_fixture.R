# tests/gerar_fixture.R — gera a base sintética do CS-010
#
# TODAS AS FICHAS SÃO FABRICADAS. Nenhuma linha vem do SIVEP real: só o formato
# (nomes de colunas, códigos) e a lista oficial dos 92 municípios do RJ.
#
# Cada cenário tem a RESPOSTA ESPERADA escrita à mão (esperado_agente,
# esperado_codeteccao, esperado_subtipo), a partir do texto do ADR-0002, e não
# calculada pelas funções que o teste vai conferir.
#
# Uso (da raiz do projeto):  Rscript tests/gerar_fixture.R

source("R/funcoes_utilitarias.R", encoding = "UTF-8")
set.seed(SEMENTE)

sidra <- jsonlite::fromJSON("dados/externos/sidra_4714_censo_2022_rj.json")
codigos <- sort(substr(sidra$D1C[-1], 1, 6))
stopifnot(length(codigos) == 92)

# Uma linha por cenário. NA = campo vazio. n = quantas fichas geradas.
# Colunas de laboratório: PCR_RESUL/RES_AN (resultado geral), checkboxes por vírus,
# e as portas de entrada POS_PCROUT/POS_AN_OUT ("positivo para outros vírus").
cen <- read.table(header = TRUE, stringsAsFactors = FALSE, na.strings = "NA", text = "
cenario                     n  CLASSI_FIN CRITERIO PCR_RESUL RES_AN POS_PCROUT POS_AN_OUT PCR_SARS2 AN_SARS2 POS_PCRFLU TP_FLU_PCR POS_AN_FLU TP_FLU_AN PCR_VSR AN_VSR esperado_agente esperado_codeteccao esperado_subtipo
covid_pcr                  20  5          1        1         NA     1          NA         1         NA       NA         NA         NA         NA        NA      NA     sarscov2        FALSE               NA
covid_antigeno             10  5          1        NA        1      NA         1          NA        1        NA         NA         NA         NA        NA      NA     sarscov2        FALSE               NA
covid_so_criterio_lab       8  5          1        NA        NA     NA         NA         NA        NA       NA         NA         NA         NA        NA      NA     sarscov2        FALSE               NA
covid_clinico               6  5          3        NA        NA     NA         NA         NA        NA       NA         NA         NA         NA        NA      NA     NA              FALSE               NA
covid_clin_epi_com_pcr      4  5          2        1         NA     1          NA         1         NA       NA         NA         NA         NA        NA      NA     sarscov2        FALSE               NA
flu_A_pcr                  12  1          1        1         NA     NA         NA         NA        NA       1          1          NA         NA        NA      NA     influenza       FALSE               A
flu_B_antigeno              6  1          1        NA        1      NA         NA         NA        NA       NA         NA         1          2         NA      NA     influenza       FALSE               B
flu_so_criterio_lab         4  1          1        NA        NA     NA         NA         NA        NA       NA         NA         NA         NA        NA      NA     influenza       FALSE               NA
flu_clinico                 3  1          2        NA        NA     NA         NA         NA        NA       NA         NA         NA         NA        NA      NA     NA              FALSE               NA
vsr_pcr                    15  2          1        1         NA     1          NA         NA        NA       NA         NA         NA         NA        1       NA     vsr             FALSE               NA
vsr_antigeno                5  2          1        NA        1      NA         1          NA        NA       NA         NA         NA         NA        NA      1      vsr             FALSE               NA
outro_virus_sem_vsr         8  2          1        1         NA     1          NA         NA        NA       NA         NA         NA         NA        NA      NA     NA              FALSE               NA
covid_com_vsr               3  5          1        1         NA     1          NA         1         NA       NA         NA         NA         NA        1       NA     sarscov2        TRUE                NA
flu_A_com_vsr               3  1          1        1         NA     1          NA         NA        NA       1          1          NA         NA        1       NA     influenza       TRUE                A
vsr_com_covid_antigeno      2  2          1        1         1      1          1          NA        1        NA         NA         NA         NA        1       NA     vsr             TRUE                NA
vsr_encerrado_como_flu_B    2  1          1        1         NA     1          NA         NA        NA       1          2          NA         NA        1       NA     influenza       TRUE                B
aberta_com_pcr_covid        4  NA         NA       1         NA     1          NA         1         NA       NA         NA         NA         NA        NA      NA     NA              FALSE               NA
outro_agente                3  3          1        NA        NA     NA         NA         NA        NA       NA         NA         NA         NA        NA      NA     NA              FALSE               NA
")

# Uma ficha "não especificado" (sem caso) por município em 2022: garante os 92
# municípios na base, e os 32 últimos ficam SEM nenhum caso (teste da grade
# completa do CS-012).
base <- data.frame(cenario = "nao_especificado_por_municipio", CO_MUN_RES = codigos, ano = 2022L,
                   CLASSI_FIN = 4, esperado_agente = NA, esperado_codeteccao = FALSE,
                   esperado_subtipo = NA, stringsAsFactors = FALSE)

linhas <- do.call(rbind, lapply(seq_len(nrow(cen)), function(i) {
  x <- cen[rep(i, cen$n[i]), setdiff(names(cen), "n")]
  x$CO_MUN_RES <- sample(codigos[1:60], nrow(x), replace = TRUE)
  x$ano <- sample(2022:2025, nrow(x), replace = TRUE)
  x
}))
todas <- merge(base, linhas, all = TRUE, sort = FALSE)
todas <- todas[order(todas$ano, todas$cenario, todas$CO_MUN_RES), ]

# Datas dentro do ano epidemiológico do banco (10/jan a 20/dez é seguro para 2022-2025).
dias <- sample(0:344, nrow(todas), replace = TRUE)
inicio <- as.Date(sprintf("%d-01-10", todas$ano)) + dias
todas$DT_SIN_PRI <- format(inicio)
todas$DT_NOTIFIC <- format(inicio + 3)
todas$DT_DIGITA <- format(inicio + 5)
todas$SEM_PRI <- sprintf("%02d", semana_epidemiologica(inicio)$semana_epi)
todas$SG_UF <- "RJ"
todas$CO_MUN_NOT <- todas$CO_MUN_RES
todas$HOSPITAL <- 1L
todas$CS_SEXO <- sample(c("M", "F"), nrow(todas), replace = TRUE)
todas$TP_IDADE <- 3L
todas$NU_IDADE_N <- sample(0:90, nrow(todas), replace = TRUE)
todas$rotulo <- "FABRICADO"

ordem <- c("rotulo", "cenario", "ano", "esperado_agente", "esperado_codeteccao", "esperado_subtipo",
           "CO_MUN_RES", "CO_MUN_NOT", "SG_UF", "DT_SIN_PRI", "DT_NOTIFIC", "DT_DIGITA", "SEM_PRI",
           "CS_SEXO", "NU_IDADE_N", "TP_IDADE", "HOSPITAL", "CLASSI_FIN", "CRITERIO",
           "PCR_RESUL", "RES_AN", "POS_PCROUT", "POS_AN_OUT", "PCR_SARS2", "AN_SARS2",
           "POS_PCRFLU", "TP_FLU_PCR", "POS_AN_FLU", "TP_FLU_AN", "PCR_VSR", "AN_VSR")
todas <- todas[, ordem]

destino <- file.path("tests", "testthat", "fixtures", "sivep_sintetico.csv")
dir.create(dirname(destino), recursive = TRUE, showWarnings = FALSE)
con <- file(destino, open = "wb")
utils::write.csv(todas, con, row.names = FALSE, na = "", fileEncoding = "UTF-8")
close(con)
message(sprintf("%s: %d fichas FABRICADAS, %d municípios, %d cenários, anos %s",
                destino, nrow(todas), length(unique(todas$CO_MUN_RES)),
                length(unique(todas$cenario)), paste(sort(unique(todas$ano)), collapse = ",")))
