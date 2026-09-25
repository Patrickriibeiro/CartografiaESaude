# 07_exportacao.R — tabelas finais para planilha (CS-020)
#
#   resultados/tabelas/exportacao/indicadores_municipais.csv  92 × 3 × 4, com nome do município
#   resultados/tabelas/exportacao/lisa_municipios.csv         classe LISA por município, agente e ano
#   resultados/tabelas/exportacao/moran_global.csv            I e p, três rodadas (ADR-0004)
#   resultados/tabelas/exportacao/incidencia_estado.csv       série do estado, dois denominadores
#   resultados/tabelas/exportacao/LEIA-ME.txt                 carimbo: data, commit, versões dos dados

source("00_setup.R")

malha <- readRDS(file.path("dados", "processados", "municipios_rj.rds"))
ind <- as.data.frame(arrow::read_parquet(file.path("dados", "processados", "indicadores_municipais.parquet")))
ml <- readRDS(file.path("resultados", "estatistica", "moran_lisa.rds"))
nomes <- stats::setNames(malha$nome, malha$cod6)

indicadores <- data.frame(
  codigo_ibge = malha$cod7[match(ind$cod6, malha$cod6)],
  municipio = nomes[ind$cod6],
  agente = ROTULOS_AGENTE[ind$agente],
  ano = ind$ano,
  casos = ind$casos,
  populacao = ind$populacao,
  fonte_populacao = ind$fonte_populacao,
  taxa_bruta_100mil = round(ind$incid_100k, 2),
  taxa_bruta_pop2024_100mil = round(ind$incid_100k_pop2024, 2),
  taxa_suavizada_100mil = round(ind$incid_eb_100k, 2),
  stringsAsFactors = FALSE, row.names = NULL
)
indicadores <- indicadores[order(indicadores$agente, indicadores$ano, indicadores$municipio), ]

l <- ml$principal$lisa
lisa <- data.frame(
  codigo_ibge = malha$cod7[match(l$cod6, malha$cod6)],
  municipio = nomes[l$cod6],
  agente = ROTULOS_AGENTE[l$agente],
  ano = l$ano,
  taxa_suavizada_100mil = round(l$valor, 2),
  quadrante = NOMES_QUADRANTE[l$quadrante],
  nivel = l$nivel,
  categoria = as.character(categoria_lisa(l$quadrante, l$nivel)),
  p_permutacao = signif(l$p_perm, 3),
  p_corrigido_fdr = signif(l$p_fdr, 3),
  um_unico_vizinho = ifelse(l$instavel, "sim", "não"),
  stringsAsFactors = FALSE, row.names = NULL
)
lisa <- lisa[order(lisa$agente, lisa$ano, lisa$municipio), ]

g <- rbind(ml$principal$global, ml$bruta$global, ml$rook$global)
moran <- data.frame(
  agente = ROTULOS_AGENTE[g$agente], ano = g$ano,
  variavel = ifelse(g$variavel == "incid_eb_100k", "taxa suavizada", "taxa bruta"),
  vizinhanca = g$vizinhanca, I_de_Moran = round(g$I, 4), p_permutacao = signif(g$p_perm, 3),
  permutacoes = g$nsim, stringsAsFactors = FALSE, row.names = NULL
)

e <- utils::read.csv(file.path("resultados", "tabelas", "incidencia_estado.csv"), encoding = "UTF-8")
estado <- data.frame(
  agente = ROTULOS_AGENTE[e$agente], ano = e$ano, casos = e$casos, populacao = e$populacao,
  taxa_100mil = round(e$incid_100k, 2), taxa_pop2024_100mil = round(e$incid_100k_pop2024, 2),
  stringsAsFactors = FALSE, row.names = NULL
)

pasta <- file.path("resultados", "tabelas", "exportacao")
arquivos <- c(
  salvar_resultado(indicadores, "indicadores_municipais", pasta),
  salvar_resultado(lisa, "lisa_municipios", pasta),
  salvar_resultado(moran, "moran_global", pasta),
  salvar_resultado(estado, "incidencia_estado", pasta),
  escrever_carimbo(pasta, c(
    sprintf("Contagens pequenas (CS-043): %d combinações município x agente x ano têm de 1 a %d casos.",
            sum(ind$casos >= 1 & ind$casos < LIMIAR_CONTAGEM_PEQUENA), LIMIAR_CONTAGEM_PEQUENA - 1L),
    "Publicadas sem supressão: o microdado de origem já é público e anonimizado pelo Ministério da Saúde.",
    "Ao republicar em outro contexto, avalie a regra local de supressão de contagens pequenas."
  ))
)

# Conferência: cada CSV relido tem as mesmas linhas e os acentos intactos.
stopifnot(nrow(ler_resultado(arquivos[1])) == 1104, nrow(ler_resultado(arquivos[2])) == 1104,
          nrow(ler_resultado(arquivos[3])) == 36, nrow(ler_resultado(arquivos[4])) == 12,
          "Niterói" %in% ler_resultado(arquivos[1])$municipio)
message(sprintf("%d arquivos em %s", length(arquivos), pasta))
