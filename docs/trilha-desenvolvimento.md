# Trilha de desenvolvimento — Cartografia & Saúde (SRAG-RJ 2022–2025)

Documento técnico vivo. Criado em 2026-09-25 a partir da análise do PDF
`23092026_ Seminário Cartografia & Saúde (IOC14090).pdf` (proposta de Gabrielle Barbosa
Teixeira Coelho, mestranda do PPG-BCS, IOC/Fiocruz).

**Atualização 2026-09-25 (mesmo dia):** existe agora `docs/proposta-v2.md`, revisão da
proposta com as correções factuais, hipóteses, objetivos mensuráveis e fontes ampliadas.
Enquanto a mestranda não aceitar a v2 (decisão D-10 no BACKLOG), o PDF v1 continua sendo
a referência; os itens CS-030 a CS-035 ficam condicionados.

**Regra constitucional:** o PDF é o documento de referência. Onde o código divergir dele,
o PDF vence até que exista uma decisão registrada em `docs/decisoes/ADR-00NN.md`.
Onde o PDF estiver **factualmente errado** (há cinco casos verificados abaixo), a
correção também passa por ADR, porque a mestranda precisa saber o que mudou e por quê.

> **ADR** = *Architecture Decision Record*, um arquivo curto que registra uma decisão,
> o contexto e as alternativas descartadas. Serve para que daqui a seis meses ninguém
> pergunte "por que o código faz isso?" sem ter resposta.

---

## 1. O que o PDF pede (leitura fiel)

| Item | Conteúdo do PDF |
|---|---|
| Pergunta | Como as taxas de incidência de SRAG por SARS-CoV-2, Influenza A/B e VSR se distribuem entre os 92 municípios do RJ e onde estão os *hotspots* regionais? |
| Desenho | Estudo ecológico, exploratório, espaço-temporal, 2022–2025 |
| Fonte epidemiológica | SIVEP-Gripe via OpenDataSUS (fichas de SRAG hospitalizada) |
| Fonte demográfica | Censo 2022 + estimativas intercensitárias do IBGE |
| Fonte cartográfica | Malhas municipais via `geobr`, SIRGAS 2000 (EPSG:4674) |
| Filtro espacial | `CO_MUNIC_RES` com prefixo 33 (o PDF usa este nome; o nome real é outro, ver §2.2) |
| Filtro temporal | `DT_SIN_PRI` ou `DT_NOTIFIC`, agregação quadrimestral e anual |
| Critério de caso | `CLASSI_FIN` + confirmação laboratorial (RT-PCR ou antígeno) por vírus |
| Indicador | Incidência acumulada por 100 mil habitantes, por município e ano |
| Estatística espacial | Contiguidade Queen 1ª ordem → Moran Global (Monte Carlo, p<0,05) → LISA em 4 classes |
| Produtos | (a) pipeline em scripts R numerados + `R/funcoes_*.R`; (b) painel Shiny + leaflet com filtros vírus × ano; (c) relatório e apresentação Quarto; (d) repositório GitHub público |
| Exclusões explícitas | Sensoriamento remoto, GEE, GPS, Random Forest, métricas de paisagem, fuzzy, redes neurais |

Seções **vazias** no PDF (a serem preenchidas depois que o pipeline gerar números):
1.1, 1.2, 4.1–4.5, 5.1–5.3, 6 e Apêndice A. Isso significa que o código é insumo do
texto científico, não o contrário. A ordem de entrega tem de respeitar isso (ver §5).

> **SRAG** = Síndrome Respiratória Aguda Grave. É o caso grave (geralmente internado) de
> infecção respiratória. O SIVEP-Gripe só registra SRAG hospitalizada e óbitos, então
> as "taxas de incidência" deste projeto medem **doença grave**, não infecção.
> Isso precisa aparecer no relatório, senão o leitor compara com dados de casos leves.

---

## 2. Achados da análise inicial (verificados em 2026-09-25)

