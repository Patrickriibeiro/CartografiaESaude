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

## Decisões

Em 2026-09-25 a autora aceitou todas as recomendações pendentes (D-01, D-04, D-05,
D-06, D-08, D-09, D-10 e a opção do CS-039). **Só a D-02 (prazo) continua aberta.**

| ID | Pergunta | Recomendação | Bloqueia |
|---|---|---|---|
| D-01 | Quem é o dono do repositório GitHub público (item 4.5 do PDF): Patrick, Gabrielle ou ambos? Qual licença (MIT para código, CC-BY para relatório)? | Ambos como autores; MIT + CC-BY 4.0 | **Decidida 2026-09-25 (autora):** Gabrielle e Patrick como autores; MIT para o código, CC-BY 4.0 para o relatório; o PDF da proposta sai do repositório antes de publicar (ver CS-026: ele está no histórico desde `b66ae13`) | CS-025 | **CI no GitHub Actions — BLOQUEADA por cobrança da conta** *(auditoria: no Windows, clonar em caminho curto; o bootstrap do `renv` falha acima de ~150 caracteres, README avisa)* — workflow escrito e validado; a 1ª execução (run 36170698073, 2026-09-25) **não começou**: o GitHub recusou o job porque "recent account payments have failed or your spending limit needs to be increased". Repositório privado consome minutos do Actions. Destravar: regularizar a cobrança da conta `Patrickriibeiro`, ou tornar o repositório público (Actions é gratuito em repositório público) | `docs/release-history/cs-025-integracao-continua.md`; aba Actions do repositório | Opus · low | 1ª execução verde, < 10 min, 6 testes pulados |
| CS-026 | **Repositório — criado PRIVADO, falta torná-lo público** — feito: licenças, `CITATION.cff`, histórico reescrito sem o PDF (37 commits preservados, hashes citados atualizados; `docs/release-history/cs-026-historico-reescrito.md`), repositório privado `Patrickriibeiro/CartografiaESaude` criado e `main` enviada; conferido pela API que o único PDF no GitHub é o dicionário oficial. **Falta:** CI verde (CS-025) e a decisão do dono de tornar público | D-01; https://github.com/Patrickriibeiro/CartografiaESaude | Opus · low | repositório público, `CITATION.cff` reconhecido pelo GitHub |
| D-02 | O `23092026` no nome do arquivo é data da apresentação (já passou) ou prazo de entrega? Existe prazo real para o produto final? | — | ordem da F5/F6 |
| D-03 | Baixar CSV ou PARQUET do portal? PARQUET é menor e lê por coluna; CSV é o formato "clássico" que a banca conhece | PARQUET, com CSV como fallback | **Decidida 2026-09-25: PARQUET** (ADR-0001) |
| D-04 | Critério de caso: estrito (`CLASSI_FIN` + laboratório) como o PDF escreve, ou laboratorial puro? Co-detecção conta em cada vírus? | ~~Estrito, co-detecção conta em cada agente e é reportada~~ **Atualizada 2026-09-25 (ADR-0002, com números sobre 99.880 fichas):** regra **R2 vigilância** (`CLASSI_FIN` do agente + critério laboratorial declarado ou checkbox), porque a estrita perde 27 % → 5 % dos casos de COVID entre 2022 e 2025 só por checkbox em branco; **atribuição única** por `CLASSI_FIN`, co-detecção só reportada; contar toda ficha do banco sem filtrar internação. Três perguntas no ADR-0002 §8 | **Decidida 2026-09-25 (autora):** regra R2 "vigilância"; atribuição única pelo `CLASSI_FIN`, co-detecção só reportada; toda ficha do banco conta, sem filtrar internação (ADR-0002 aceito) | CS-008 destravado |
| D-05 | Denominador 2023 (IBGE não publicou estimativa): repetir Censo 2022, interpolar 2022–2024 ou outra? | Interpolar linearmente. **Atualizada 2026-09-25 (ADR-0003):** o Censo 2022 fica 3,1–8,4 % abaixo da estimativa de 2024 em todos os 92 municípios; há 4 opções no ADR. Implementada a interpolação como provisória | **Decidida 2026-09-25 (autora):** comparações entre anos com denominador único = estimativa 2024; mapa de cada ano com o número oficial daquele ano (Censo 2022, 2023 interpolado, estimativas 2024 e 2025); a outra versão como sensibilidade (ADR-0003 aceito) | CS-012 destravado |
| D-06 | "Por bairro" na seção 4.2 do PDF: erro de digitação ou intenção futura? | Tratar como município; registrar em ADR-0005 | **Decidida 2026-09-25 (autora):** município; "por bairro" era erro de digitação (ADR-0005 item 3) | — |
| D-07 | Data de corte do snapshot do banco 2025 (vivo, semanal). Uma vez fixada, o manifesto congela | Fixar na primeira execução real do CS-005 | **Decidida 2026-09-25: versão 14-09-2026** (ADR-0001) |
| D-08 | Agregação quadrimestral: entra como série temporal no relatório ou só a anual vai para LISA? | Anual no LISA; quadrimestral só em gráfico de linha | **Decidida 2026-09-25 (autora):** quadrimestre só descritivo (gráfico de linha); LISA anual (ADR-0005 item 3) | — |
| D-09 | Suavização empírica de Bayes: só comparação no relatório ou substitui a taxa bruta no LISA? | Reportar as duas; LISA sobre a suavizada | **Decidida 2026-09-25 (autora):** LISA sobre a taxa suavizada por Bayes empírico; taxa bruta como sensibilidade (entra no ADR-0004) | CS-013, CS-017 destravados |
| D-11 | Contagens pequenas (CS-043): publicar como está, com nota, ou suprimir/agrupar células com menos de 5 casos? | Publicar com nota: o microdado de origem já é público e anonimizado; suprimir apagaria 349 células sem ganho de proteção. **Aplicada como provisória em 2026-09-25** (relatório §5.3, LEIA-ME da exportação, `LIMIAR_CONTAGEM_PEQUENA`); se a autora preferir suprimir, muda `07_exportacao.R` e o painel | confirmação da autora |
| D-10 | A mestranda aceita os objetivos novos da proposta v2 (OE9 padronização por idade, OE10 leitos do CNES, escala de região de saúde, hipóteses H1–H4)? | Aceitar região de saúde e H1–H3; OE9/OE10 como opcionais | **Decidida 2026-09-25 (autora):** H1–H3 e escala de região de saúde no escopo; OE9, OE10 e H4 opcionais | CS-030 a CS-032 e CS-035 no escopo; CS-033/CS-034 opcionais |

