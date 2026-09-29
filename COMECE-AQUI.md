# Comece aqui — rodar o projeto do zero

Para chegar ao resultado você **não precisa entender todas as pastas**: são 3 passos. O resto
deste guia é o mapa para quando quiser entender o que cada coisa faz.

## 1. Antes: onde colocar a pasta

Descompacte (ou clone) numa pasta de **caminho curto**, como `C:\Projetos\`, e não em
Downloads nem na Área de Trabalho. O Windows limita o tamanho dos caminhos a 260 caracteres,
e o renv (explicado abaixo) instala pacotes em subpastas fundas: num caminho longo a
instalação falha no meio. Mantenha **uma cópia só** da pasta.

Instale antes: **R 4.6** (cran.r-project.org) e **Quarto** (quarto.org; só para o relatório).

## 2. Os 3 passos

1. **Abra o projeto:** dê dois cliques em `CartografiaESaude.Rproj`. O RStudio abre já dentro
   da pasta certa e liga o renv sozinho (no Console aparece uma mensagem do renv).
2. **Instale os pacotes (só na primeira vez; demora):** no Console,
   ```r
   renv::restore(prompt = FALSE)
   ```
3. **Rode tudo:**
   ```r
   source("run.R")
   ```
   Na primeira vez ele baixa os bancos do SIVEP-Gripe (~115 MB), a tabela de regiões e os
   leitos do CNES, e confere cada arquivo. Os resultados saem em `resultados/`, e o relatório em
   `08_relatorio.html`.

Sem RStudio: abra um terminal nesta pasta e rode `Rscript -e "renv::restore(prompt = FALSE)"`
e depois `Rscript run.R`.

Se der erro, guarde a **última mensagem em vermelho** do Console: é ela que diz o que faltou.

## 3. O que é o renv (e por que a pasta cresce)

O renv é o "congelador de pacotes" do projeto. O arquivo `renv.lock` lista cada pacote R na
versão exata usada na análise, e o `renv::restore()` instala **essas** versões numa biblioteca
só deste projeto (`renv/library/`), sem mexer nos pacotes que você já tem. Resolve o problema de
"na minha máquina deu outro número porque meu pacote é de outra versão". Depois do passo 2 a
pasta `renv/` fica grande: é normal, não é bagunça. O arquivo `.Rprofile` é o que liga o renv
toda vez que o R abre nesta pasta; por isso o passo 1 importa.

## 4. A ordem das etapas

O `run.R` chama tudo na ordem certa. Cada etapa lê o que a anterior gravou; para acompanhar
passo a passo, abra e rode os scripts nesta ordem:

| Etapa | O que faz |
|---|---|
| `01_etl_sivep.R` | baixa os bancos do SIVEP-Gripe, filtra o RJ e classifica os casos por vírus |
| `02_indicadores.R` | casos e taxas por município, vírus e ano (população do IBGE, padronização por idade) |
| `03_cartografia.R` | malha dos 92 municípios (IBGE) |
| `04_pesos_espaciais.R` | quem é vizinho de quem (vizinhança Queen) |
| `05_moran_lisa.R` | estatística espacial: Moran global e LISA |
| `06_visualizacoes.R` | mapas e gráficos |
| `07_exportacao.R` | tabelas para Excel, tabelas ABNT e a proposta em Word |
| `08_relatorio.qmd` | relatório e apresentação (Quarto) |

O `00_setup.R` é carregado por todas as etapas: não precisa rodá-lo sozinho.

## 5. Mapa das pastas

**Para rodar (não mexa):**

| Pasta ou arquivo | Para quê |
|---|---|
| `R/` | as funções que as etapas usam, uma por tema |
| `config/fontes.yml` | endereço e versão de cada fonte de dados |
| `dados/externos/`, `dados/MANIFESTO.md` | arquivos públicos do IBGE e a impressão digital (SHA-256) de cada arquivo baixado |
| `renv/`, `renv.lock`, `.Rprofile` | os pacotes congelados (seção 3) |
| `docs/proposta-v2.md`, `docs/decisoes/` | lidos pela etapa 07 e pelo relatório |
| `_quarto.yml`, `referencias.bib` | configuração e referências do relatório |

**Gerado pelo pipeline (pode apagar; volta com `source("run.R")`):**
`dados/brutos/`, `dados/intermediarios/`, `dados/processados/` (os microdados ficam só
aqui, nunca vão para o git), `resultados/`, `08_relatorio.html`, `08_apresentacao.html`.

**Para ler, não para rodar:**
`docs/historia-do-projeto.md` (a história da construção, contada do zero, sem presumir que você
sabe programar: cada pasta e arquivo, por que existe e o que produz),
`README.md` (detalhes técnicos), `docs/` (proposta, notas metodológicas, decisões, backlog),
`tests/` (testes automáticos: `testthat::test_dir("tests/testthat")`), `app.R` (painel
interativo, opcional: `shiny::runApp()`), `LICENSE`, `CITATION.cff`.