Cada achado traz a evidência de onde foi confirmado. Os cinco primeiros são erros
factuais do PDF que, se implementados como escritos, quebram o pipeline em silêncio.

### 2.1 `microdatasus` não baixa o SIVEP-Gripe (bloqueante)

O PDF diz três vezes que a extração é "via pacote microdatasus". A documentação oficial
de `fetch_datasus()` lista SIH, SIM, SINASC, CNES, SIA e SINAN, e **não** lista
SIVEP-Gripe nem SRAG. O motivo é estrutural: o `microdatasus` lê arquivos `.dbc` do
FTP do DATASUS; o SIVEP-Gripe é distribuído como CSV/PARQUET no portal de dados
abertos, outro canal.

**Consequência:** `baixar_sivep()` será escrita com download HTTP direto do portal
`dadosabertos.saude.gov.br/dataset/srag-2019-a-2026`. Vira o ADR-0001.

Evidência: https://rfsaldanha.github.io/microdatasus/reference/fetch_datasus.html

### 2.2 Nomes de campos do PDF não existem no dicionário oficial

Conferido no dicionário de dados do SIVEP-Gripe (versão SES-SP do dicionário do
Ministério, 37 páginas):

| No PDF | No dicionário | Observação |
|---|---|---|
| `CO_MUNIC_RES` | `CO_MUN_RES` | `Varchar2(6)` — **6 dígitos**, não 7 |
| `PCR_FLU` | `POS_PCRFLU` (1-Sim/2-Não/9-Ign) + `TP_FLU_PCR` (1-A/2-B) | Influenza é dois campos |
| `PCR_SARS2` | `PCR_SARS2` (1-marcado / vazio) | correto |
| `PCR_VSR` | `PCR_VSR` (1-marcado / vazio) | correto |
| *(antígeno não nomeado)* | `RES_AN`, `POS_AN_FLU`, `TP_FLU_AN`, `AN_SARS2`, `AN_VSR` | o PDF cita teste rápido mas não os campos |
| `CLASSI_FIN` | 1-influenza · 2-outro vírus resp. · 3-outro agente · 4-não especificado · 5-covid-19 | VSR cai em **2**, não tem código próprio |

**Consequência para o join:** o `geobr` entrega `code_muni` com 7 dígitos (o sétimo é
dígito verificador). Para casar com `CO_MUN_RES` é preciso `substr(code_muni, 1, 6)`.
Fazer o join direto retorna **zero linhas** sem erro. Este é o tipo de falha silenciosa
que exige um teste: `nrow(join) == 92`.

### 2.3 Não existe estimativa populacional do IBGE para 2023

Consulta à API SIDRA (tabela 6579, população estimada) para o município do Rio:
existem 2001–2021, **2024, 2025 e 2026**. Faltam **2022** (ano censitário, está na
tabela 4714 do Censo) e **2023** (o IBGE não publicou estimativa nesse ano por causa
da divulgação do Censo).

**Consequência:** o denominador de 2023 exige decisão. Opções: (a) repetir o Censo
2022; (b) interpolar linearmente entre 2022 e 2024; (c) usar a projeção retroativa do
IBGE quando existir. Vira o ADR-0003. A opção (b) é a recomendada por manter a taxa
comparável entre anos, mas é a mestranda quem decide, porque aparece na metodologia.

Evidência: `apisidra.ibge.gov.br/values/t/6579/n6/3304557/v/9324/p/all` e `t/4714`.

### 2.4 O banco de 2025 é "vivo" e muda toda semana

O portal marca 2019–2024 como bancos congelados e 2025–2026 como bancos vivos com
atualização semanal (última em 2026-09-14). Um pipeline "reprodutível" que baixa o
2025 hoje e o baixa de novo daqui a um mês produz mapas diferentes.

**Consequência:** o projeto precisa de um **manifesto de proveniência**: URL, data do
download, tamanho e hash SHA-256 de cada arquivo bruto, gravados em
`dados/MANIFESTO.md`. O relatório cita a data do snapshot. Sem isso não há
reprodutibilidade, só re-execução.

