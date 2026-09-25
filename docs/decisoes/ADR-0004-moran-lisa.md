# ADR-0004 — Moran global e LISA: permutações, correção para testes múltiplos, variável e instabilidade

- **Status:** aceito (as escolhas D-09 e CS-039 já eram da autora; o restante é técnico e
  segue o que a proposta v2 §3.6 descreve, com dois refinamentos registrados aqui)
- **Data:** 2026-09-25
- **Nasce em:** CS-017 · implementa a D-09 e o CS-039
- **Evidência:** `resultados/estatistica/moran_global.csv`, `lisa_municipios.csv`,
  `lisa_resumo.csv`, `lisa_concordancia.csv` (gerados por `05_moran_lisa.R`);
  funções em `R/funcoes_espaciais.R` com testes de padrão conhecido em
  `tests/testthat/test-moran-lisa.R`.

## 1. Contexto

O PDF v1 (§3.4) pede: contiguidade Queen, Moran Global testado por Monte Carlo
(p < 0,05) e, confirmada a autocorrelação, o Moran Local (LISA) em quatro classes mais
"não significativo". Ficaram por decidir: o número de permutações, a variável (bruta ou
suavizada), como tratar os 92 testes simultâneos do LISA, o que fazer com os municípios
de um único vizinho, e que sensibilidades reportar.

## 2. Decisões

1. **Variável principal: taxa suavizada por Bayes empírico** (`incid_eb_100k`, D-09),
   com a população oficial do ano. A taxa bruta é sensibilidade obrigatória no relatório.
2. **Vizinhança Queen de 1ª ordem, pesos padronizados por linha** (CS-016, 456 ligações
   da malha oficial). Rook entra como sensibilidade só no Moran global.
3. **Moran global por permutação, 9.999 permutações, hipótese alternativa "maior"**
   (autocorrelação positiva, que é a H1 da proposta). Semente fixa (`SEMENTE`) antes de
   cada cálculo, para que a ordem de execução não altere o resultado.
4. **LISA por permutação condicional, 9.999 permutações, p bicaudal da simulação**
   (`localmoran_perm`, `Pr(z != E(Ii)) Sim`), quadrante pelo diagrama de Moran com
   valores centrados na média.
5. **Correção para testes múltiplos por Benjamini-Hochberg (FDR) em α = 0,05, por
   mapa** (92 testes). O LISA sai em **dois níveis**:
   - **confirmado**: significativo após a correção;
   - **indicativo**: significativo só sem correção (p < 0,05);
   - **ns**: o resto.
   A classe (HH, LL, HL, LH) só é atribuída aos dois primeiros níveis. O mapa mostra os
   dois níveis com intensidades diferentes; a tabela conta os dois.
6. **Instabilidade (CS-039):** Paraty, Itatiaia e Armação dos Búzios (um único vizinho)
   mantêm a classe, marcada como `instavel`; no mapa, com hachura; no texto, citados na
   limitação de efeito de borda.
7. **Alinhamento pela chave `cod6`**, nunca pela posição da linha. A função para se o
   dado tiver município a mais, a menos ou repetido.

## 3. Por que 9.999 permutações e não 999

Com 999 permutações o menor p possível é 0,001. O limiar mais exigente do FDR para
92 testes é 0,05/92 = 0,00054. Logo, com 999 permutações, o município mais extremo do
mapa **nunca** poderia ser confirmado sozinho: só se dois empatassem em p = 0,001.
A correção ficaria decidida pela resolução da simulação, não pelo dado. Com 9.999
permutações a resolução é 0,0001, abaixo do limiar. Custo: 12 combinações × 3 rodadas
(suavizada, bruta, Rook) em 32 s.

## 4. O que os dados mostram

### 4.1 Moran global (I; p por permutação)

| Agente | Ano | Suavizada, Queen | Bruta, Queen | Suavizada, Rook |
|---|---|---|---|---|
| SARS-CoV-2 | 2022 | 0,078 (0,095) | 0,059 (0,145) | 0,074 (0,108) |
| | 2023 | **0,113 (0,040)** | **0,123 (0,032)** | 0,103 (0,052) |
| | 2024 | 0,087 (0,068) | 0,027 (0,222) | 0,087 (0,069) |
| | 2025 | **0,180 (0,009)** | **0,192 (0,004)** | **0,194 (0,007)** |
| Influenza | 2022 | **0,167 (0,015)** | **0,201 (0,004)** | **0,165 (0,016)** |
| | 2023 | **0,208 (0,003)** | **0,240 (0,001)** | **0,219 (0,002)** |
| | 2024 | 0,077 (0,095) | **0,128 (0,033)** | 0,084 (0,083) |
| | 2025 | **0,163 (0,013)** | **0,123 (0,034)** | **0,171 (0,011)** |
| VSR | 2022 | 0,066 (0,103) | **0,187 (0,008)** | 0,071 (0,095) |
| | 2023 | −0,010 (0,410) | 0,064 (0,090) | 0,007 (0,285) |
| | 2024 | **0,326 (0,0001)** | **0,439 (0,0001)** | **0,332 (0,0001)** |
| | 2025 | 0,094 (0,073) | **0,147 (0,021)** | 0,096 (0,070) |

Negrito: p < 0,05. Valor esperado sob aleatoriedade: −1/91 = −0,011.

