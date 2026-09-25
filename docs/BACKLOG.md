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
| D-03 | Baixar CSV ou PARQUET do portal? PARQUET é menor e lê por coluna; CSV é o formato "clássico" que a banca conhece | PARQUET, com CSV como fallback | **Decidida 2026-09-25: PARQUET** (ADR-0001) |
| D-04 | Critério de caso: estrito (`CLASSI_FIN` + laboratório) como o PDF escreve, ou laboratorial puro? Co-detecção conta em cada vírus? | ~~Estrito, co-detecção conta em cada agente e é reportada~~ **Atualizada 2026-09-25 (ADR-0002, com números sobre 99.880 fichas):** regra **R2 vigilância** (`CLASSI_FIN` do agente + critério laboratorial declarado ou checkbox), porque a estrita perde 27 % → 5 % dos casos de COVID entre 2022 e 2025 só por checkbox em branco; **atribuição única** por `CLASSI_FIN`, co-detecção só reportada; contar toda ficha do banco sem filtrar internação. Três perguntas no ADR-0002 §8 | CS-008 |
| D-05 | Denominador 2023 (IBGE não publicou estimativa): repetir Censo 2022, interpolar 2022–2024 ou outra? | Interpolar linearmente. **Atualizada 2026-09-25 (ADR-0003):** o Censo 2022 fica 3,1–8,4 % abaixo da estimativa de 2024 em todos os 92 municípios; há 4 opções no ADR. Implementada a interpolação como provisória | CS-012 (comparação entre anos) |
| D-06 | "Por bairro" na seção 4.2 do PDF: erro de digitação ou intenção futura? | Tratar como município; registrar em ADR-0005 | CS-022 |
| D-07 | Data de corte do snapshot do banco 2025 (vivo, semanal). Uma vez fixada, o manifesto congela | Fixar na primeira execução real do CS-005 | **Decidida 2026-09-25: versão 14-09-2026** (ADR-0001) |
| D-08 | Agregação quadrimestral: entra como série temporal no relatório ou só a anual vai para LISA? | Anual no LISA; quadrimestral só em gráfico de linha | CS-012, CS-019 |
| D-09 | Suavização empírica de Bayes: só comparação no relatório ou substitui a taxa bruta no LISA? | Reportar as duas; LISA sobre a suavizada | CS-013, CS-017 |
| D-10 | A mestranda aceita os objetivos novos da proposta v2 (OE9 padronização por idade, OE10 leitos do CNES, escala de região de saúde, hipóteses H1–H4)? | Aceitar região de saúde e H1–H3; OE9/OE10 como opcionais | CS-030 a CS-034 |

---

## Abertos

### F0 — Fundação

| ID | Título | Evidência | Modelo · Esforço | Aceite |
|---|---|---|---|---|
| CS-029 | **Ecossistema `.claude/`** no padrão evidence: `CLAUDE.md` do projeto (constituição = PDF, invariantes §3.3 da trilha), hook `SessionStart` de contexto, hook que nega commit sem release-history. Adaptar, não copiar | memória do dono `ecossistema-segue-padrao-evidence` | Opus · medium | 2 hooks registrados; `CLAUDE.md` ≤ 150 linhas |

### F1 — ETL do SIVEP-Gripe

| ID | Título | Evidência | Modelo · Esforço | Aceite |
|---|---|---|---|---|
| CS-008 | **`classificar_agente()` + `aplicar_criterios_inclusao()`** — aplica a regra aceita na D-04 chamando `aplicar_regra_caso(d, <regra>)` (as 5 regras já existem em `REGRAS_CASO`); saída `sivep_processado.parquet` com `agente` (fator), `codeteccao` (outro dos 3 agentes detectado) e `subtipo_influenza` (A/B); tabula o subtipo | ADR-0002 (proposto); **bloqueado pela D-04** | Opus · medium | contagem por agente × ano idêntica à linha da regra em `comparacao_regras_caso.csv`; parquet ≥ 1 linha por ano; subtipo A/B tabulado |
| CS-009 | **`validar_variaveis()`, `validar_codigos_ibge()`, `validar_municipios_rj()`, `validar_datas()`** — falham alto (`stop()`) em: coluna faltante, código fora dos 92, data < 2022-01-01 ou > data do snapshot | PDF tabela de funções; `srag-intelligence-agent` PR #1 registra anos impossíveis (1695, 5202) | Opus · medium | 4 funções; cada uma com ≥ 2 testes (1 passa, 1 falha) |
| CS-010 | **Fixture sintética + testes do ETL** — `tests/testthat/fixtures/sivep_sintetico.csv` (~200 linhas geradas por `tests/gerar_fixture.R` com seed, rotuladas FABRICADAS), cobrindo os 92 municípios, 3 agentes, co-detecção, `CLASSI_FIN` vazio, data inválida | trilha §3.3 invariante 7 | Opus · medium | testes do ETL rodam em < 5 s sem rede; X/X verdes |