> **Hash SHA-256** = uma "impressão digital" de 64 caracteres calculada sobre o
> conteúdo do arquivo. Se um byte mudar, o hash muda. Serve para provar que o arquivo
> analisado é o mesmo que foi baixado.

### 2.5 "Por bairro" (4.2) contradiz o desenho municipal

O título da seção 4.2 diz "Taxas de Incidência por Bairro", mas todo o resto do PDF
trabalha com 92 municípios. O SIVEP não tem bairro estruturado para o estado inteiro.
Tratar como erro de digitação e registrar no ADR-0005 (escopo).

### 2.6 Co-detecção: um caso pode ser positivo para dois vírus

`PCR_SARS2`, `PCR_VSR` e `POS_PCRFLU` são campos independentes marcáveis na mesma
ficha. Se o pipeline contar "casos" somando positivos por vírus, um paciente com
SARS-CoV-2 + VSR conta duas vezes. Isso é **correto** se o indicador é "incidência de
SRAG por agente" (cada vírus tem sua própria taxa) e **errado** se for "incidência de
SRAG total". O ADR-0002 (critério de caso) precisa dizer qual dos dois o projeto usa e
o relatório precisa informar quantas co-detecções houve.

### 2.7 Semântica de `CLASSI_FIN` vs resultado laboratorial

`CLASSI_FIN` é a classificação **final** da vigilância, preenchida no encerramento do
caso. Casos ainda abertos têm o campo vazio, e isso é mais frequente nos dados
recentes (maturação da notificação). Um projeto de análise sobre o repositório
`srag-intelligence-agent` mediu esse efeito no campo `EVOLUCAO` variando de 22,65 % a
4,57 % de ausentes conforme a idade do registro. O mesmo vale para `CLASSI_FIN`.

Duas estratégias possíveis, ambas defensáveis:
- **Estrita:** `CLASSI_FIN == 5` para COVID, `== 1` para Influenza, `== 2 & (PCR_VSR==1 | AN_VSR==1)` para VSR.
- **Laboratorial:** ignorar `CLASSI_FIN` e usar apenas os campos de PCR/antígeno.

A estrita perde casos não encerrados; a laboratorial pode incluir resultados que a
vigilância depois descartou. O PDF diz "casos encerrados como SRAG por agente viral
com confirmação por RT-PCR ou antígeno", ou seja, **as duas condições juntas** (a
estrita, com confirmação laboratorial obrigatória). É o ponto de partida do ADR-0002;
o relatório deve quantificar quantos casos cada regra inclui.

### 2.8 Pequenos números e o problema da unidade de área modificável

Municípios como Macuco (~5 mil hab.) produzem taxas instáveis: 3 casos viram 60 por
100 mil. LISA sobre taxa bruta pode marcar *hotspot* onde há só ruído. A literatura de
epidemiologia espacial usa **suavização empírica de Bayes** (`spdep::EBest`), que puxa
taxas de municípios pequenos em direção à média estadual proporcionalmente à incerteza.
Não está no PDF; é um refinamento a decidir (ADR-0004), e o pipeline deve produzir as
duas versões para comparação.

> **MAUP** (*Modifiable Areal Unit Problem*) = o resultado de uma estatística espacial
> muda conforme o recorte das áreas. Agregar por município é uma escolha, e o
> relatório precisa reconhecê-la como limitação (seção 5.3 do PDF).

### 2.9 LISA e testes múltiplos

O Moran Local roda **92 testes** de uma vez. Com p<0,05 esperam-se ~4,6 municípios
"significativos" por puro acaso mesmo sem nenhum padrão real. A prática atual é usar
`localmoran_perm()` (permutação, não a aproximação analítica) e corrigir os p-valores
por FDR (*False Discovery Rate*, método de Benjamini-Hochberg), reportando os dois. O
PDF não fala disso; entra no ADR-0004.