- A autocorrelação é **fraca a moderada** (I ≤ 0,33) e significativa em **6 de 12**
  mapas com a suavizada. Rook concorda com Queen em 11 de 12 (SARS-CoV-2 2023 fica no
  limiar: 0,052).
- **A taxa bruta encontra mais autocorrelação que a suavizada** (9 de 12 significativos),
  e a diferença é maior onde há mais municípios sem caso: VSR 2022 (44 municípios com
  zero caso; bruta p = 0,008, suavizada p = 0,10). Municípios pequenos vizinhos, todos
  com zero caso, formam um "cluster de zeros" na taxa bruta; a suavização, que puxa cada
  zero para perto da média com força que depende da população, desfaz esse cluster.
  Zero caso em município pequeno é, em boa parte, ausência de notificação ou de
  testagem, não de doença; por isso a suavizada é a principal e a bruta é sensibilidade.

### 4.2 LISA

| Agente | Ano | Signif. sem correção | Confirmados (FDR) | HH conf. | LL conf. | HH indic. | LL indic. |
|---|---|---|---|---|---|---|---|
| SARS-CoV-2 | 2022 | 9 | 0 | 0 | 0 | 4 | 3 |
| | 2023 | 9 | 0 | 0 | 0 | 1 | 4 |
| | 2024 | 6 | 0 | 0 | 0 | 0 | 4 |
| | 2025 | 12 | 0 | 0 | 0 | 4 | 4 |
| Influenza | 2022 | 12 | 0 | 0 | 0 | 5 | 5 |
| | 2023 | 8 | 0 | 0 | 0 | 2 | 5 |
| | 2024 | 11 | 0 | 0 | 0 | 2 | 4 |
| | 2025 | 6 | 0 | 0 | 0 | 1 | 4 |
| VSR | 2022 | 0 | 0 | 0 | 0 | 0 | 0 |
| | 2023 | 6 | 0 | 0 | 0 | 1 | 2 |
| | 2024 | 12 | **5** | **3** | 1 | 6 | 0 |
| | 2025 | 8 | 0 | 0 | 0 | 4 | 1 |

Esperado por acaso, sem correção: 92 × 0,05 = **4,6 municípios por mapa**.

- **Só o VSR de 2024 tem agrupamentos confirmados:** Tanguá (p = 0,0004), Itaboraí e
  Maricá como Alto-Alto (o eixo leste da Baía de Guanabara, Metropolitana II),
  Comendador Levy Gasparian como Baixo-Baixo e Petrópolis como Alto-Baixo.
- Nos outros 11 mapas, os significativos sem correção ficam entre 0 e 12, contra 4,6
  esperados por acaso: há sinal em alguns (influenza 2022, SARS-CoV-2 2025), mas nenhum
  município individual sobrevive à correção. O mapa mostra esses como **indicativos**.
- Entre os instáveis, só Itatiaia aparece significativo (Baixo-Alto, indicativo, na
  influenza de 2022 e 2024). A classe dele compara com Resende apenas.
- Concordância de classe entre suavizada e bruta: 85 % a 98 % por mapa. A maior
  divergência é o VSR 2022: 13 municípios significativos só na bruta, 0 na suavizada.

## 5. Consequências para o relatório e para as hipóteses

- **H1** (autocorrelação positiva em ao menos um ano) se sustenta para os três agentes,
  com I fraco.
- **H2** (hotspots diferentes por agente) só tem base confirmada no VSR 2024; para os
  demais, o relatório fala em "áreas indicativas" e não em hotspots.
- **H3** (mudança no tempo) fica limitada pela fraqueza do sinal; a tabela de níveis por
  ano é a evidência, não o mapa.
- O relatório traz: a tabela 4.1 com as três colunas; a tabela 4.2; mapas LISA com dois
  níveis e hachura nos instáveis (CS-019); e a concordância suavizada × bruta.
- Nenhum resultado aqui é causal; a discussão (§5.1 da proposta) relaciona o eixo de
  Metropolitana II à estrutura assistencial e etária, como hipótese.

## 6. Alternativas descartadas

- **Sem correção como resultado principal:** 4,6 falsos positivos esperados por mapa;
  12 mapas gerariam ~55 "hotspots" por acaso.
- **Bonferroni:** α/92 = 0,00054 por teste; mais conservador que o FDR e sem ganho,
  dado que já sobra pouco.
- **Correção global sobre os 12 mapas (1.104 testes):** apagaria até o VSR 2024;
  a pergunta é por mapa (onde estão os agrupamentos daquele agente naquele ano).
- **999 permutações:** ver §3.
- **p unilateral no LISA:** a classe já diz o sentido; o p bicaudal é o padrão do
  `spdep` (`hotspot()`) e mais conservador.
- **Excluir os 3 municípios de um vizinho:** criaria buracos no mapa e mudaria a
  vizinhança dos outros; marcar é mais honesto.

## 7. Limitações

- Efeito de borda: a matriz ignora vizinhos em SP, MG e ES (CS-039).
- A suavização global e o LISA usam a mesma malha, mas não a mesma vizinhança (a
  suavização puxa para a média do estado, não dos vizinhos); ver nota do CS-013.
- Com 92 unidades, o poder do LISA é baixo; ausência de confirmação não é ausência
  de agrupamento.
