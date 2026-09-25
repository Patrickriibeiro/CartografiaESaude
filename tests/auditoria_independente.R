# tests/auditoria_independente.R — recálculo independente dos resultados (CS-027)
#
# Refaz os números centrais do projeto por OUTRO caminho: R base + arrow para ler
# os brutos, sem nenhuma função de R/ e sem o spdep. Se este script e o pipeline
# concordam, um erro teria de estar nos dois ao mesmo tempo.
#
# Uso, da raiz do projeto, com o pipeline já executado:  Rscript tests/auditoria_independente.R
# Saída: uma linha por conferência, com OK/DIVERGE, e código de saída 1 se algo divergir.

ok_total <- TRUE
conferir <- function(nome, obtido, esperado, tol = 0) {
  igual <- if (is.numeric(obtido)) all(abs(obtido - esperado) <= tol) else identical(obtido, esperado)
  cat(sprintf("%-70s %s\n", nome, if (igual) "OK" else sprintf("DIVERGE: %s x %s",
              paste(format(obtido), collapse = ","), paste(format(esperado), collapse = ","))))
  if (!igual) ok_total <<- FALSE
  invisible(igual)
}
ler <- function(...) utils::read.csv(file.path(...), stringsAsFactors = FALSE, fileEncoding = "UTF-8")

# ---- 1. Fichas e casos direto dos bancos brutos ---------------------------
bancos <- sort(list.files("dados/brutos", "^INFLUD2[2-5].*\\.parquet$", full.names = TRUE))
diag <- ler("resultados", "tabelas", "diagnostico_sivep.csv")
cpa <- ler("resultados", "tabelas", "casos_por_agente.csv")
cols <- c("CO_MUN_RES", "CLASSI_FIN", "CRITERIO", "PCR_SARS2", "AN_SARS2", "POS_PCRFLU", "POS_AN_FLU", "PCR_VSR", "AN_VSR")
for (i in seq_along(bancos)) {
  ano <- 2021L + i
  b <- as.data.frame(arrow::read_parquet(bancos[i], col_select = dplyr::all_of(c(cols, "SG_UF"))))
  # which(): sem ele, b[NA, ] cria linhas de NA e infla a contagem (erro da 1ª versão desta auditoria)
  rj <- b[which(substr(b$CO_MUN_RES, 1, 2) == "33"), ]
  conferir(sprintf("%d: fichas do RJ (bruto x diagnostico_sivep.csv)", ano), nrow(rj), diag$fichas_rj[diag$ano == ano])
  # residentes do RJ que o filtro por código NÃO alcança: UF de residência RJ sem código 33
  fora <- sum(which(b$SG_UF == "RJ") %in% which(is.na(b$CO_MUN_RES) | substr(b$CO_MUN_RES, 1, 2) != "33"))
  cat(sprintf("%-70s %d (informativo)\n", sprintf("%d: fichas com SG_UF = RJ sem código de município 33", ano), fora))
  um <- function(x) !is.na(x) & as.character(x) == "1"
  cf <- as.integer(as.character(rj$CLASSI_FIN)); crit_lab <- um(rj$CRITERIO)
  r2 <- c(
    sarscov2 = sum(cf %in% 5 & (crit_lab | um(rj$PCR_SARS2) | um(rj$AN_SARS2))),
    influenza = sum(cf %in% 1 & (crit_lab | um(rj$POS_PCRFLU) | um(rj$POS_AN_FLU))),
    vsr = sum(cf %in% 2 & (um(rj$PCR_VSR) | um(rj$AN_VSR)))
  )
  for (ag in names(r2)) conferir(sprintf("%d: casos R2 %s (bruto x casos_por_agente.csv)", ano, ag), r2[[ag]], cpa$casos[cpa$ano == ano & cpa$agente == ag])
}

# ---- 2. População direto do SIDRA e incidência do estado ------------------
sidra <- function(f) { j <- jsonlite::fromJSON(f)[-1, ]; stats::setNames(as.numeric(j$V), substr(j$D1C, 1, 6)) }
p22 <- sidra("dados/externos/sidra_4714_censo_2022_rj.json")
p24 <- sidra("dados/externos/sidra_6579_estimativa_2024_rj.json")
p25 <- sidra("dados/externos/sidra_6579_estimativa_2025_rj.json")
peso <- as.numeric(as.Date("2023-07-01") - as.Date("2022-08-01")) / as.numeric(as.Date("2024-07-01") - as.Date("2022-08-01"))
p23 <- round(p22 + peso * (p24[names(p22)] - p22))
est <- ler("resultados", "tabelas", "incidencia_estado.csv")
pop_ano <- list(`2022` = p22, `2023` = p23, `2024` = p24, `2025` = p25)
for (a in 2022:2025) {
  conferir(sprintf("%d: população do estado (SIDRA x incidencia_estado.csv)", a), sum(pop_ano[[as.character(a)]]), unique(est$populacao[est$ano == a]))
  for (ag in c("sarscov2", "influenza", "vsr")) {
    e <- est[est$ano == a & est$agente == ag, ]
    conferir(sprintf("%d: incidência %s pop. do ano", a, ag), e$casos / sum(pop_ano[[as.character(a)]]) * 1e5, e$incid_100k, 1e-6)
    conferir(sprintf("%d: incidência %s pop. 2024", a, ag), e$casos / sum(p24) * 1e5, e$incid_100k_pop2024, 1e-6)
  }
}
conferir("peso da interpolação de 2023 = 334/700", peso, 334 / 700, 1e-12)

