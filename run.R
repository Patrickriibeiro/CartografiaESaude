# run.R — executa o pipeline inteiro, em ordem, parando no primeiro erro (CS-023)
#
# Uso, da raiz do projeto:
#   Rscript run.R                  roda tudo (usa o cache de dados baixados)
#   Rscript run.R --limpar         apaga as saídas derivadas antes e refaz do zero
#   Rscript run.R --sem-relatorio  pula o Quarto (máquina sem Quarto instalado)
#
# Tempo de cada etapa em resultados/execucao.log.

for (arquivo in list.files("R", pattern = "^funcoes_.*\\.R$", full.names = TRUE)) {
  source(arquivo, encoding = "UTF-8")
}

argumentos <- commandArgs(trailingOnly = TRUE)
if ("--limpar" %in% argumentos) {
  message("Apagando saídas derivadas (brutos e externos ficam: são cache conferido pelo manifesto)")
  message(limpar_derivados(), " arquivos apagados")
}

etapas <- list(
  "01_etl_sivep.R"       = etapa_script("01_etl_sivep.R"),
  "02_indicadores.R"     = etapa_script("02_indicadores.R"),
  "03_cartografia.R"     = etapa_script("03_cartografia.R"),
  "04_pesos_espaciais.R" = etapa_script("04_pesos_espaciais.R"),
  "05_moran_lisa.R"      = etapa_script("05_moran_lisa.R"),
  "06_visualizacoes.R"   = etapa_script("06_visualizacoes.R"),
  "07_exportacao.R"      = etapa_script("07_exportacao.R")
)
if (!"--sem-relatorio" %in% argumentos) etapas[["08_relatorio.qmd"]] <- etapa_relatorio()

log <- executar_etapas(etapas)
message(sprintf("Pipeline concluído: %d etapas em %.0f s (resultados/execucao.log)",
                nrow(log), sum(log$segundos)))