---

## Abertos

### F0 — Fundação

| ID | Título | Evidência | Modelo · Esforço | Aceite |
|---|---|---|---|---|
| CS-029 | **Ecossistema `.claude/`** no padrão evidence: `CLAUDE.md` do projeto (constituição = PDF, invariantes §3.3 da trilha), hook `SessionStart` de contexto, hook que nega commit sem release-history. Adaptar, não copiar | memória do dono `ecossistema-segue-padrao-evidence` | Opus · medium | 2 hooks registrados; `CLAUDE.md` ≤ 150 linhas |

### F1 — ETL do SIVEP-Gripe

| ID | Título | Evidência | Modelo · Esforço | Aceite |
|---|---|---|---|---|
| CS-009 | *(parcialmente coberto: `preparar_sivep()` já para em data fora do ano, código fora do padrão, UF ≠ RJ e DT_SIN_PRI ausente; falta extrair as 4 funções nomeadas do PDF)* **`validar_variaveis()`, `validar_codigos_ibge()`, `validar_municipios_rj()`, `validar_datas()`** — falham alto (`stop()`) em: coluna faltante, código fora dos 92, data < 2022-01-01 ou > data do snapshot | PDF tabela de funções; `srag-intelligence-agent` PR #1 registra anos impossíveis (1695, 5202) | Opus · medium | 4 funções; cada uma com ≥ 2 testes (1 passa, 1 falha) |

### F2 — Indicadores

| ID | Título | Evidência | Modelo · Esforço | Aceite |
|---|---|---|---|---|

### F3 — Cartografia

| ID | Título | Evidência | Modelo · Esforço | Aceite |
|---|---|---|---|---|

### F4 — Estatística espacial

| ID | Título | Evidência | Modelo · Esforço | Aceite |
|---|---|---|---|---|

### F5 — Produtos

| ID | Título | Evidência | Modelo · Esforço | Aceite |
|---|---|---|---|---|

### F6 — Entrega e reprodutibilidade

| ID | Título | Evidência | Modelo · Esforço | Aceite |
|---|---|---|---|---|
| CS-026 | **Repositório público** — licença (D-01), `CITATION.cff`, README com badge da CI, link no PDF seção 4.5 | PDF §4.5 | Opus · low | URL público; `CITATION.cff` valida |

### Propostos pela proposta v2 (D-10 aceita em 2026-09-25: CS-030 a CS-032 e CS-035 no escopo; CS-033 e CS-034 opcionais)

