# BACKLOG — Cartografia & Saúde (SRAG-RJ 2022–2025)

Fonte única de "feito / não feito". Criado em 2026-09-25 na análise inicial do PDF.

Regras (herdadas do padrão evidence/Compasso do dono):
1. **Achado fora de escopo vira item `CS-0NN` aqui** antes de a tarefa fechar. Prosa não conta.
2. **Nada é apagado.** Concluído vai para *Encerrados* com data e commit; descartado fica com o motivo.
3. Cada item carrega **evidência** (`arquivo:linha`, URL verificada ou ADR). Sem evidência é opinião.
4. Cada item carrega **modelo e esforço** (critério em `docs/trilha-desenvolvimento.md` §4).
5. Critério de aceite tem **número**, nunca adjetivo.

Prefixos: `CS` = tarefa · `D` = decisão que só o dono/mestranda fecha · `ADR` = decisão registrada em `docs/decisoes/`.

---

## Decisões abertas (bloqueiam o que está indicado)

| ID | Pergunta | Recomendação | Bloqueia |
|---|---|---|---|
| D-01 | Quem é o dono do repositório GitHub público (item 4.5 do PDF): Patrick, Gabrielle ou ambos? Qual licença (MIT para código, CC-BY para relatório)? | Ambos como autores; MIT + CC-BY 4.0 | CS-026 |
| D-02 | O `23092026` no nome do arquivo é data da apresentação (já passou) ou prazo de entrega? Existe prazo real para o produto final? | — | ordem da F5/F6 |
| D-03 | Baixar CSV ou PARQUET do portal? PARQUET é menor e lê por coluna; CSV é o formato "clássico" que a banca conhece | PARQUET, com CSV como fallback | CS-005 |
| D-04 | Critério de caso: estrito (`CLASSI_FIN` + laboratório) como o PDF escreve, ou laboratorial puro? Co-detecção conta em cada vírus? | Estrito, co-detecção conta em cada agente e é reportada | CS-007, CS-008 |
| D-05 | Denominador 2023 (IBGE não publicou estimativa): repetir Censo 2022, interpolar 2022–2024 ou outra? | Interpolar linearmente | CS-011 |
| D-06 | "Por bairro" na seção 4.2 do PDF: erro de digitação ou intenção futura? | Tratar como município; registrar em ADR-0005 | CS-022 |
| D-07 | Data de corte do snapshot do banco 2025 (vivo, semanal). Uma vez fixada, o manifesto congela | Fixar na primeira execução real do CS-005 | CS-003 |
| D-08 | Agregação quadrimestral: entra como série temporal no relatório ou só a anual vai para LISA? | Anual no LISA; quadrimestral só em gráfico de linha | CS-012, CS-019 |
| D-09 | Suavização empírica de Bayes: só comparação no relatório ou substitui a taxa bruta no LISA? | Reportar as duas; LISA sobre a suavizada | CS-013, CS-017 |
| D-10 | A mestranda aceita os objetivos novos da proposta v2 (OE9 padronização por idade, OE10 leitos do CNES, escala de região de saúde, hipóteses H1–H4)? | Aceitar região de saúde e H1–H3; OE9/OE10 como opcionais | CS-030 a CS-034 |

---

## Abertos

### F0 — Fundação