### F2 — Indicadores

| ID | Título | Evidência | Modelo · Esforço | Aceite |
|---|---|---|---|---|
| CS-012 | **`calcular_casos()`, `calcular_incidencia()`, `completar_municipios()`** — grade completa 92 × 3 × 4 (anual) e 92 × 3 × 12 (quadrimestral) com zero explícito; join por `cod6`; `incid_100k = casos/populacao*1e5` | trilha §3.3 invariantes 3 e 4; medido no CS-006: só 90 municípios têm ficha em 2023 e 91 em 2024, então a grade completa é necessária já nos dados brutos | Opus · medium | `nrow == 1104` (anual); 0 `NA`; município sem caso presente com 0; teste: remover um município do input e ver a grade completar |
| CS-013 | **Suavização empírica de Bayes** — `spdep::EBest(casos, populacao)` por agente × ano; coluna `incid_eb_100k`; comparação bruta × EB no relatório | trilha §2.8; D-09 | **Fable · medium** | coluna preenchida 92 × 12; gráfico dispersão bruta × EB; nota metodológica no relatório |

### F3 — Cartografia

| ID | Título | Evidência | Modelo · Esforço | Aceite |
|---|---|---|---|---|

### F4 — Estatística espacial

| ID | Título | Evidência | Modelo · Esforço | Aceite |
|---|---|---|---|---|
| CS-017 | **ADR-0004 + `05_moran_lisa.R`** — alinhar dados aos pesos pelo `region.id` (= cod6) de `pesos_queen.rds`, nunca pela posição; decidir o CS-039 no mesmo ADR — — Moran global via `moran.mc(nsim=999)` com `set.seed`; LISA via `localmoran_perm(nsim=999)`; p bruto e `p.adjust(method="BH")`; classificação em 5 classes (HH, LL, HL, LH, ns) com α=0,05; variável: `incid_eb_100k` (D-09) | trilha §2.9; PDF §3.4 | **Fable · high** | 12 combinações agente × ano com I, p_mc; tabela LISA 92 × 12; ADR aceito; contagem de HH antes e depois do FDR reportada |
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
| CS-030 | **Escala de região de saúde** — `geobr::read_health_region()` filtrada para o RJ (9 regiões) **só como tabela município → região; a geometria regional sai de dissolver a malha IBGE (ADR-0006)**; agregação de casos e população por região; mapas e Moran/LISA regionais (n = 9 é pequeno para LISA; reportar só descritivo e Moran global com ressalva) | proposta v2 §3.4; SES-RJ, 9 regiões | Opus · medium | 9 feições; tabela 9 × 3 × 4; 12 mapas regionais |
| CS-031 | **Residência × notificação** — recalcular indicadores por `CO_MUN_NOT` e tabular a diferença por município (mede fluxo intermunicipal de internação, Cavalcante 2021) | proposta v2 §3.3 | Opus · low | tabela 92 linhas com casos_res, casos_not, razão; top-10 importadores |
| CS-032 | **Série por semana epidemiológica** — casos por `semana_epi` (calculada de `DT_SIN_PRI`; NÃO o `SEM_PRI`, que rotula a semana 53/2025 como 01) × agente para o estado e por região; gráfico de linhas com as datas das campanhas de Influenza como marcas | proposta v2 §4.2, §5.1; D-08 | Opus · low | 1 gráfico estadual + 9 regionais; semanas do Ministério (domingo a sábado) |
| CS-033 | **Padronização por idade (OE9, opcional)** — SIDRA 9514 por faixa etária; método direto com padrão RJ 2022; `incid_pad_100k` para VSR e Influenza | proposta v2 §3.4; API 9514 verificada (134 linhas por município) | **Fable · medium** | coluna preenchida; gráfico bruta × padronizada; nota metodológica |
| CS-034 | **Leitos do CNES (OE10, opcional)** — `microdatasus` CNES-LT por município e ano (leitos SUS clínicos + UTI); Spearman entre taxa por residência e leitos por 100 mil, por ano e por região | proposta v2 §3.10; aqui o `microdatasus` cobre a fonte | Opus · medium | 4 coeficientes (um por ano) com IC; sem linguagem causal no relatório |
| CS-035 | **Proporção de não encerrados** — por ano, fração de fichas com `CLASSI_FIN` vazio entre as fichas de SRAG do RJ; gráfico por semana para 2025 (maturação) | proposta v2 §3.3, §3.10 item 2 | Opus · low | tabela 4 linhas; gráfico 2025 |

