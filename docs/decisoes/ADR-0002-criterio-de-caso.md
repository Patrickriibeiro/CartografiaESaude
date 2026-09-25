# ADR-0002 — Critério de caso por agente e tratamento da co-detecção

- **Status:** **proposto**. Aguarda a decisão D-04 da autora. Enquanto isso, o CS-008 não
  produz `sivep_processado.parquet`.
- **Data:** 2026-09-25
- **Nasce em:** CS-007 · decide D-04
- **Evidência:** `resultados/tabelas/comparacao_regras_caso.csv`,
  `decomposicao_sem_campo_especifico.csv`, `codeteccao_por_regra.csv` e
  `diagnostico_sivep.csv`, todos gerados por `01_etl_sivep.R` a partir das 99.880 fichas de
  SRAG de residentes do RJ (bancos 2022–2025, versões do manifesto). As regras estão em
  código em `R/funcoes_sivep.R` (`REGRAS_CASO`), com 6 testes sobre fichas fabricadas de
  resposta conhecida.

## 1. Contexto

O PDF v1 (§3.2) define o caso como "encerrado como SRAG por agente viral (`CLASSI_FIN`)
com confirmação por RT-PCR ou teste rápido de antígeno". Isso combina dois tipos de
campo do SIVEP-Gripe:

- **`CLASSI_FIN`**, a classificação final que a vigilância dá ao encerrar o caso
  (1 influenza · 2 outro vírus respiratório · 3 outro agente · 4 não especificado ·
  5 covid-19; vazio = caso não encerrado), e **`CRITERIO`**, o critério desse
  encerramento (1 laboratorial · 2 clínico-epidemiológico · 3 clínico · 4 clínico-imagem).
- Os **campos de laboratório**: o resultado do teste (`PCR_RESUL` 1 = detectável;
  `RES_AN` 1 = positivo), e, dentro dele, o *checkbox* de **qual vírus** foi detectado
  (`PCR_SARS2`, `AN_SARS2`, `POS_PCRFLU`, `POS_AN_FLU`, `PCR_VSR`, `AN_VSR`; 1 = marcado,
  vazio = não marcado). Há ainda a sorologia para SARS-CoV-2 (`RES_IGG`, `RES_IGM`,
  `RES_IGA`).

A pergunta prática é: **o que conta como "confirmação"?** O checkbox do vírus, o
critério declarado pela vigilância, ou qualquer resultado positivo? As três leituras
dão números diferentes, e a diferença não é uniforme entre os anos.

## 2. Regras candidatas

| Regra | Definição (por agente) |
|---|---|
| **R1 estrita-PDF** | `CLASSI_FIN` do agente **e** checkbox do vírus marcado (leitura literal do PDF) |
| **R2 vigilância** | `CLASSI_FIN` do agente **e** (`CRITERIO` = laboratorial **ou** checkbox marcado) |
| **R3 qualquer evidência** | `CLASSI_FIN` do agente **e** (checkbox, resultado genérico positivo, sorologia reagente ou `CRITERIO` laboratorial) |
| **R4 classificação** | Só `CLASSI_FIN` do agente, inclusive encerramentos clínicos |
| **R5 laboratorial** | Só o checkbox do vírus, ignorando `CLASSI_FIN` (inclui fichas abertas e conta co-detecção em cada agente) |

Para o **VSR**, R1 a R4 são idênticas: `CLASSI_FIN = 2` significa "outro vírus
respiratório" (rinovírus, adenovírus, VSR...), então só o checkbox `PCR_VSR`/`AN_VSR`
diz que é VSR.

## 3. Evidência

### 3.1 Casos por regra, agente e ano

