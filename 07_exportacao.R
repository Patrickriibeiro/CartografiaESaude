# 07_exportacao.R — tabelas finais para planilha (CS-020)
#
#   resultados/tabelas/exportacao/indicadores_municipais.csv  92 × 3 × 4, com nome do município
#   resultados/tabelas/exportacao/lisa_municipios.csv         classe LISA por município, agente e ano
#   resultados/tabelas/exportacao/moran_global.csv            I e p, três rodadas (ADR-0004)
#   resultados/tabelas/exportacao/incidencia_estado.csv       série do estado, dois denominadores
#   resultados/tabelas/exportacao/indicadores_regionais.csv   9 regiões de saúde × 3 × 4 (CS-030)
#   resultados/tabelas/exportacao/moran_regional.csv          Moran global regional, descritivo (CS-030)
#   resultados/tabelas/exportacao/residencia_notificacao.csv  92 municípios, casos por residência e por notificação (CS-031)
#   resultados/tabelas/exportacao/serie_semanal.csv           casos por semana, estado e 9 regiões (CS-032)
#   resultados/tabelas/exportacao/nao_encerrados.csv          fichas não encerradas por ano (CS-035)
#   resultados/tabelas/exportacao/leitos_municipais.csv       leitos SUS e de UTI SUS de julho, 92 × 4 (CS-034)
#   resultados/tabelas/exportacao/spearman_leitos.csv         taxa × leitos, por ano, com IC (CS-034)
#   resultados/tabelas/exportacao/regioes_de_saude_municipios.csv  92 municípios e sua região (CS-050)
#   resultados/tabelas/exportacao/versoes_do_banco.csv        casos em cada versão do banco (CS-048)
#   resultados/tabelas/exportacao/tempo_ate_encerramento.csv  dias até encerrar a ficha, por ano (CS-048)
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
  taxa_padronizada_idade_100mil = round(ind$incid_pad_100k, 2),
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

r <- as.data.frame(arrow::read_parquet(file.path("dados", "processados", "indicadores_regionais.parquet")))
regional <- data.frame(
  codigo_regiao = r$cod_regiao, regiao_de_saude = r$regiao, municipios = r$n_municipios,
  agente = ROTULOS_AGENTE[r$agente], ano = r$ano, casos = r$casos, populacao = r$populacao,
  taxa_bruta_100mil = round(r$incid_100k, 2), taxa_bruta_pop2024_100mil = round(r$incid_100k_pop2024, 2),
  stringsAsFactors = FALSE, row.names = NULL
)
regional <- regional[order(regional$agente, regional$ano, regional$regiao_de_saude), ]

gr <- ml$regional
moran_reg <- data.frame(
  agente = ROTULOS_AGENTE[gr$agente], ano = gr$ano, regioes = gr$n, variavel = "taxa bruta",
  I_de_Moran = round(gr$I, 4), I_esperado_sem_padrao = round(gr$esperado_I, 4),
  p_permutacao = signif(gr$p_perm, 3), permutacoes = gr$nsim,
  stringsAsFactors = FALSE, row.names = NULL
)

rn <- utils::read.csv(file.path("resultados", "tabelas", "residencia_notificacao.csv"),
                      encoding = "UTF-8", colClasses = c(cod6 = "character"))
res_not <- data.frame(
  codigo_ibge = malha$cod7[match(rn$cod6, malha$cod6)], municipio = nomes[rn$cod6],
  casos_por_residencia = rn$casos_res, casos_por_notificacao = rn$casos_not,
  notificados_residentes_do_municipio = rn$not_mesmo_municipio,
  notificados_de_outro_municipio_rj = rn$not_de_outro_mun_rj,
  notificados_de_fora_do_rj = rn$not_de_fora_do_rj,
  residentes_notificados_fora_do_rj = rn$res_not_fora_do_rj,
  residentes_sem_municipio_de_notificacao = rn$res_sem_not,
  razao_notificacao_residencia = round(rn$razao_not_res, 3),
  saldo_notificacao_menos_residencia = rn$saldo,
  stringsAsFactors = FALSE, row.names = NULL
)

ss <- utils::read.csv(file.path("resultados", "tabelas", "serie_semanal.csv"), encoding = "UTF-8", stringsAsFactors = FALSE)
serie <- data.frame(recorte = ss$recorte, agente = ROTULOS_AGENTE[ss$agente], ano_epidemiologico = ss$ano_epi,
                    semana_epidemiologica = ss$semana_epi, inicio_da_semana = ss$inicio_semana, casos = ss$casos,
                    stringsAsFactors = FALSE, row.names = NULL)
ne <- utils::read.csv(file.path("resultados", "tabelas", "nao_encerrados.csv"))
nao_enc <- data.frame(ano = ne$ano, fichas_de_srag = ne$fichas, nao_encerradas = ne$nao_encerradas,
                      proporcao_pct = round(100 * ne$proporcao, 2), row.names = NULL)

lt <- as.data.frame(arrow::read_parquet(file.path("dados", "processados", "leitos_rj.parquet")))
leitos_exp <- data.frame(codigo_ibge = malha$cod7[match(lt$cod6, malha$cod6)], municipio = nomes[lt$cod6], ano = lt$ano,
                         estabelecimentos = lt$estabelecimentos, leitos_sus = lt$leitos_sus, leitos_uti_sus = lt$uti_sus,
                         populacao = lt$populacao, leitos_sus_100mil = round(lt$leitos_sus_100k, 2),
                         leitos_uti_sus_100mil = round(lt$uti_sus_100k, 2), stringsAsFactors = FALSE, row.names = NULL)
