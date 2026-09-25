# 05_moran_lisa.R — Moran global e LISA por agente × ano (CS-017, ADR-0004)
#
#   resultados/estatistica/moran_lisa.rds        lista completa (global, lisa, sensibilidades)
#   resultados/estatistica/moran_global.csv      I e p por agente × ano × variável × vizinhança
#   resultados/estatistica/lisa_municipios.csv   92 × 12: Ii, p, p_fdr, quadrante, classe, nível, instável
#   resultados/estatistica/lisa_resumo.csv       contagens por agente × ano (antes/depois do FDR)
#   resultados/estatistica/lisa_concordancia.csv suavizada × bruta
#   resultados/estatistica/moran_regional.csv    Moran global nas 9 regiões de saúde (CS-030, descritivo)

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
