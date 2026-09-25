# 05_moran_lisa.R — Moran global e LISA por agente × ano (CS-017, ADR-0004)
#
#   resultados/estatistica/moran_lisa.rds        lista completa (global, lisa, sensibilidades)
#   resultados/estatistica/moran_global.csv      I e p por agente × ano × variável × vizinhança
#   resultados/estatistica/lisa_municipios.csv   92 × 12: Ii, p, p_fdr, quadrante, classe, nível, instável
#   resultados/estatistica/lisa_resumo.csv       contagens por agente × ano (antes/depois do FDR)
#   resultados/estatistica/lisa_concordancia.csv suavizada × bruta
#   resultados/estatistica/moran_regional.csv    Moran global nas 9 regiões de saúde (CS-030, descritivo)
#   resultados/estatistica/spearman_leitos.csv   taxa de SRAG × leitos por 100 mil, por ano, IC bootstrap (CS-034)
#   resultados/estatistica/zeros_diagnostico.csv municípios sem caso × zeros esperados, notificação própria e leitos (CS-041)

source("00_setup.R")

ind <- as.data.frame(arrow::read_parquet(file.path("dados", "processados", "indicadores_municipais.parquet")))
municipios <- readRDS(file.path("dados", "processados", "municipios_rj.rds"))
pesos <- readRDS(file.path("resultados", "objetos", "pesos_queen.rds"))
if (contar_ligacoes(pesos$neighbours) != 456) stop("Pesos não são os da malha oficial (ADR-0006)")

t0 <- Sys.time()

# Principal: taxa suavizada (D-09), Queen.
principal <- executar_moran_lisa(ind, pesos, variavel = "incid_eb_100k")

# Sensibilidade 1: taxa bruta, Queen.
bruta <- executar_moran_lisa(ind, pesos, variavel = "incid_100k")

# Sensibilidade 2: vizinhança Rook (só o Moran global).
pesos_rook <- criar_pesos(criar_vizinhos_queen(municipios, queen = FALSE))
rook <- executar_moran_lisa(ind, pesos_rook, variavel = "incid_eb_100k", rotulo_vizinhanca = "rook")

global <- rbind(principal$global, bruta$global, rook$global)

# Escala regional (CS-030): Moran global só, sobre a taxa bruta; sem LISA com n = 9.
ind_reg <- as.data.frame(arrow::read_parquet(file.path("dados", "processados", "indicadores_regionais.parquet")))
pesos_reg <- readRDS(file.path("resultados", "objetos", "pesos_regionais.rds"))
regional <- executar_moran_regional(ind_reg, pesos_reg)
lisa <- principal$lisa
lisa$nome <- municipios$nome[match(lisa$cod6, municipios$cod6)]
resumo <- resumir_lisa(lisa)
concordancia <- comparar_lisa(principal$lisa, bruta$lisa)

# Contratos: 12 combinações, 92 municípios em cada, sem NA.
stopifnot(nrow(principal$global) == 12, nrow(lisa) == 92 * 12, nrow(regional) == 12,
          !anyNA(lisa[, c("Ii", "p_perm", "p_fdr", "classe")]))

saveRDS(list(principal = principal, bruta = bruta, rook = rook, regional = regional, resumo = resumo,
             concordancia = concordancia, nsim = N_PERMUTACOES, alfa = ALFA_LISA, semente = SEMENTE),
        file.path("resultados", "estatistica", "moran_lisa.rds"))
gravar <- function(x, nome) utils::write.csv(x, file.path("resultados", "estatistica", nome),
                                             row.names = FALSE, fileEncoding = "UTF-8")
gravar(global, "moran_global.csv")
gravar(lisa[, c("agente", "ano", "cod6", "nome", "valor", "z", "lag_z", "Ii", "p_perm", "p_fdr",
                "quadrante", "nivel", "classe", "n_vizinhos", "instavel")], "lisa_municipios.csv")
gravar(resumo, "lisa_resumo.csv")
gravar(concordancia, "lisa_concordancia.csv")
gravar(regional, "moran_regional.csv")

message(sprintf("Moran/LISA: 12 combinações × 3 rodadas, %d permutações, em %.0f s",
                N_PERMUTACOES, as.numeric(Sys.time() - t0, units = "secs")))
g <- principal$global
message("Moran global (suavizada, Queen) significativo em ", sum(g$p_perm < ALFA_LISA), " de 12")
print(g[, c("agente", "ano", "I", "p_perm")], row.names = FALSE, digits = 3)
print(resumo[, c("agente", "ano", "sig_sem_correcao", "sig_fdr", "HH_confirmado", "LL_confirmado",
                 "HH_indicativo", "LL_indicativo", "instaveis_sig")], row.names = FALSE)
message(sprintf("Moran regional (9 regiões, taxa bruta): I abaixo do esperado %.3f em %d de 12; p < %.2f em %d de 12",
                -1 / 8, sum(regional$I < regional$esperado_I), ALFA_LISA, sum(regional$p_perm < ALFA_LISA)))

# ---- taxa × leitos (CS-034): Spearman por ano, IC por bootstrap, sem leitura causal ----
leitos <- as.data.frame(arrow::read_parquet(file.path("dados", "processados", "leitos_rj.parquet")))
sp <- correlacionar_leitos(ind, leitos)
stopifnot(nrow(sp) == 2 * length(ANOS_ESTUDO), all(sp$ic_inf <= sp$rho & sp$rho <= sp$ic_sup))
gravar(sp, "spearman_leitos.csv")
print(sp[, c("ano", "rotulo", "rho", "ic_inf", "ic_sup")], row.names = FALSE, digits = 3)

# ---- agrupamento de zeros na taxa bruta (CS-041) ----
# "Notificação própria" = o município notificou ao menos uma ficha de SRAG (de
# residente do RJ, qualquer agente, qualquer classificação) no ano.
# Testagem: ficha com resultado de RT-PCR ou antígeno (1, 2 ou 3), por município de RESIDÊNCIA.
fichas <- as.data.frame(arrow::read_parquet(file.path("dados", "intermediarios", "sivep_rj.parquet"),
                                            col_select = c("CO_MUN_NOT", "CO_MUN_RES", "ano_banco", "PCR_RESUL", "RES_AN")))
notificantes <- unique(data.frame(cod6 = fichas$CO_MUN_NOT, ano = fichas$ano_banco)[!is.na(fichas$CO_MUN_NOT), ])
fichas$testada <- as.integer(fichas$PCR_RESUL %in% 1:3 | fichas$RES_AN %in% 1:3)
por_mun <- stats::aggregate(cbind(fichas = 1L, testadas = testada) ~ CO_MUN_RES + ano_banco, data = fichas, FUN = sum)
names(por_mun)[1:2] <- c("cod6", "ano")
zeros <- diagnosticar_zeros(ind, notificantes, leitos, por_mun)
stopifnot(nrow(zeros) == 12, all(zeros$zeros == tapply(ind$casos == 0, paste(ind$agente, ind$ano), sum)[paste(zeros$agente, zeros$ano)]))
gravar(zeros, "zeros_diagnostico.csv")
print(zeros[, c("agente", "ano", "zeros", "zeros_esperados", "zeros_sem_notificacao", "outros_sem_notificacao",
                "zeros_sem_leito", "pop_mediana_zeros", "pop_mediana_outros", "fichas_zeros",
                "pct_testadas_zeros", "pct_testadas_outros")], row.names = FALSE, digits = 3)
