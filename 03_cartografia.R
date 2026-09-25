# 03_cartografia.R — malha municipal do RJ em SIRGAS 2000 (CS-014)
#
#   dados/externos/RJ_Municipios_2022.zip      malha oficial do IBGE, no manifesto
#   dados/processados/municipios_rj.rds        sf com 92 municípios, EPSG:4674

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