### Achados do CS-006

| ID | Título | Evidência | Modelo · Esforço | Aceite |
|---|---|---|---|---|
| CS-036 | **"Ano" do estudo é o ano epidemiológico** — cada banco anual do SIVEP é um ano epidemiológico (o de 2024 começa em 31/12/2023; o de 2025 termina em 03/01/2026, semana 53). A proposta v2 §3.1 fala em "01/01/2022"; ajustar o texto, o relatório e o denominador (população de 1º de julho do ano civil de mesmo número, diferença de no máximo 3 dias) | ADR-0001, "Fatos descobertos"; `preparar_sivep()` recusa ficha fora do ano do banco | Opus · low | proposta v2 §3.1 e §3.3 corrigidas; nota no relatório; ADR-0003 cita a convenção |

### Achados do CS-011 e do CS-014

| ID | Título | Evidência | Modelo · Esforço | Aceite |
|---|---|---|---|---|

### Achados do CS-016

| ID | Título | Evidência | Modelo · Esforço | Aceite |
|---|---|---|---|---|
| CS-039 | **Efeito de borda e municípios com 1 vizinho** — Paraty (só Angra), Itatiaia (só Resende) e Armação dos Búzios (só Cabo Frio) têm 1 vizinho; com pesos W, o LISA deles é a comparação com um único município. Paraty e Itatiaia, e outros municípios de divisa, perdem vizinhos de SP, MG e ES. Decidir no ADR-0004: (a) só declarar na limitação; (b) sensibilidade com k vizinhos mais próximos (k = 4); (c) marcar a classe LISA desses 3 como "instável" no mapa | `resultados/estatistica/vizinhos_por_municipio.csv` · CS-016 | Fable · medium (entra no ADR-0004) | ADR-0004 decide; relatório §5.3 cita os 3 municípios |

### Achados do CS-007

| ID | Título | Evidência | Modelo · Esforço | Aceite |
|---|---|---|---|---|
| CS-040 | **Sensibilidade do critério de caso no relatório** — tabela agente × ano com R1 (limite inferior), R2 (escolhida), R4 (limite superior) e R5 como "detecções por agente"; tabela de co-detecção; nota sobre os 941 casos de 2022 com critério laboratorial sem resultado exportado | ADR-0002 §4.5 e §6; `resultados/tabelas/comparacao_regras_caso.csv` | Opus · low | 3 tabelas no `08_relatorio.qmd`, lidas do CSV |

### Fora do código (para a mestranda)

| ID | Título | Evidência | Modelo · Esforço | Aceite |
|---|---|---|---|---|
| CS-028 | **Seções vazias do PDF** — 1.1, 1.2 (contextualização, problematização), 6 (conclusão) e Apêndice A são texto científico; dependem de CS-022 para os números. Registrar aqui para que a trilha não "termine" com o relatório sem introdução | PDF: seções listadas sem conteúdo | Fable · medium (revisão) | rascunho entregue à mestranda; não é aceite de código |

---

## ADRs previstos

| ADR | Título | Nasce em |
|---|---|---|
| ADR-0001 | Extração do SIVEP-Gripe por download direto do portal (não `microdatasus`) | CS-005 · **escrito e aceito** (decide D-03 e D-07) |
| ADR-0002 | Critério de caso por agente e tratamento de co-detecção | CS-007 · **escrito, proposto** (aguarda D-04) |
| ADR-0003 | Denominador populacional por ano, incluindo 2023 | CS-011 · **escrito, proposto** (aguarda D-05) |
| ADR-0004 | LISA: permutação, correção FDR, variável (bruta × EB), α | CS-017 |
| ADR-0006 | Malha oficial do IBGE em resolução completa, não o `geobr` simplificado | CS-014 · **escrito e aceito** |
| ADR-0005 | Escopo: município (não bairro); scripts numerados (não `targets`); quadrimestre só descritivo | CS-002 · **escrito**, itens 1–2 aceitos |

---

## Encerrados