### 2.10 Contiguidade Queen no RJ

Os 92 municípios formam um único bloco contínuo (Ilha Grande e Paquetá pertencem a
Angra e ao Rio, não são municípios). Ainda assim o pipeline deve **provar** isso com
`spdep::n.comp.nb(nb)$nc == 1`, porque uma malha com geometria inválida pode gerar
"ilhas" artificiais, e o `nb2listw` falha ou distorce com vizinhança vazia.

### 2.11 Ambiente da máquina

R, Rscript e RTools **não estão instalados** nesta máquina (verificado no PATH e em
`C:\Program Files\R`). Python 3.13 e `pdftotext` existem. Quarto CLI não verificado.
A primeira tarefa da trilha é instalar e provar com número de versão.

### 2.12 Prazo

O arquivo chama-se `23092026_…`, dois dias antes desta análise. Não sabemos se é a data
em que a proposta foi apresentada ou uma data de entrega. **Pergunta aberta ao dono**
(D2 no BACKLOG).

---

## 3. Arquitetura técnica

### 3.1 Stack (versões a congelar no `renv.lock`)

| Camada | Pacote | Por quê este e não outro |
|---|---|---|
| Ambiente | R ≥ 4.4, `renv` | `renv` congela a versão exata de cada pacote; sem ele "funciona na minha máquina" |
| Leitura de dados grandes | `arrow` | Lê PARQUET e CSV **por coluna** sem carregar tudo na RAM; o INFLUD22 completo tem centenas de MB e ~190 colunas, das quais usamos ~20 |
| Manipulação | `dplyr`, `tidyr`, `stringr`, `lubridate` | Ecossistema tidyverse pedido pelo PDF |
| População | `sidrar` | Cliente da API SIDRA do IBGE (tabelas 4714 e 6579) |
| Cartografia | `sf`, `geobr` | Pedidos pelo PDF; `sf` é o padrão de fato para vetores em R |
| Estatística espacial | `spdep` | Pedido pelo PDF; `poly2nb`, `nb2listw`, `moran.mc`, `localmoran_perm`, `EBest` |
| Mapas estáticos | `ggplot2` + `sf` (`geom_sf`) | Sem dependência externa; PNG reprodutível |
| Painel | `shiny`, `bslib`, `leaflet` | Pedidos pelo PDF |
| Relatório | Quarto (`.qmd`) | Pedido pelo PDF; gera HTML, PDF e revealjs do mesmo fonte |
| Testes | `testthat` (edição 3) | Padrão em R; roda em CI |
| Formato intermediário | PARQUET (`arrow::write_parquet`) e RDS | O PDF já prevê `.parquet` para tabelas e `.rds` para objetos `sf`/`listw` |

**Decisão a registrar (ADR-0005):** manter os scripts numerados + `run.R` como o PDF
desenha, em vez do pacote `targets`. Motivo: o avaliador da disciplina precisa ler o
fluxo sem aprender uma ferramenta de orquestração; o custo é re-executar tudo em vez de
só o que mudou. Aceitável para 92 polígonos e 4 anos.

### 3.2 Fluxo e contratos entre etapas

O PDF define a cadeia; aqui ela ganha **contrato**: o que cada etapa promete produzir.
Testes verificam o contrato, não a implementação.

```
00_setup.R          cria diretórios, carrega renv, lê config (anos, snapshot)
01_etl_sivep.R  ──► dados/processados/sivep_processado.parquet
                    contrato: 1 linha por ficha; colunas tipadas; só CO_MUN_RES 33xxxx;
                    coluna agente ∈ {sarscov2, influenza, vsr}; datas plausíveis
02_indicadores.R ─► dados/processados/indicadores_municipais.parquet
                    contrato: 92 municípios × 3 agentes × N períodos, SEM linha faltante
                    (zero explícito); casos, populacao, incid_100k, incid_eb_100k
03_cartografia.R ─► dados/processados/municipios_rj.rds
                    contrato: sf com 92 feições válidas, EPSG:4674, coluna cod6
04_pesos_espaciais.R ► resultados/objetos/pesos_queen.rds
                    contrato: listw estilo W; n.comp.nb == 1; nenhum vizinho vazio
05_moran_lisa.R ──► resultados/estatistica/moran_lisa.rds
                    contrato: por agente × ano: I, p_mc (999 perm, seed fixa),
                    tabela LISA com Ii, p_perm, p_fdr, quadrante, classe
06_visualizacoes.R ► resultados/mapas/*.png
07_exportacao.R ──► resultados/tabelas/*.csv
app.R / 08_relatorio.qmd  consomem só dados/processados e resultados/
```