| ID | Título | Evidência | Modelo · Esforço | Aceite |
|---|---|---|---|---|
| CS-003 | **Manifesto de proveniência** — `dados/MANIFESTO.md` gerado por `R/funcoes_utilitarias.R::registrar_fonte()`: URL, data/hora do download, bytes, SHA-256, versão do arquivo (ex.: `INFLUD25_DATASUS-Versao26-06-2025`). Sem manifesto, nada em `dados/brutos/` é lido | trilha §2.4; portal marca 2025–2026 como bancos vivos (atualização 2026-09-14) | Opus · medium | 1 linha por arquivo bruto; `verificar_manifesto()` falha se hash divergir (teste com arquivo alterado) |
| CS-004 | **Dicionário oficial no repositório** — baixar o "Dicionário de Dados 2019–2025" do portal para `dados/externos/`, extrair para `docs/dicionario-sivep.md` a tabela dos ~25 campos usados, com a coluna "nome no PDF → nome real" (trilha §2.2) | recurso `3135ac9c-…` do dataset `srag-2019-a-2026` | Opus · low | tabela com os 25 campos; cada um com domínio de valores citado |
| CS-029 | **Ecossistema `.claude/`** no padrão evidence: `CLAUDE.md` do projeto (constituição = PDF, invariantes §3.3 da trilha), hook `SessionStart` de contexto, hook que nega commit sem release-history. Adaptar, não copiar | memória do dono `ecossistema-segue-padrao-evidence` | Opus · medium | 2 hooks registrados; `CLAUDE.md` ≤ 150 linhas |

### F1 — ETL do SIVEP-Gripe

| ID | Título | Evidência | Modelo · Esforço | Aceite |
|---|---|---|---|---|
| CS-005 | **`baixar_sivep()` sem `microdatasus`** (ADR-0001) — download HTTP direto do portal por ano, URLs em `config/fontes.yml`, retomada de download, chamada a `registrar_fonte()`. `microdatasus` não suporta SIVEP-Gripe | trilha §2.1; doc oficial de `fetch_datasus()` | Opus · medium | 4 arquivos (2022–2025) em `dados/brutos/` com hash no manifesto; segunda chamada não rebaixa (cache por hash) |
| CS-006 | **`preparar_sivep()`** — `arrow::open_dataset` lendo só as ~25 colunas; filtro `substr(CO_MUN_RES,1,2)=="33"`; `CO_MUN_RES` como **texto**; datas `dd/mm/yyyy` → `Date`; `SEM_PRI` mantida; encoding Latin-1 se CSV | dicionário: `CO_MUN_RES Varchar2(6)`; trilha §2.2 | Opus · medium | 100 % das linhas com prefixo 33; 0 datas `NA` em `DT_SIN_PRI`; `class(CO_MUN_RES) == "character"`; tempo por ano medido |
| CS-007 | **ADR-0002 — critério de caso e co-detecção** — texto curto: regra estrita do PDF (`CLASSI_FIN` + PCR/antígeno por vírus), tratamento do vazio em `CLASSI_FIN` (não encerrado ≠ negativo), co-detecção contada por agente. Inclui tabela "quantos casos cada regra alternativa incluiria" | trilha §2.6, §2.7; D-04 | **Fable · high** | ADR aceito pelo dono; tabela comparativa com 3 regras × 4 anos |
| CS-008 | **`classificar_agente()` + `aplicar_criterios_inclusao()`** implementando o ADR-0002; saída `sivep_processado.parquet` com coluna `agente` (fator: sarscov2/influenza/vsr) e `codeteccao` (lógico) | ADR-0002 | Opus · medium | contagem por agente × ano bate com a tabela do ADR; parquet ≥ 1 linha por ano |
| CS-009 | **`validar_variaveis()`, `validar_codigos_ibge()`, `validar_municipios_rj()`, `validar_datas()`** — falham alto (`stop()`) em: coluna faltante, código fora dos 92, data < 2022-01-01 ou > data do snapshot | PDF tabela de funções; `srag-intelligence-agent` PR #1 registra anos impossíveis (1695, 5202) | Opus · medium | 4 funções; cada uma com ≥ 2 testes (1 passa, 1 falha) |
| CS-010 | **Fixture sintética + testes do ETL** — `tests/testthat/fixtures/sivep_sintetico.csv` (~200 linhas geradas por `tests/gerar_fixture.R` com seed, rotuladas FABRICADAS), cobrindo os 92 municípios, 3 agentes, co-detecção, `CLASSI_FIN` vazio, data inválida | trilha §3.3 invariante 7 | Opus · medium | testes do ETL rodam em < 5 s sem rede; X/X verdes |