| ID | Título | Evidência | Modelo · Esforço | Aceite |
|---|---|---|---|---|
| CS-033 | **Padronização por idade (OE9, opcional)** — SIDRA 9514 por faixa etária; método direto com padrão RJ 2022; `incid_pad_100k` para VSR e Influenza | proposta v2 §3.4; API 9514 verificada (134 linhas por município) | **Fable · medium** | coluna preenchida; gráfico bruta × padronizada; nota metodológica |
| CS-034 | **Leitos do CNES (OE10, opcional)** — `microdatasus` CNES-LT por município e ano (leitos SUS clínicos + UTI); Spearman entre taxa por residência e leitos por 100 mil, por ano e por região | proposta v2 §3.10; aqui o `microdatasus` cobre a fonte | Opus · medium | 4 coeficientes (um por ano) com IC; sem linguagem causal no relatório |

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

### Achados do CS-017

| ID | Título | Evidência | Modelo · Esforço | Aceite |
|---|---|---|---|---|
| CS-041 | **"Cluster de zeros" na taxa bruta** — no VSR 2022 (44 municípios sem caso) a taxa bruta dá Moran global p = 0,008 e 13 municípios LISA significativos; a suavizada dá p = 0,10 e 0. Investigar se os zeros se concentram em municípios sem unidade notificadora/laboratório (cruzar com `CO_MUN_NOT` e, se o CS-034 rodar, com o CNES); vira parágrafo da discussão (§5.1/§5.3) | ADR-0004 §4.1 · `lisa_concordancia.csv` | Opus · medium | tabela zeros × existência de notificação própria por município; parágrafo no relatório |

### Achados do CS-007

| ID | Título | Evidência | Modelo · Esforço | Aceite |
|---|---|---|---|---|

### Achados da auditoria final (CS-027)

| ID | Título | Evidência | Modelo · Esforço | Aceite |
|---|---|---|---|---|

### Fora do código (para a mestranda)

| ID | Título | Evidência | Modelo · Esforço | Aceite |
|---|---|---|---|---|
| CS-028 | **Seções vazias do PDF** — 1.1, 1.2 (contextualização, problematização), 6 (conclusão) e Apêndice A são texto científico; dependem de CS-022 para os números. Registrar aqui para que a trilha não "termine" com o relatório sem introdução | PDF: seções listadas sem conteúdo | Fable · medium (revisão) | rascunho entregue à mestranda; não é aceite de código |

---

## ADRs previstos