| Agente | Regra | 2022 | 2023 | 2024 | 2025 | Total |
|---|---|---|---|---|---|---|
| SARS-CoV-2 | R1 estrita-PDF | 13.551 | 3.251 | 2.026 | 1.038 | 19.866 |
| | R2 vigilância | 16.658 | 4.062 | 2.278 | 1.089 | 24.087 |
| | R3 qualquer evidência | 16.819 | 4.082 | 2.288 | 1.092 | 24.281 |
| | R4 classificação | 18.647 | 4.123 | 2.307 | 1.098 | 26.175 |
| | R5 laboratorial | 13.773 | 3.311 | 2.072 | 1.088 | 20.244 |
| Influenza | R1 estrita-PDF | 326 | 626 | 1.630 | 2.649 | 5.231 |
| | R2 vigilância | 384 | 671 | 1.727 | 2.754 | 5.536 |
| | R3 qualquer evidência | 387 | 673 | 1.728 | 2.758 | 5.546 |
| | R4 classificação | 422 | 697 | 1.785 | 2.771 | 5.675 |
| | R5 laboratorial | 383 | 669 | 1.683 | 2.687 | 5.422 |
| VSR | R1 = R2 = R3 = R4 | 1.169 | 921 | 2.037 | 3.812 | 7.939 |
| | R5 laboratorial | 1.231 | 950 | 2.116 | 4.020 | 8.317 |
| Fichas contadas em 2+ agentes | R1 a R4 | 0 | 0 | 0 | 0 | 0 |
| | R5 laboratorial | 89 | 41 | 58 | 117 | 305 |

### 3.2 A regra literal do PDF mede completude de preenchimento, não confirmação

Fichas encerradas como COVID (`CLASSI_FIN = 5`) **sem** o checkbox de SARS-CoV-2
marcado, e onde está o laboratório delas:

| Ano | Encerradas como COVID | Com checkbox | **Sem checkbox** | ...com resultado positivo genérico ou sorologia | ...só `CRITERIO` laboratorial declarado | ...clínico-epidemiológico | ...clínico ou imagem | ...critério vazio |
|---|---|---|---|---|---|---|---|---|
| 2022 | 18.647 | 13.551 | **5.096 (27,3 %)** | 2.327 | 941 | 106 | 1.509 | 213 |
| 2023 | 4.123 | 3.251 | **872 (21,1 %)** | 544 | 287 | 11 | 3 | 27 |
| 2024 | 2.307 | 2.026 | **281 (12,2 %)** | 205 | 57 | 5 | 5 | 9 |
| 2025 | 1.098 | 1.038 | **60 (5,5 %)** | 26 | 28 | 1 | 0 | 5 |

Três leituras:

1. **A perda da R1 cai de 27 % para 5 % entre 2022 e 2025.** Isso não é epidemiologia,
   é preenchimento: em 2022, 2.327 fichas têm um resultado de teste **positivo**
   (`PCR_RESUL` detectável ou `RES_AN` positivo, ou sorologia reagente) e foram encerradas
   como COVID, mas o *checkbox* "qual vírus" ficou em branco. Uma regra que dependa do
   checkbox fabrica uma queda extra de COVID ao longo do período, exatamente o que a
   hipótese H3 (dinâmica temporal) quer medir.
2. **A mudança de regra de 31/10/2022 aparece nos dados.** Os encerramentos clínicos e
   por imagem de COVID são 1.509 em 2022 e 3, 5 e 0 depois. O dicionário oficial diz que
   esses critérios deixaram de valer para COVID naquela data. A R4 (só classificação)
   inclui esses 1.509 e torna 2022 incomparável com os anos seguintes.
3. Para a Influenza o mesmo padrão existe em escala menor (96 → 122 fichas sem
   checkbox por ano, de 3 % a 10 % das encerradas como influenza).

### 3.3 Co-detecção

Entre os três agentes, uma ficha com checkbox de dois ou mais vírus é rara: 305 em
99.880 (0,3 %). Nas regras ancoradas na classificação (R1–R4) cada ficha tem **um**
`CLASSI_FIN`, então pertence a um único agente, o que a vigilância escolheu (o
dicionário manda priorizar o RT-PCR quando os métodos divergem). Só a R5 conta a
mesma ficha em dois agentes.

O campo oficial `CO_DETEC` não serve para isso: ele marca co-detecção com **qualquer**
vírus (rinovírus, adenovírus etc.) e está vazio em 65 % das fichas.

Sob a R2, as fichas do agente que também têm outro dos três vírus detectado, por ano:
SARS-CoV-2 83 · 32 · 39 · 57; Influenza 37 · 15 · 38 · 62; VSR 2 · 1 · 0 · 5.

### 3.4 Duas decisões secundárias, com os números

- **Internação.** O banco é de SRAG hospitalizada e óbitos, mas 1.023 fichas (1,0 %)
  dizem "não internado" (`HOSPITAL = 2`) e 2.161 (2,2 %) têm o campo ignorado ou vazio.