### F2 — Indicadores

| ID | Título | Evidência | Modelo · Esforço | Aceite |
|---|---|---|---|---|
| CS-011 | **Denominadores populacionais + ADR-0003** — `sidrar` tabela 4714 (Censo 2022) e 6579 (2024, 2025); 2023 conforme D-05; salvar `dados/externos/populacao_rj.parquet` com `cod6`, `ano`, `populacao`, `fonte` | API SIDRA: 6579 não tem 2022 nem 2023 (verificado 2026-09-25) | **Fable · medium** | 92 × 4 linhas; nenhum `NA`; soma 2022 bate com o Censo do estado (16.055.174) |
| CS-012 | **`calcular_casos()`, `calcular_incidencia()`, `completar_municipios()`** — grade completa 92 × 3 × 4 (anual) e 92 × 3 × 12 (quadrimestral) com zero explícito; join por `cod6`; `incid_100k = casos/populacao*1e5` | trilha §3.3 invariantes 3 e 4 | Opus · medium | `nrow == 1104` (anual); 0 `NA`; município sem caso presente com 0; teste: remover um município do input e ver a grade completar |
| CS-013 | **Suavização empírica de Bayes** — `spdep::EBest(casos, populacao)` por agente × ano; coluna `incid_eb_100k`; comparação bruta × EB no relatório | trilha §2.8; D-09 | **Fable · medium** | coluna preenchida 92 × 12; gráfico dispersão bruta × EB; nota metodológica no relatório |

### F3 — Cartografia

| ID | Título | Evidência | Modelo · Esforço | Aceite |
|---|---|---|---|---|
| CS-014 | **`03_cartografia.R`** — `geobr::read_municipality(code_muni = 33, year = 2022)`, `st_transform(4674)`, `cod6 = substr(code_muni,1,6)`, cache com hash em `dados/externos/`, `st_make_valid` se necessário | trilha §2.2 (6 vs 7 dígitos), §6 (geobr instável) | Opus · medium | 92 feições; `st_crs()$epsg == 4674`; `all(st_is_valid)`; `inner_join(indicadores) → 92` |
| CS-015 | **Testes da malha** — 92 códigos distintos, todos com prefixo 33, nenhum duplicado, área total ≈ 43,7 mil km² (±2 %) | IBGE: área do RJ 43.750 km² | Opus · low | 4 testes verdes |

### F4 — Estatística espacial

| ID | Título | Evidência | Modelo · Esforço | Aceite |
|---|---|---|---|---|
| CS-016 | **`04_pesos_espaciais.R`** — `poly2nb(queen=TRUE)` → `nb2listw(style="W", zero.policy=FALSE)`; salvar `pesos_queen.rds`; teste `n.comp.nb(nb)$nc == 1`; tabela de nº de vizinhos por município | trilha §2.10 | Opus · medium | 1 componente; mín. vizinhos ≥ 1; histograma de vizinhos em `resultados/estatistica/` |
| CS-017 | **ADR-0004 + `05_moran_lisa.R`** — Moran global via `moran.mc(nsim=999)` com `set.seed`; LISA via `localmoran_perm(nsim=999)`; p bruto e `p.adjust(method="BH")`; classificação em 5 classes (HH, LL, HL, LH, ns) com α=0,05; variável: `incid_eb_100k` (D-09) | trilha §2.9; PDF §3.4 | **Fable · high** | 12 combinações agente × ano com I, p_mc; tabela LISA 92 × 12; ADR aceito; contagem de HH antes e depois do FDR reportada |
| CS-018 | **Testes estatísticos com padrão conhecido** — grade sintética 10×10: tabuleiro de xadrez → I < 0 significativo; gradiente → I > 0 significativo; aleatório → p > 0,05 na maioria de 20 seeds | boa prática; `spdep` vignette | Opus · medium | 3 testes verdes; rodam em < 10 s |