### 3.3 Invariantes do projeto (as regras que nunca se quebram)

1. **`dados/brutos/` nunca entra no git** e nunca é editado; só baixado e hasheado.
2. **Todo número do relatório sai de um objeto em `resultados/`**, nunca digitado à mão.
3. **Zero explícito**: município sem caso aparece com `casos = 0`, não desaparece.
4. **Chave de join é `cod6`** (6 dígitos, texto), em todas as tabelas, sempre.
5. **Semente fixa** (`set.seed`) antes de qualquer permutação Monte Carlo.
6. **Vizinhança única**: `n.comp.nb == 1` é testado antes de qualquer Moran.
7. **Fixture sintética é rotulada** como fabricada; nunca se parece com dado real de paciente.
8. **Verificação com número**: "testes passando" não vale; "38/38 em 6 arquivos" vale.

> **Fixture** = um dado pequeno e controlado, criado só para testar. Aqui será um
> CSV de ~200 linhas com as mesmas colunas do SIVEP, gerado por script com valores
> inventados, para que os testes rodem em 2 segundos e sem baixar 500 MB.

### 3.4 Classes de documento

| Classe | Arquivos | Regra |
|---|---|---|
| Intocável | o PDF da proposta; `dados/MANIFESTO.md` depois de fechado por snapshot | não se edita; nova versão = novo arquivo |
| Append-only | `docs/decisoes/ADR-*.md`; `docs/release-history/*.md` | só se acrescenta |
| Vivo | este documento; `docs/BACKLOG.md`; `README.md` | reflete o estado atual |

---

## 4. Modelo e esforço — critério usado no BACKLOG

Herdado do padrão do dono (CLAUDE.md do Compasso, §0a):

| Modelo | Quando |
|---|---|
| **Fable 5** | Decisão com espaço aberto, auditoria, refutação, desenho de ADR |
| **Opus** | Execução de tarefa já desenhada; fallback **Opus · high** se Fable indisponível |

| Esforço | Quando |
|---|---|
| `low` | Mecânico, critério binário de aceite, sem bifurcação |
| `medium` | Existe uma armadilha real (falha silenciosa, ordem crítica) |
| `high` | Espaço de solução aberto; precisa comparar alternativas |

Cada item do BACKLOG carrega os dois. Esforço mede profundidade de raciocínio, não
tamanho da resposta.

---

## 5. Trilha por fases

A ordem respeita dependências reais e o fato de que o texto científico depende dos
números. Itens completos em `docs/BACKLOG.md`.