- **Fichas não encerradas** (`CLASSI_FIN` vazio): 1.028 · 481 · 760 · 138. O ano de
  2025 é o que tem **menos**, não mais, ao contrário do que a proposta v2 (§3.10)
  supunha. Neste snapshot, a maturação do banco não é a limitação principal.
- **Cobertura de testagem com resultado conclusivo** (RT-PCR ou antígeno): 87,5 % ·
  88,3 % · 89,6 % · 91,7 % das fichas. Cresce 4 pontos no período; qualquer regra
  laboratorial herda essa tendência.

## 4. Decisão proposta

1. **Regra R2 (vigilância) para os três agentes.** É a leitura do PDF que usa o campo
   onde a vigilância declara a confirmação (`CRITERIO = laboratorial`), aceitando o
   checkbox como evidência alternativa quando o critério falta. Exclui os encerramentos
   clínicos de 2022 (comparabilidade entre anos) e não depende da completude do
   checkbox (que muda entre anos).
2. **Cada ficha pertence a um único agente**, o do `CLASSI_FIN`. A co-detecção **não**
   conta duas vezes; é reportada como tabela (agente × ano × "com outro agente
   detectado"). *(Isso muda a recomendação inicial da D-04, que era contar em cada
   agente: aquela recomendação só faz sentido na R5.)*
3. **Toda ficha do banco SRAG conta**, sem filtrar `HOSPITAL`. A unidade é a notificação
   de SRAG; os 1,0 % "não internado" vão para a seção de limitações. O texto deve dizer
   "SRAG notificada" onde hoje diz "hospitalizada".
4. **Ano = ano epidemiológico do banco** (CS-036).
5. **Sensibilidade no relatório:** R1 (limite inferior) e R4 (limite superior) por
   agente × ano, e a R5 como "detecções por agente", que é a métrica dos boletins de
   positividade e a única que mostra co-detecção.

## 5. Alternativas descartadas

- **R1 (literal):** confunde checkbox em branco com ausência de confirmação; a perda
  varia de 27 % a 5 % entre anos.
- **R3:** difere da R2 em 194 fichas em 4 anos (0,7 % dos casos de COVID), todas com
  resultado positivo mas critério declarado não-laboratorial, ou seja, registros
  contraditórios. Não vale a complexidade extra de explicar sorologia e resultado
  genérico na metodologia.
- **R4:** inclui os 1.509 encerramentos clínicos de 2022 (regra que deixou de valer) e
  os 941 "laboratorial declarado sem resultado" (que a R2 também inclui; ver limitação).
- **R5:** descarta a decisão da vigilância; para o VSR, inclui 378 fichas que a
  vigilância encerrou como outro agente (96 como influenza, 85 como COVID, 165 como
  outro agente, 8 não especificado, 24 abertas). É medida de detecção, não de caso.

## 6. Limitações que a regra escolhida carrega

- 941 fichas de COVID em 2022 (5,6 % da R2 daquele ano) têm critério laboratorial
  declarado sem nenhum resultado nos campos exportados. A R2 confia na declaração da
  vigilância. A alternativa, exigir resultado visível, é a R1, que perde mais.
- Nenhuma regra corrige a variação de testagem entre municípios; isso fica para a
  discussão de vieses (proposta v2 §3.10, item 1).
- O subtipo A/B da influenza está disponível em mais de 99 % dos positivos por PCR e
  por antígeno (exploração; tabulação formal no CS-008).

## 7. Consequências

- CS-008: `classificar_agente()` = `aplicar_regra_caso(d, "R2_vigilancia")`; a coluna
  `codeteccao` marca "outro dos três agentes detectado"; testes sobre a fixture do CS-010.
- CS-037: reescrever a tabela de critério da proposta v2 §3.3 com a R2 e a atribuição
  única; trocar "hospitalizada" por "notificada".
- Relatório (CS-022): incluir as tabelas 3.1 e 3.2 e a de co-detecção.
- Se a autora escolher outra regra, basta trocar o nome em `classificar_agente()`; as
  tabelas comparativas continuam sendo geradas.

## 8. O que a autora decide (D-04)

1. Aceita a R2? Se preferir R1 ou R4, o relatório passa a ter a R2 como sensibilidade.
2. Aceita a atribuição única por `CLASSI_FIN`, com co-detecção só reportada?
3. Aceita contar toda ficha do banco, sem filtrar internação?