### F5 — Produtos

| ID | Título | Evidência | Modelo · Esforço | Aceite |
|---|---|---|---|---|
| CS-019 | **`06_visualizacoes.R`** — `mapa_incidencia()` (coropleto por agente × ano, quebras por quantil, escala viridis, legenda em pt-BR) e `mapa_lisa()` (5 classes, cores convencionais HH vermelho / LL azul), `tema_mapa()`; PNG 300 dpi | PDF tabela de funções | Opus · medium | 12 mapas de incidência + 12 LISA em `resultados/mapas/`; sem texto sobreposto (inspeção visual registrada) |
| CS-020 | **`07_exportacao.R`** — CSV UTF-8 com BOM (abre no Excel) de indicadores e LISA; `salvar_resultado()` com carimbo de data | PDF | Opus · low | 3 CSV; abrem no Excel sem acento quebrado |
| CS-021 | **`app.R` Shiny + leaflet** — sidebar com `selectInput` agente e ano, mapa coropleto com popup (município, casos, população, taxa bruta, taxa EB, classe LISA), toggle de camada LISA; carrega só `dados/processados` e `resultados/`; 3 estados (carregando / vazio / erro) | PDF §3.5 | Opus · medium | 12 combinações filtram sem erro no console; popup mostra 6 campos; inicia em < 5 s |
| CS-022 | **`08_relatorio.qmd` + `_quarto.yml`** — HTML e revealjs do mesmo fonte; seções 4.1–4.5 e 5.1–5.3 do PDF preenchidas com **chunks** que leem `resultados/` (nenhum número digitado); data do snapshot no cabeçalho | PDF sumário; trilha §3.3 invariante 2 | Opus · medium | `quarto render` sem erro; `grep` de números "mágicos" no `.qmd` = 0; 2 formatos gerados |
| CS-023 | **`run.R`** — executa 00→07 em ordem, mede tempo por etapa, para no primeiro erro, escreve `resultados/execucao.log` | PDF "ORGANIZAÇÃO FLUXO" | Opus · low | execução do zero completa; log com 8 tempos |

### F6 — Entrega e reprodutibilidade

| ID | Título | Evidência | Modelo · Esforço | Aceite |
|---|---|---|---|---|
| CS-024 | **`renv.lock` congelado + README de máquina nova** — roteiro: instalar R, `renv::restore()`, baixar dados, `source("run.R")`. Testado em pasta limpa | lição C-003 do Compasso (README que não leva ao verde) | Opus · low | roteiro reexecutado do zero; tempo total registrado |
| CS-025 | **CI GitHub Actions** (`r-lib/actions/setup-r` + `setup-renv`) rodando `testthat` sobre fixtures, sem baixar dados reais | lição C-001 do Compasso (sem CI, fatia quebrada por meses) | Opus · medium | workflow verde no 1º PR; tempo < 10 min |
| CS-026 | **Repositório público** — licença (D-01), `CITATION.cff`, README com badge da CI, link no PDF seção 4.5 | PDF §4.5 | Opus · low | URL público; `CITATION.cff` valida |
| CS-027 | **Auditoria final** — reexecução em máquina limpa; conferir cada número do relatório contra `resultados/`; verificar que os 5 erros factuais do PDF (trilha §2.1–2.5) estão cobertos por ADR; lista de limitações para a seção 5.3 | trilha §2 | **Fable · high** | 0 divergências número-relatório; 5 ADRs referenciados; relatório de auditoria em `docs/release-history/` |

### Propostos pela proposta v2 (condicionados à D-10)