leitos_exp <- leitos_exp[order(leitos_exp$ano, leitos_exp$municipio), ]
spl <- utils::read.csv(file.path("resultados", "estatistica", "spearman_leitos.csv"), encoding = "UTF-8")
spearman_exp <- data.frame(ano = spl$ano, tipo_de_leito = spl$rotulo, municipios = spl$municipios,
                           rho_de_spearman = round(spl$rho, 3), ic95_inferior = round(spl$ic_inf, 3),
                           ic95_superior = round(spl$ic_sup, 3), reamostras_bootstrap = spl$reamostras,
                           stringsAsFactors = FALSE, row.names = NULL)

mr_exp <- as.data.frame(arrow::read_parquet(file.path("dados", "processados", "municipio_regiao.parquet")))
reg_mun <- data.frame(codigo_ibge = malha$cod7[match(mr_exp$cod6, malha$cod6)], municipio = nomes[mr_exp$cod6],
                      codigo_regiao = mr_exp$cod_regiao, regiao_de_saude = mr_exp$regiao,
                      stringsAsFactors = FALSE, row.names = NULL)
reg_mun <- reg_mun[order(reg_mun$regiao_de_saude, reg_mun$municipio), ]

vb <- utils::read.csv(file.path("resultados", "tabelas", "versoes_banco.csv"), encoding = "UTF-8", stringsAsFactors = FALSE)
versoes_exp <- data.frame(ano_do_banco = vb$ano, versao = vb$versao, dias_apos_fim_do_ano = vb$dias_apos_fim_do_ano,
                          versao_do_estudo = ifelse(vb$referencia, "sim", "não"), fichas = vb$fichas, encerradas = vb$encerradas,
                          casos_sarscov2 = vb$casos_sarscov2, casos_influenza = vb$casos_influenza, casos_vsr = vb$casos_vsr,
                          pct_fichas = round(vb$pct_fichas, 2), pct_casos_sarscov2 = round(vb$pct_casos_sarscov2, 2),
                          pct_casos_influenza = round(vb$pct_casos_influenza, 2), pct_casos_vsr = round(vb$pct_casos_vsr, 2),
                          stringsAsFactors = FALSE, row.names = NULL)
te <- utils::read.csv(file.path("resultados", "tabelas", "tempo_encerramento.csv"), encoding = "UTF-8")
tempo_exp <- data.frame(ano = te$ano, fichas = te$fichas, encerradas_com_data = te$encerradas_com_data,
                        dias_ate_encerrar_mediana = te$dias_encerramento_mediana, dias_ate_encerrar_p90 = te$dias_encerramento_p90,
                        pct_encerradas_ate_30_dias = round(te$pct_encerradas_30d, 1), pct_encerradas_ate_60_dias = round(te$pct_encerradas_60d, 1),
                        pct_encerradas_ate_90_dias = round(te$pct_encerradas_90d, 1), dias_ate_digitar_mediana = te$dias_digitacao_mediana,
                        row.names = NULL)

pasta <- file.path("resultados", "tabelas", "exportacao")
arquivos <- c(
  salvar_resultado(indicadores, "indicadores_municipais", pasta),
  salvar_resultado(lisa, "lisa_municipios", pasta),
  salvar_resultado(moran, "moran_global", pasta),
  salvar_resultado(estado, "incidencia_estado", pasta),
  salvar_resultado(regional, "indicadores_regionais", pasta),
  salvar_resultado(moran_reg, "moran_regional", pasta),
  salvar_resultado(res_not, "residencia_notificacao", pasta),
  salvar_resultado(serie, "serie_semanal", pasta),
  salvar_resultado(nao_enc, "nao_encerrados", pasta),
  salvar_resultado(leitos_exp, "leitos_municipais", pasta),
  salvar_resultado(spearman_exp, "spearman_leitos", pasta),
  salvar_resultado(reg_mun, "regioes_de_saude_municipios", pasta),
  salvar_resultado(versoes_exp, "versoes_do_banco", pasta),
  salvar_resultado(tempo_exp, "tempo_ate_encerramento", pasta),
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
          nrow(ler_resultado(arquivos[5])) == 108, nrow(ler_resultado(arquivos[6])) == 12,
          nrow(ler_resultado(arquivos[7])) == 92,
          nrow(ler_resultado(arquivos[8])) == 10 * 3 * nrow(semanas_do_estudo()),
          nrow(ler_resultado(arquivos[9])) == length(ANOS_ESTUDO),
          nrow(ler_resultado(arquivos[10])) == 92 * length(ANOS_ESTUDO), nrow(ler_resultado(arquivos[11])) == 2 * length(ANOS_ESTUDO),
          nrow(ler_resultado(arquivos[12])) == 92,
          nrow(ler_resultado(arquivos[14])) == length(ANOS_ESTUDO),
          "Baía da Ilha Grande" %in% ler_resultado(arquivos[5])$regiao_de_saude,
          "Niterói" %in% ler_resultado(arquivos[1])$municipio)
message(sprintf("%d arquivos em %s", length(arquivos), pasta))
