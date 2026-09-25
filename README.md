# Cartografia & Saúde — SRAG no Estado do Rio de Janeiro (2022–2025)

Pipeline reprodutível em R para a análise espaço-temporal da incidência de Síndrome
Respiratória Aguda Grave (SRAG) por SARS-CoV-2, Influenza e VSR nos 92 municípios do
Estado do Rio de Janeiro, com dados abertos do SIVEP-Gripe e do IBGE.

Projeto de Gabrielle Barbosa Teixeira Coelho (PPG-BCS, IOC/Fiocruz), disciplina
Cartografia & Saúde (IOC 14090).

> **Estado:** esqueleto (CS-002). Os scripts numerados ainda param com
> "não implementado". A ordem de implementação está em `docs/BACKLOG.md`.

## Documentos

| Arquivo | O que é |
|---|---|
| `23092026_ Seminário…pdf` | Proposta original (v1), documento de referência |
| `docs/proposta-v2.md` | Revisão da proposta com correções factuais, aguardando aceite da autora |
| `docs/trilha-desenvolvimento.md` | Arquitetura técnica, contratos entre etapas, fases |
| `docs/BACKLOG.md` | Fonte única de feito/não feito (itens `CS-0NN`) |
| `docs/decisoes/` | ADRs: decisões registradas e o motivo |

## Pré-requisitos

- R ≥ 4.6 (verificado com 4.6.1)
- Quarto ≥ 1.10 (verificado com 1.10.18), para o relatório
- Rtools só se algum pacote precisar ser compilado; com os binários do CRAN não foi necessário

## Como rodar

```r
# 1. Restaurar exatamente as versões de pacotes do renv.lock
renv::restore()

# 2. Rodar os testes
testthat::test_dir("tests/testthat")

# 3. Rodar o pipeline inteiro (quando implementado)
source("run.R")
```

## Estrutura

```
00_setup.R … 07_exportacao.R   etapas do pipeline, em ordem
run.R                          executa todas as etapas
app.R                          painel Shiny + leaflet
08_relatorio.qmd               relatório e apresentação (Quarto)
R/funcoes_*.R                  funções usadas pelas etapas
dados/brutos/                  downloads originais (fora do git)
dados/processados/             tabelas limpas (.parquet, .rds)
resultados/                    tabelas, mapas, estatística, objetos
tests/testthat/                testes automatizados
```

Dados brutos não são versionados: são microdados de saúde e são grandes. Cada arquivo
baixado é registrado com URL, data e hash SHA-256 em `dados/MANIFESTO.md` (CS-003).
