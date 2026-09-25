# 03_cartografia.R — malha municipal do RJ em SIRGAS 2000 (CS-014)
#
#   dados/externos/RJ_Municipios_2022.zip      malha oficial do IBGE, no manifesto
#   dados/processados/municipios_rj.rds        sf com 92 municípios, EPSG:4674
#   dados/brutos/geobr_healthregions_*.parquet tabela município → região (CS-030), no manifesto
#   dados/processados/regioes_saude_rj.rds     sf com 9 regiões de saúde, malha IBGE dissolvida
#   dados/processados/municipio_regiao.parquet cod6 → cod_regiao, regiao
#   dados/processados/indicadores_regionais.parquet  9 regiões × 3 agentes × 4 anos
#   resultados/tabelas/indicadores_regionais.csv     a mesma tabela, para leitura
#   dados/brutos/Leitos_*.csv|zip                    CNES, Hospitais e Leitos (CS-034), no manifesto
#   dados/processados/leitos_rj.parquet              leitos SUS e de UTI SUS de julho, 92 × 4 anos
#   resultados/tabelas/leitos_regionais.csv          leitos e taxa de SRAG por região de saúde

source("00_setup.R")

obter_malha_municipal()
municipios_rj <- ler_malha_municipal()

# A chave cod6 precisa casar com o SIVEP e com a população. Junção com 7 dígitos
# retornaria zero linhas sem erro; por isso o teste é contar as linhas.
populacao <- arrow::read_parquet(file.path("dados", "processados", "populacao_rj.parquet"))
casam <- sum(municipios_rj$cod6 %in% populacao$cod6[populacao$ano == 2022])
if (casam != nrow(municipios_rj)) {
  stop("Só ", casam, " de ", nrow(municipios_rj), " municípios casam com a população",
       call. = FALSE)
}

saveRDS(municipios_rj, file.path("dados", "processados", "municipios_rj.rds"))
message(sprintf("Malha: %d municípios, EPSG %d, %.1f km²; %d casam com a população",
                nrow(municipios_rj), sf::st_crs(municipios_rj)$epsg,
                sum(municipios_rj$area_km2), casam))

# ---- regiões de saúde (CS-030) ----
# A tabela vem do geobr; a geometria é a malha municipal acima, dissolvida.
obter_regioes_saude()
municipio_regiao <- ler_regioes_saude()
regioes_rj <- dissolver_regioes(municipios_rj, municipio_regiao)

indicadores <- as.data.frame(arrow::read_parquet(file.path("dados", "processados", "indicadores_municipais.parquet")))
indicadores_regionais <- agregar_por_regiao(indicadores, municipio_regiao)

# Contratos: 9 feições, 92 municípios distribuídos, grade 9 × 3 × 4, nenhum caso perdido.
stopifnot(nrow(regioes_rj) == 9, sum(regioes_rj$n_municipios) == nrow(municipios_rj),
          nrow(indicadores_regionais) == 9 * length(AGENTES) * length(ANOS_ESTUDO),
          sum(indicadores_regionais$casos) == sum(indicadores$casos),
          !anyNA(indicadores_regionais$incid_100k))

saveRDS(regioes_rj, file.path("dados", "processados", "regioes_saude_rj.rds"))
arrow::write_parquet(municipio_regiao, file.path("dados", "processados", "municipio_regiao.parquet"))
arrow::write_parquet(indicadores_regionais, file.path("dados", "processados", "indicadores_regionais.parquet"))
utils::write.csv(indicadores_regionais, file.path("resultados", "tabelas", "indicadores_regionais.csv"),
                 row.names = FALSE, fileEncoding = "UTF-8")
message(sprintf("Regiões de saúde: %d feições (%s municípios); grade regional %d linhas, %d casos",
                nrow(regioes_rj), paste(regioes_rj$n_municipios, collapse = "/"),
                nrow(indicadores_regionais), sum(indicadores_regionais$casos)))

# ---- leitos SUS do CNES (CS-034) ----
# Junção por NOME (os arquivos de 2022-2024 não trazem código IBGE): por isso vem
# depois da malha, que dá os nomes oficiais.
obter_leitos()
leitos <- montar_leitos(municipios_rj, populacao)
stopifnot(nrow(leitos) == nrow(municipios_rj) * length(ANOS_ESTUDO), !anyNA(leitos$leitos_sus_100k))
arrow::write_parquet(leitos, file.path("dados", "processados", "leitos_rj.parquet"))
leitos_reg <- resumir_leitos_regiao(leitos, municipio_regiao, indicadores_regionais)
utils::write.csv(leitos_reg, file.path("resultados", "tabelas", "leitos_regionais.csv"), row.names = FALSE, fileEncoding = "UTF-8")
message(sprintf("Leitos CNES (julho): %s leitos SUS no estado por ano; %d municípios sem leito SUS em %d",
                paste(tapply(leitos$leitos_sus, leitos$ano, sum), collapse = "/"),
                sum(leitos$leitos_sus == 0 & leitos$ano == max(ANOS_ESTUDO)), max(ANOS_ESTUDO)))