# ---- 3. Vizinhança reconstruída pelos NOMES e Moran pela fórmula ----------
viz <- ler("resultados", "estatistica", "vizinhos_por_municipio.csv")
viz$cod6 <- as.character(viz$cod6)   # read.csv lê o código como número; a matriz é indexada por texto
nome_para_cod <- stats::setNames(viz$cod6, viz$nome)
n <- nrow(viz)
W <- matrix(0, n, n, dimnames = list(viz$cod6, viz$cod6))
for (i in seq_len(n)) {
  vizinhos <- trimws(strsplit(viz$vizinhos[i], ";")[[1]])
  W[viz$cod6[i], nome_para_cod[vizinhos]] <- 1 / length(vizinhos)   # estilo W, pela lista de nomes
}
conferir("vizinhança reconstruída: 456 ligações", sum(W > 0), 456)
conferir("vizinhança reconstruída é simétrica (A vizinho de B <=> B de A)", all((W > 0) == t(W > 0)), TRUE)
conferir("nenhum município vizinho de si mesmo", sum(diag(W)), 0)

lisa <- ler("resultados", "estatistica", "lisa_municipios.csv")
lisa$cod6 <- as.character(lisa$cod6)
glob <- ler("resultados", "estatistica", "moran_global.csv")
glob <- glob[glob$variavel == "incid_eb_100k" & glob$vizinhanca == "queen", ]
moran_formula <- function(x, W) { z <- x - mean(x); (length(z) / sum(W)) * sum(W * outer(z, z)) / sum(z^2) }
lisa_formula <- function(x, W) { z <- x - mean(x); m2 <- sum(z^2) / length(z); (z / m2) * as.vector(W %*% z) }
for (ag in c("sarscov2", "influenza", "vsr")) for (a in 2022:2025) {
  l <- lisa[lisa$agente == ag & lisa$ano == a, ]
  l <- l[match(viz$cod6, l$cod6), ]
  x <- l$valor
  conferir(sprintf("%s %d: Moran I pela fórmula (base R x spdep)", ag, a), moran_formula(x, W), glob$I[glob$agente == ag & glob$ano == a], 1e-9)
  conferir(sprintf("%s %d: LISA Ii pela fórmula, 92 municípios", ag, a), lisa_formula(x, W), l$Ii, 1e-9)
  z <- x - mean(x); lag <- as.vector(W %*% z)
  q <- ifelse(z >= 0, ifelse(lag >= 0, "HH", "HL"), ifelse(lag >= 0, "LH", "LL"))
  conferir(sprintf("%s %d: quadrantes", ag, a), q, l$quadrante)
  # Benjamini-Hochberg refeito à mão
  p <- l$p_perm; m <- length(p); o <- order(p, decreasing = TRUE)
  bh <- numeric(m); atual <- 1
  for (k in seq_along(o)) { atual <- min(atual, p[o[k]] * m / (m - k + 1)); bh[o[k]] <- atual }
  conferir(sprintf("%s %d: FDR (BH à mão x p_fdr)", ag, a), bh, l$p_fdr, 1e-12)
  conferir(sprintf("%s %d: nível confirmado/indicativo", ag, a),
           ifelse(bh < 0.05, "confirmado", ifelse(p < 0.05, "indicativo", "ns")), l$nivel)
}

# ---- 4. Hashes do manifesto conferidos fora do R do projeto -----------------
man <- readLines("dados/MANIFESTO.md", encoding = "UTF-8")
linhas <- grep("^\\| dados/", man, value = TRUE)
for (l in linhas) {
  campos <- trimws(strsplit(l, "|", fixed = TRUE)[[1]])[-1]
  conferir(paste("manifesto:", basename(campos[1])), digest::digest(file = campos[1], algo = "sha256"), campos[5])
}

cat("\nRESULTADO DA AUDITORIA INDEPENDENTE:", if (ok_total) "todas as conferências OK" else "HÁ DIVERGÊNCIAS", "\n")
if (!ok_total) quit(status = 1)
