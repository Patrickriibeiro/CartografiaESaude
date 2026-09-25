# CS-001 + CS-002 — Ambiente R e esqueleto do repositório

- **Data:** 2026-09-25
- **Modelo · esforço:** Opus · low (acordado com o dono)
- **Itens:** CS-001, CS-002 · ADR-0005 (itens 1 e 2)

## Verificação com número

| Critério de aceite | Resultado |
|---|---|
| `Rscript` imprime versão | R 4.6.1 (2026-06-24 ucrt) |
| `quarto --version` | 1.10.18 |
| 9 pacotes do CS-001 carregam | **9/9**: sf 1.1.3, spdep 1.4.2, arrow 25.0.1, geobr 2.1.0, sidrar 0.5.1, shiny 1.14.0, leaflet 2.2.3, testthat 3.3.2, renv 1.2.4 |
| Bibliotecas geoespaciais do `sf` | GEOS 3.14.1, GDAL 3.12.1, PROJ 9.7.1 |
| `renv.lock` existe | 140 pacotes, R 4.6.1 |
| `renv::status()` limpo | "No issues found" |
| Árvore idêntica ao PDF | 8 scripts `00`–`07`, `run.R`, `app.R`, `08_relatorio.qmd`, `_quarto.yml`, 6 `R/funcoes_*.R`, 4 pastas de dados, 4 de resultados, `tests/testthat` |
| Testes do esqueleto | **5/5 expectativas em 1 arquivo**, 0 falhas |
| Primeiro commit | `b66ae13`, 44 arquivos; nenhum de `renv/library/` nem de `dados/brutos/` |

## O que ficou de fora e por quê

- **Rtools não instalado.** O winget só oferece Rtools 4.5, incompatível com R 4.6, e
  nenhum dos 140 pacotes precisou compilar (0 menções a compilação no log). Instalar
  quando um pacote exigir.
- **Editor (RStudio/Positron) não instalado.** Escolha pessoal do dono; não afeta o
  pipeline.

## Erros do caminho

1. `winget install RProject.R` baixou e verificou o hash, mas falhou ao iniciar o
   instalador com `0x800401f5 : Application not found`. Resolvido executando o mesmo
   instalador baixado (hash `C5424C40…C2DF`) com parâmetros silenciosos do Inno Setup e
   `/CURRENTUSER`. Instalou em `%LOCALAPPDATA%\Programs\R\R-4.6.1` sem administrador.
2. `Rscript -e '<várias linhas>'` no Windows executa só a primeira linha do argumento.
   Como a primeira estava vazia, o comando "terminou com sucesso" sem fazer nada. Regra
   daqui em diante: código R de mais de uma linha vai em arquivo `.R`.

## Pendências registradas

- O PDF da proposta está versionado. Antes de tornar o repositório público (CS-026,
  D-01), a autora decide se ele fica.