| ID | Título | Encerrado em | Commit/registro |
|---|---|---|---|
| CS-001 | **Ambiente R** — R 4.6.1, Quarto 1.10.18; 9/9 pacotes carregam; Rtools dispensado (nenhum pacote compilou) | 2026-09-25 | `docs/release-history/cs-001-cs-002-fundacao.md` · commit `b66ae13` |
| CS-002 | **Esqueleto do repositório** — árvore do PDF, `renv.lock` com 140 pacotes, 5/5 expectativas, `git init` | 2026-09-25 | idem · ADR-0005 |
| CS-003 | **Manifesto de proveniência** — `registrar_fonte()`, `verificar_manifesto()`, `baixar_e_registrar()`; tabela Markdown escrita e relida por código; 12 testes, incluindo arquivo alterado em 1 byte | 2026-09-25 | `docs/release-history/cs-003-cs-004-proveniencia-e-dicionario.md` · commit `5f09f23` |
| CS-004 | **Dicionário oficial no repositório** — PDF oficial (28 p., SHA-256 `6b92d438…`) registrado no manifesto; `docs/dicionario-sivep.md` com 34 campos, domínio de cada um e 4 marcados [CONFERIR] | 2026-09-25 | idem |
| CS-005 | **Download do SIVEP sem `microdatasus`** — `baixar_sivep()` + `baixar_arquivo()` com retomada; 4 bancos PARQUET (113,9 MB) no manifesto; 2ª chamada usa o cache em 0,4 s | 2026-09-25 | `docs/release-history/cs-005-cs-006-etl-sivep.md` · ADR-0001 · commit `0f38200` |
| CS-006 | **`preparar_sivep()`** — 99.880 fichas de residentes do RJ, 34 colunas tipadas, datas lidas em UTC, semana epidemiológica recalculada; 4 dúvidas do dicionário conferidas; diagnóstico por ano em `resultados/tabelas/` | 2026-09-25 | idem |
| CS-011 | **Denominadores populacionais** — SIDRA 4714 (Censo 2022) e 6579 (2024, 2025) no manifesto; 2023 interpolado nas datas de referência reais (peso 0,4771); 92 × 4 sem NA; soma 2022 = 16.055.174. ADR-0003 **proposto**: degrau Censo × estimativa devolvido à D-05 | 2026-09-25 | `docs/release-history/cs-011-cs-014-populacao-e-malha.md` · commit `0d3d91a` |
| CS-014 | **Malha municipal** — IBGE oficial em resolução completa (ADR-0006), não o `geobr` simplificado, que perdia 8 pares de vizinhos; 92 feições válidas, EPSG 4674; casa 92/92 com população e SIVEP por `cod6` | 2026-09-25 | idem · ADR-0006 |
| CS-015 | **Testes da malha** — 92 códigos únicos com prefixo 33, área 43.750,4 km² (dentro de 2 % da oficial). Fechado junto com o CS-014, com aviso ao dono, porque os critérios já eram exercidos pelo mesmo teste | 2026-09-25 | idem |
| CS-016 | **Vizinhança Queen e pesos W** — 92 municípios, **456 ligações** (bate com o ADR-0006), 1 bloco, mínimo 1 vizinho, máximo 10, mediana 5; `region.id` = cod6; tabela e histograma em `resultados/estatistica/` | 2026-09-25 | `docs/release-history/cs-016-vizinhanca-queen.md` · commit `72970cf` |
| CS-007 | **ADR-0002, critério de caso** — 5 regras candidatas em código (`REGRAS_CASO`, 6 testes), tabela 5 regras × 3 agentes × 4 anos sobre 99.880 fichas, decomposição das fichas sem checkbox, co-detecção; ADR **proposto** com recomendação R2 e 3 perguntas à autora (D-04) | 2026-09-25 | `docs/release-history/cs-007-criterio-de-caso.md` · ADR-0002 · commit `df1606a` |
| CS-037 | **Proposta v2 atualizada com as decisões de dados** — §2.2 OE4, §3.2, §3.3 (critério de caso e co-detecção), §3.4 (denominador), §3.5 (malha), §3.10 (limitações 2, 6, 7) e referências; D-04 e D-05 continuam pendentes e o texto traz a **recomendação** marcada [REVISAR]. Não inclui o CS-036 (ano epidemiológico em §3.1) | 2026-09-25 | `docs/release-history/cs-037-cs-038-proposta-e-ibge.md` · commit PENDENTE |
| CS-038 | **Método de ajuste do IBGE citado** — Nota metodológica n. 01 das Estimativas 2024, p. 6–7: Censo 2022 ajustado pela PPE, maior ajuste em municípios grandes; citado no ADR-0003 e na proposta v2 | 2026-09-25 | idem |

## Descartados

| ID | Título | Motivo |
|---|---|---|
| — | *(nenhum ainda)* | |