| ID | Título | Evidência | Modelo · Esforço | Aceite |
|---|---|---|---|---|
| CS-030 | **Escala de região de saúde** — `geobr::read_health_region()` filtrada para o RJ (9 regiões); agregação de casos e população por região; mapas e Moran/LISA regionais (n = 9 é pequeno para LISA; reportar só descritivo e Moran global com ressalva) | proposta v2 §3.4; SES-RJ, 9 regiões | Opus · medium | 9 feições; tabela 9 × 3 × 4; 12 mapas regionais |
| CS-031 | **Residência × notificação** — recalcular indicadores por `CO_MUN_NOT` e tabular a diferença por município (mede fluxo intermunicipal de internação, Cavalcante 2021) | proposta v2 §3.3 | Opus · low | tabela 92 linhas com casos_res, casos_not, razão; top-10 importadores |
| CS-032 | **Série por semana epidemiológica** — casos por `SEM_PRI` × agente para o estado e por região; gráfico de linhas com as datas das campanhas de Influenza como marcas | proposta v2 §4.2, §5.1; D-08 | Opus · low | 1 gráfico estadual + 9 regionais; semanas do Ministério (domingo a sábado) |
| CS-033 | **Padronização por idade (OE9, opcional)** — SIDRA 9514 por faixa etária; método direto com padrão RJ 2022; `incid_pad_100k` para VSR e Influenza | proposta v2 §3.4; API 9514 verificada (134 linhas por município) | **Fable · medium** | coluna preenchida; gráfico bruta × padronizada; nota metodológica |
| CS-034 | **Leitos do CNES (OE10, opcional)** — `microdatasus` CNES-LT por município e ano (leitos SUS clínicos + UTI); Spearman entre taxa por residência e leitos por 100 mil, por ano e por região | proposta v2 §3.10; aqui o `microdatasus` cobre a fonte | Opus · medium | 4 coeficientes (um por ano) com IC; sem linguagem causal no relatório |
| CS-035 | **Proporção de não encerrados** — por ano, fração de fichas com `CLASSI_FIN` vazio entre as fichas de SRAG do RJ; gráfico por semana para 2025 (maturação) | proposta v2 §3.3, §3.10 item 2 | Opus · low | tabela 4 linhas; gráfico 2025 |

### Fora do código (para a mestranda)

| ID | Título | Evidência | Modelo · Esforço | Aceite |
|---|---|---|---|---|
| CS-028 | **Seções vazias do PDF** — 1.1, 1.2 (contextualização, problematização), 6 (conclusão) e Apêndice A são texto científico; dependem de CS-022 para os números. Registrar aqui para que a trilha não "termine" com o relatório sem introdução | PDF: seções listadas sem conteúdo | Fable · medium (revisão) | rascunho entregue à mestranda; não é aceite de código |

---

## ADRs previstos

| ADR | Título | Nasce em |
|---|---|---|
| ADR-0001 | Extração do SIVEP-Gripe por download direto do portal (não `microdatasus`) | CS-005 |
| ADR-0002 | Critério de caso por agente e tratamento de co-detecção | CS-007 |
| ADR-0003 | Denominador populacional por ano, incluindo 2023 | CS-011 |
| ADR-0004 | LISA: permutação, correção FDR, variável (bruta × EB), α | CS-017 |
| ADR-0005 | Escopo: município (não bairro); scripts numerados (não `targets`); quadrimestre só descritivo | CS-002 · **escrito**, itens 1–2 aceitos |

---

## Encerrados

| ID | Título | Encerrado em | Commit/registro |
|---|---|---|---|
| CS-001 | **Ambiente R** — R 4.6.1, Quarto 1.10.18; 9/9 pacotes carregam; Rtools dispensado (nenhum pacote compilou) | 2026-09-25 | `docs/release-history/cs-001-cs-002-fundacao.md` · commit `b66ae13` |
| CS-002 | **Esqueleto do repositório** — árvore do PDF, `renv.lock` com 140 pacotes, 5/5 expectativas, `git init` | 2026-09-25 | idem · ADR-0005 |

## Descartados

| ID | Título | Motivo |
|---|---|---|
| — | *(nenhum ainda)* | |
