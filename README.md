# Cartografia & Saúde — SRAG no Estado do Rio de Janeiro (2022–2025)

[![testes](https://github.com/Patrickriibeiro/CartografiaESaude/actions/workflows/testes.yml/badge.svg)](https://github.com/Patrickriibeiro/CartografiaESaude/actions/workflows/testes.yml)

Pipeline reprodutível em R para a análise espaço-temporal da incidência de Síndrome
Respiratória Aguda Grave (SRAG) por SARS-CoV-2, influenza e VSR nos 92 municípios do
Estado do Rio de Janeiro, com dados abertos do SIVEP-Gripe e do IBGE: do download ao mapa,
com Moran global e LISA, painel interativo e relatório.

Projeto de Gabrielle Barbosa Teixeira Coelho (PPG-BCS, IOC/Fiocruz), disciplina
Cartografia & Saúde (IOC 14090), com Patrick Ribeiro Oliveira.

## Rodar numa máquina nova

Testado do zero num clone limpo (ver `docs/release-history/cs-024-maquina-nova.md`).

**1. Instale**

- **R ≥ 4.6** — <https://cran.r-project.org/>. No Windows, os pacotes vêm compilados; o
  Rtools não é necessário.
- **Quarto ≥ 1.10** — <https://quarto.org/docs/get-started/>. Só para o relatório; o resto
  roda sem ele.
- **Git** — para clonar.

**2. Clone e restaure os pacotes** (na primeira vez, baixa ~140 pacotes nas versões exatas
do `renv.lock`). **No Windows, clone numa pasta de caminho curto**, como `C:\Projetos\`: o
`renv` instala pacotes em subpastas fundas e, a partir de ~150 caracteres de caminho, o
limite de 260 caracteres do Windows faz a instalação falhar (visto na auditoria final).

```bash
git clone https://github.com/Patrickriibeiro/CartografiaESaude.git
cd CartografiaESaude
Rscript -e "renv::restore(prompt = FALSE)"
```

**3. Rode os testes** (não usam rede nem os dados reais; os de integração são pulados até o
passo 4)

```bash
Rscript -e "testthat::test_dir('tests/testthat')"
```

**4. Rode o pipeline** (na primeira vez baixa ~115 MB do Portal de Dados Abertos do SUS e
~21 MB da tabela de regiões de saúde do geobr, e
confere cada arquivo pelo SHA-256 do manifesto)

```bash
Rscript run.R                  # tudo, inclusive o relatório
Rscript run.R --sem-relatorio  # sem Quarto
Rscript run.R --limpar         # apaga o que é derivado e refaz do zero
```

Tempo medido: ~120–140 s com os dados já baixados; o tempo de cada etapa fica em
`resultados/execucao.log`. Para conferir os resultados por um caminho independente do
pipeline (sem o `spdep` nem as funções de `R/`), rode `Rscript tests/auditoria_independente.R`.

**5. Abra o painel**

```bash
Rscript -e "shiny::runApp(launch.browser = TRUE)"
```

## O que sai

| Onde | O quê |
|---|---|
| `08_relatorio.html` | Relatório autocontido (um arquivo; nenhum número digitado à mão) |
| `08_apresentacao.html` | Apresentação (revealjs) do mesmo fonte |
| `resultados/mapas/` | 12 mapas de incidência, 12 de LISA, 2 painéis e 12 mapas por região de saúde (300 dpi) |
| `resultados/tabelas/exportacao/` | 7 CSV para Excel em português (municípios, regiões de saúde, residência × notificação) + LEIA-ME com a versão dos dados |
| `resultados/estatistica/` | Moran global, LISA por município, vizinhança |
| `app.R` | Painel Shiny + leaflet |

## Documentos

| Arquivo | O que é |
|---|---|
| `docs/proposta-v2.md` | Proposta revisada, com as decisões da autora |
| `docs/decisoes/ADR-*.md` | Cada decisão metodológica, com a evidência e as alternativas |
| `docs/trilha-desenvolvimento.md` | Arquitetura, contratos entre etapas e fases |
| `docs/BACKLOG.md` | O que foi feito (com commit) e o que falta |
| `docs/dicionario-sivep.md` | Os 37 campos do SIVEP-Gripe usados, conferidos contra os bancos |
| `dados/MANIFESTO.md` | Cada arquivo externo com URL, data, tamanho e SHA-256 |

## Estrutura

```
00_setup.R … 07_exportacao.R   etapas do pipeline, em ordem (run.R executa todas)
08_relatorio.qmd               relatório e apresentação (Quarto)
app.R                          painel Shiny + leaflet
R/funcoes_*.R                  funções usadas pelas etapas, com testes
config/fontes.yml              endereços das fontes (fora do código)
dados/brutos/                  bancos do SIVEP e regiões de saúde baixados (fora do git; conferidos pelo manifesto)
dados/externos/                dicionário, malha e população do IBGE (no git)
dados/processados/             tabelas intermediárias (fora do git; regeneráveis)
resultados/                    tabelas, estatística, mapas
tests/testthat/                testes automatizados e base sintética FABRICADA
```

Os microdados de saúde não são versionados: são grandes e, embora anonimizados pelo
Ministério da Saúde, o projeto só publica agregados por município.

## Licença

Código sob a licença MIT (`LICENSE`); relatório, mapas e tabelas sob CC-BY 4.0
(`LICENSE-CONTEUDO.md`). Para citar, veja `CITATION.cff`.