| ADR | Título | Nasce em |
|---|---|---|
| ADR-0001 | Extração do SIVEP-Gripe por download direto do portal (não `microdatasus`) | CS-005 · **escrito e aceito** (decide D-03 e D-07) |
| ADR-0002 | Critério de caso por agente e tratamento de co-detecção | CS-007 · **aceito 2026-09-25** |
| ADR-0003 | Denominador populacional por ano, incluindo 2023 | CS-011 · **aceito 2026-09-25** (implementação do denominador único no CS-012) |
| ADR-0004 | LISA: permutação, correção FDR, variável (bruta × EB), α | CS-017 · **escrito e aceito** (9.999 permutações; FDR-BH por mapa; dois níveis) |
| ADR-0006 | Malha oficial do IBGE em resolução completa, não o `geobr` simplificado | CS-014 · **escrito e aceito** |
| ADR-0007 | Nomes reais dos campos do SIVEP e chave de junção `cod6` (registro retroativo; fecha a cobertura dos 5 erros do PDF) | CS-027 · **escrito e aceito** |
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
| CS-008 | **Classificação por agente** — `classificar_agente()` (regra R2, atribuição única com trava) + `aplicar_criterios_inclusao()` (co-detecção, subtipo A/B); **37.562 casos** (SARS-CoV-2 24.087, influenza 5.536, VSR 7.939), idênticos à linha R2 da tabela do ADR-0002; o ETL para se divergir; subtipo tabulado | 2026-09-25 | `docs/release-history/cs-008-cs-010-classificacao.md` · commit `240e8a1` |
| CS-010 | **Base sintética** — `tests/gerar_fixture.R` (semente fixa) gera 210 fichas FABRICADAS, 92 municípios, 19 cenários com resposta esperada escrita à mão; 32 municípios sem caso; 7 testes de classificação em 1,1 s; a data inválida segue coberta em `test-sivep-etl.R` | 2026-09-25 | idem |
| CS-012 | **Casos e incidência** — `calcular_casos()`, `completar_municipios()`, `calcular_incidencia()`; grade anual **1.104 linhas** (92 × 3 × 4), quadrimestral 3.312; 37.562 casos preservados; 295 combinações com zero explícito; duas taxas da D-05 (`incid_100k` e `incid_100k_pop2024`); quadrimestre epidemiológico (semanas 1–17, 18–34, 35–53; adendo ao ADR-0005) | 2026-09-25 | `docs/release-history/cs-012-incidencia.md` · commit `3bba681` |
| CS-013 | **Suavização empírica de Bayes** — `suavizar_bayes_empirico()` (Marshall 1991, Poisson, por agente × ano, população do ano); `incid_eb_100k` em 1.104/1.104 linhas; conferida contra a fórmula à mão; guarda para agente × ano sem caso (0/0); dispersão bruta × suavizada e `docs/nota-metodologica-suavizacao.md` | 2026-09-25 | `docs/release-history/cs-013-suavizacao.md` · commit `4962c0b` |
| CS-017 | **ADR-0004 + `05_moran_lisa.R`** — Moran global (9.999 permutações, semente fixa, H1 positiva) e LISA (permutação condicional, p bicaudal, FDR-BH por mapa, dois níveis confirmado/indicativo, instáveis marcados); 12 globais × 3 rodadas (suavizada, bruta, Rook) e 92 × 12 locais em 32 s; global significativo em 6/12; só o VSR 2024 tem 5 confirmados | 2026-09-25 | `docs/release-history/cs-017-cs-018-moran-lisa.md` · ADR-0004 · commit `20dc23d` |
| CS-018 | **Testes de padrão conhecido** — tabuleiro (Rook: I < −0,9; Queen: ≈ 0), gradiente (I > 0,5), ruído em 20 sementes (≥ 15 com p > 0,05), bloco alto (HH confirmado), quadrantes à mão, embaralhar linhas não muda nada. Fechado junto com o CS-017, com aviso ao dono | 2026-09-25 | idem |
| CS-039 | **Efeito de borda** — decidido pela autora e implementado: `instavel` marca os 3 municípios de um vizinho; só Itatiaia aparece significativo (LH indicativo, influenza 2022 e 2024) | 2026-09-25 | idem · ADR-0004 §2.6 |
| CS-019 | **Mapas** — `mapa_incidencia()`, `mapa_lisa()` (9 categorias, dois níveis, hachura nos instáveis, confirmados nomeados), `tema_mapa()`, `hachurar()`; 12 + 12 PNG a 300 dpi e 2 painéis 3 × 4; inspeção visual pegou 2 defeitos que os testes não pegavam | 2026-09-25 | `docs/release-history/cs-019-mapas.md` · commit `d9f475e` |
| CS-020 | **Exportação para planilha** — `salvar_resultado()` (UTF-8 com BOM, `;`, `,`) e `escrever_carimbo()`; 4 CSV + LEIA-ME em `resultados/tabelas/exportacao/`; 17 expectativas | 2026-09-25 | `docs/release-history/cs-020-exportacao.md` · commit `e757212` |
| CS-022 | **Relatório e apresentação** — `08_relatorio.qmd` → HTML autocontido e revealjs; seções 4.1–4.5 e 5.1–5.3 do PDF; 9 tabelas e 3 figuras, todos os números calculados (teste de números digitados, com mutação); `referencias.bib` | 2026-09-25 | `docs/release-history/cs-022-cs-040-relatorio.md` · commit `486e549` |
| CS-040 | **Sensibilidade do critério de caso no relatório** — regra × agente × ano (literal, adotada, só classificação, detecção), tabela de co-detecção e nota dos 941 casos de 2022 com critério declarado sem resultado exportado | 2026-09-25 | idem |
| CS-021 | **Painel Shiny + leaflet** — agente × ano × camada, popup com 6 campos, 3 estados, instáveis tracejados; `testServer` em 24 estados; carga em 2 s. Não aberto no navegador embutido (permissão negada): inspeção visual fica com o dono | 2026-09-25 | `docs/release-history/cs-021-painel.md` · commit `968fd97` |
| CS-023 | **`run.R`** — 8 etapas isoladas, tempo por etapa em `resultados/execucao.log`, para no primeiro erro; `--limpar` refaz tudo em 97 s e os resultados versionados saem byte a byte idênticos | 2026-09-25 | `docs/release-history/cs-023-run.md` · commit `ce956b8` |
| CS-024 | **README de máquina nova** — roteiro em 5 passos executado num clone limpo: restore, 383 expectativas sem dados (6 testes pulados), pipeline com download real em 89 s, 491/491 depois, resultados iguais aos do repositório. Tempo de instalação numa máquina realmente nova não medido (pacotes vieram do cache) | 2026-09-25 | `docs/release-history/cs-024-maquina-nova.md` · commit `b0b1420` |
| CS-027 | **Auditoria final** — clone do GitHub reproduz tudo byte a byte (relatório inclusive); recálculo independente sem `spdep` e sem as funções do projeto: 118/118; ADRs × CSV: 86/86; HTML × CSV: 14/14; 0 residentes do RJ perdidos pelo filtro; 6 achados (ADR-0007 criado, aviso de caminho curto no README, errata no ADR-0004, 2 itens novos, 2 erros do próprio auditor); lista de 16 limitações | 2026-09-25 | `docs/release-history/cs-027-auditoria-final.md` · commit `96fc3a2` |
| CS-043 | **Contagens pequenas** — decisão provisória (D-11): publicar sem supressão, com nota no relatório §5.3 e no LEIA-ME da exportação; 349 combinações com 1 a 4 casos, contadas pelo código (`LIMIAR_CONTAGEM_PEQUENA`). Falta a confirmação da autora | 2026-09-25 | `docs/release-history/cs-043-cs-044-limitacoes.md` · commit `ac8853a` |
| CS-044 | **Limitações completas** — relatório §5.3 passa de 6 para 16 limitações, todas com números calculados (teste de números digitados verde); proposta v2 §3.10 com os itens 8 a 13 | 2026-09-25 | idem |
| CS-030 | **Escala de região de saúde** — tabela município → região do geobr 2025 (0 diferenças entre 2013 e 2025; 91/91 conferidos na SES-RJ), nomes canônicos pelo código; 9 regiões dissolvidas da malha IBGE; grade 108 linhas (37.562 casos, igual à municipal); vizinhança regional 14 pares = os implicados pelos municípios; Moran global descritivo (I < esperado em 11/12, p < 0,05 em 0/12), sem LISA; 12 mapas; 2 CSV; seção no relatório. Suíte 532/532 em 16 arquivos | 2026-09-25 | `docs/release-history/cs-030-regioes-de-saude.md` · commit `df78168` |
| CS-031 | **Residência × notificação** — complemento lido do banco (notificados no RJ de quem mora fora: 160 casos pela regra do ADR-0002); tabela 92 linhas com casos por residência (37.562) e por notificação (37.497), decomposição, razão e saldo; 13 importadores, top-10 no relatório; 7.286 casos (19,4 %) notificados em outro município do RJ; CSV exportado. Suíte 547/547 em 17 arquivos | 2026-09-25 | `docs/release-history/cs-031-residencia-notificacao.md` · commit `bfa1e24` |
| CS-032 | **Série por semana epidemiológica** — 209 semanas (domingo a sábado, de `DT_SIN_PRI`), estado + 9 regiões × 3 agentes com zero explícito (6.270 linhas; estado = soma das regiões = 37.562); 10 gráficos + painel; campanhas de influenza 2022–2025 com fonte oficial em `config/fontes.yml`; pico de influenza 2022 antes da campanha (semana 1), nos outros anos 2 a 5 semanas depois | 2026-09-25 | `docs/release-history/cs-032-cs-035-series.md` · commit `(a registrar)` |
| CS-035 | **Fichas não encerradas** — 1.028 · 481 · 760 · 138 (2,7 · 2,4 · 4,2 · 0,6 %); 2025 é o MENOR, sem subida nas últimas semanas (0,9 % × 0,6 %): o banco de 14/09/2026 já amadureceu, ao contrário do que o item supunha; gráfico semanal de 2025. Suíte 575/575 em 18 arquivos | 2026-09-25 | idem |
| CS-037 | **Proposta v2 atualizada com as decisões de dados** — §2.2 OE4, §3.2, §3.3 (critério de caso e co-detecção), §3.4 (denominador), §3.5 (malha), §3.10 (limitações 2, 6, 7) e referências; D-04 e D-05 continuam pendentes e o texto traz a **recomendação** marcada [REVISAR]. Não inclui o CS-036 (ano epidemiológico em §3.1) | 2026-09-25 | `docs/release-history/cs-037-cs-038-proposta-e-ibge.md` · commit `9cb75c1` |
| CS-038 | **Método de ajuste do IBGE citado** — Nota metodológica n. 01 das Estimativas 2024, p. 6–7: Censo 2022 ajustado pela PPE, maior ajuste em municípios grandes; citado no ADR-0003 e na proposta v2 | 2026-09-25 | idem |

## Descartados

| ID | Título | Motivo |
|---|---|---|
| — | *(nenhum ainda)* | |