| Fase | Objetivo | Itens | Critério de saída (com número) |
|---|---|---|---|
| **F0 Fundação** | Máquina e repositório prontos | CS-001 a CS-004 | `Rscript -e 'library(sf); library(spdep); library(arrow)'` sem erro; `git log` com 1 commit; `renv.lock` existe |
| **F1 ETL** | SIVEP-RJ 2022–2025 limpo e classificado | CS-005 a CS-010 | parquet com ≥ 1 linha por ano; 100 % `CO_MUN_RES` com prefixo 33; testes do ETL X/X verdes |
| **F2 Indicadores** | Taxas por 100 mil, grade completa | CS-011 a CS-013 | `nrow == 92 × 3 × 4` (anual); nenhum `NA` em `incid_100k` |
| **F3 Cartografia** | Malha RJ validada e chaveada | CS-014, CS-015 | 92 feições; `all(st_is_valid)`; EPSG 4674; join com indicadores = 92 linhas |
| **F4 Estatística espacial** | Moran global e LISA por agente × ano | CS-016 a CS-018 | `n.comp.nb == 1`; 12 valores de I com p_mc; tabela LISA 92 × 12; testes sintéticos verdes |
| **F5 Produtos** | Mapas, tabelas, Shiny, Quarto | CS-019 a CS-023 | `run.R` do zero em < N min; `quarto render` sem erro; app abre e filtra 3 × 4 |
| **F6 Entrega** | Reprodutível por terceiro | CS-024 a CS-027 | CI verde; README seguido em máquina limpa; auditoria final sem divergência número-relatório |

### 5.1 Caminho crítico

```
CS-001 → CS-002 → CS-005 → CS-006 → CS-007(ADR-0002) → CS-008 → CS-012 → CS-016 → CS-017 → CS-022
                          └→ CS-014 ─────────────────────────────┘
                 CS-011(ADR-0003) ───────────────────────┘
```

Tudo o mais (Shiny, mapas estáticos, CI, EB) pode correr em paralelo depois de CS-012.

### 5.2 Decisões que só o dono (ou a mestranda) fecha

Estão no BACKLOG como `D-0N`. Nenhuma bloqueia a F0 e a F1 inicial; a D4 (critério
de caso) bloqueia CS-008 em diante.

---

## 6. Riscos que não são tarefas

| Risco | Mitigação |
|---|---|
| Portal de dados abertos muda URL dos recursos (já aconteceu: `opendatasus` → `dadosabertos`) | `baixar_sivep()` recebe a URL de um `config/fontes.yml`, não a tem em código; manifesto guarda a URL usada |
| `geobr` depende de servidor externo instável | cache local em `dados/externos/municipios_rj_<ano>.rds` com hash; teste lê do cache |
| Dado de 2025 incompleto por atraso de notificação | relatório declara a data de corte e trata 2025 como parcial; gráfico de maturação opcional |
| LGPD | microdados já anonimizados pelo Ministério; o projeto só publica agregados por município; nunca comitar `dados/brutos/` |
| Dependência de compilação no Windows (`sf`, `arrow`) | usar binários do CRAN; RTools só se um pacote exigir |

---

## 7. Glossário rápido (termos que aparecem sem explicação no PDF)

- **Estudo ecológico**: a unidade de análise é o grupo (município), não o indivíduo. Não permite inferir risco individual.
- **Incidência por 100 mil**: (casos ÷ população) × 100 000. Normaliza para comparar municípios de tamanhos diferentes.
- **Contiguidade Queen**: dois polígonos são vizinhos se tocam em qualquer ponto (como a rainha do xadrez). Rook exige aresta compartilhada.
- **Matriz de pesos W (estilo W)**: cada linha soma 1; o valor "esperado do vizinho" é a média dos vizinhos.
- **Moran Global I**: um número de −1 a +1; positivo = municípios parecidos com os vizinhos (agrupamento); zero = aleatório.
- **Monte Carlo**: embaralha os valores entre os polígonos 999 vezes e vê quantas vezes o I por acaso supera o observado. Daí o p-valor.
- **LISA / Moran Local**: o mesmo cálculo, um por município. Gera as classes Alto-Alto, Baixo-Baixo, Alto-Baixo, Baixo-Alto e "não significativo".
- **FDR (Benjamini-Hochberg)**: correção que controla a proporção esperada de falsos positivos entre os que foram declarados significativos.
- **SIRGAS 2000 / EPSG:4674**: o sistema de referência geodésico oficial do Brasil e seu código numérico universal. Todo dado espacial do projeto é convertido para ele antes de qualquer cruzamento.
- **Parquet**: formato de arquivo colunar; ler 20 colunas de 190 custa 20/190 do tempo, diferente do CSV.
