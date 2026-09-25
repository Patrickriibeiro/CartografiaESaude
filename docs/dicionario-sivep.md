# Dicionário SIVEP-Gripe — campos usados pelo projeto

Documento vivo (CS-004). Fonte única: o dicionário oficial do Ministério da Saúde,
guardado em `dados/externos/dicionario-srag-2019-a-2025.pdf` e registrado em
`dados/MANIFESTO.md` (SHA-256 `6b92d438…0e35`, 1.052.922 bytes).

- **Documento:** "Dicionário de Dados — Ficha de registro individual, casos de SRAG
  hospitalizados", 28 páginas, datado de **25/05/2023**.
- **Publicação no portal:** 29/01/2026, como dicionário dos bancos 2019 a 2025.
- **Numeração:** "Nº ficha" é o número do campo na ficha de notificação oficial.
  Difere da versão da SES-SP usada na análise inicial; vale esta.

> **Conferido contra os bancos reais (CS-006, 2026-09-25).** Os quatro bancos PARQUET
> (2022 a 2025) têm as mesmas **194 colunas**, com os mesmos nomes e os mesmos tipos. Os
> 37 campos abaixo existem nos quatro. As três dúvidas marcadas antes como [CONFERIR]
> foram resolvidas e estão indicadas como **[CONFERIDO]**.
>
> **Tipos no PARQUET:** 6 datas como `timestamp[ns]` sem fuso, à meia-noite UTC (ler
> com `tz = "UTC"`; ver ADR-0001); `CLASSI_FIN`, `CRITERIO` e `NU_IDADE_N` como
> `decimal128(3,0)`; os demais como texto. Nenhum campo de código tem valor não
> numérico nas 99.880 fichas do RJ.

## Onde o PDF v1 erra o nome

| No PDF v1 | Nome real | Por que importa |
|---|---|---|
| `CO_MUNIC_RES`, "sete dígitos" | `CO_MUN_RES`, `Varchar2(6)` | Coluna com o nome do PDF não existe; e o `geobr` tem 7 dígitos, então a junção exige truncar |
| `PCR_FLU` | `POS_PCRFLU` + `TP_FLU_PCR` | Influenza por RT-PCR é um Sim/Não mais um tipo A/B |
| *(não cita)* | `AN_SARS2`, `AN_VSR`, `POS_AN_FLU`, `TP_FLU_AN` | O PDF inclui o teste de antígeno no critério, mas não diz em quais campos |
| *(não cita)* | `CO-DETEC` | Existe um campo oficial de co-detecção |

## Tempo

| Campo | Nº ficha | Tipo | Domínio | Uso no projeto |
|---|---|---|---|---|
| `DT_NOTIFIC` | 1 | Date `DD/MM/AAAA` | data ≤ data da digitação | Fallback de `DT_SIN_PRI` |
| `SEM_NOT` | — (interno) | `Varchar2(6)` | ano + semana | Não usado |
| `DT_SIN_PRI` | 2 | Date `DD/MM/AAAA` | ≤ data da digitação e ≤ `DT_NOTIFIC` | **Data de referência do caso** (define o ano) |
| `SEM_PRI` | — (interno) | `Varchar2(6)` | semana epidemiológica dos 1ºs sintomas, calculada de `DT_SIN_PRI`. No PARQUET vem só a semana (ex.: `"01"`), sem o ano | Só conferência: o projeto recalcula a semana de `DT_SIN_PRI`, porque o banco de 2025 rotula a semana 53 como `01` (226 fichas do RJ; ADR-0001) |
| `DT_ENCERRA` | 84 | Date | ≥ data do preenchimento; obrigatório se `CLASSI_FIN` preenchido | Mede maturação do banco |
| `DT_DIGITA` | — | Date | data de digitação | Teto de plausibilidade das outras datas |

## Lugar

| Campo | Nº ficha | Tipo | Domínio | Uso no projeto |
|---|---|---|---|---|
| `SG_UF_NOT` | 3 | `Varchar2(2)` | sigla da UF da unidade notificadora | Não usado |
| `CO_MUN_NOT` | 4 | `Varchar2(6)` | código IBGE do município da unidade notificadora | Comparação residência × notificação (CS-031) |
| `SG_UF` | 23 | `Varchar2(2)` | UF de residência; obrigatório se país = Brasil | Conferência: tem de ser `RJ` quando `CO_MUN_RES` começa com 33 |
| `CO_MUN_RES` | 24 | `Varchar2(6)` | código IBGE do município de residência; obrigatório se país = Brasil. No PARQUET: texto, sempre 6 dígitos no RJ | **Filtro espacial e chave de junção** (prefixo `33`, tratado como texto) |
| `CO_MU_INTE` | 51 | `Varchar2(20)` | município de internação; habilitado se `HOSPITAL = 1` | Não usado nesta fase |

## Pessoa

| Campo | Nº ficha | Tipo | Domínio | Uso no projeto |
|---|---|---|---|---|
| `CS_SEXO` | 11 | `Varchar2(1)` | 1-Masculino, 2-Feminino, 9-Ignorado no dicionário; **[CONFERIDO] no PARQUET vem como letra: `M`, `F`, `I`** | Descritivo |
| `NU_IDADE_N` | 13 | `Varchar2(3)` | idade, ≤ 150 | Faixas etárias (OE9) |
| `TP_IDADE` | 13 | `Varchar2(1)` | 1-Dia, 2-Mês, 3-Ano | **Obrigatório para ler `NU_IDADE_N`**: "6" pode ser 6 dias ou 6 anos |

## Internação

| Campo | Nº ficha | Tipo | Domínio | Uso no projeto |
|---|---|---|---|---|
| `HOSPITAL` | 48 | `Varchar2(1)` | 1-Sim, 2-Não, 9-Ignorado; se ≠ 1 o sistema avisa que não atende a definição de caso | Conferência de definição de caso |
| `DT_INTERNA` | 49 | Date | ≥ `DT_SIN_PRI` | Não usado nesta fase |

## Laboratório: teste de antígeno

| Campo | Nº ficha | Tipo | Domínio | Uso no projeto |
|---|---|---|---|---|
| `TP_TES_AN` | 65 | `Varchar2(1)` | tipo do teste antigênico | Não usado |
| `RES_AN` | 67 | `Varchar2(1)` | 1-Positivo, 2-Negativo, 3-Inconclusivo, 4-Não realizado, 5-Aguardando resultado, 9-Ignorado | Contexto |
| `POS_AN_FLU` | 69 | `Varchar2(1)` | 1-Sim, 2-Não, 9-Ignorado | **Critério Influenza** |
| `TP_FLU_AN` | 69 | `Varchar2(1)` | 1-Influenza A, 2-Influenza B; habilitado se `POS_AN_FLU = 1` | Subtipo A/B |
| `POS_AN_OUT` | 69 | `Varchar2(1)` | 1-Sim, 2-Não, 9-Ignorado | Porta de entrada de `AN_SARS2` e `AN_VSR` |
| `AN_SARS2` | 69 | `Varchar2(1)` | 1-marcado; **vazio = não marcado**; habilitado se `POS_AN_OUT = 1` | **Critério SARS-CoV-2** |
| `AN_VSR` | 69 | `Varchar2(1)` | 1-marcado; **vazio = não marcado**; habilitado se `POS_AN_OUT = 1` | **Critério VSR** |

## Laboratório: RT-PCR ou outro método molecular

| Campo | Nº ficha | Tipo | Domínio | Uso no projeto |
|---|---|---|---|---|
| `PCR_RESUL` | 70 | `Varchar2(1)` | 1-Detectável, 2-Não detectável, 3-Inconclusivo, 4-Não realizado, 5-Aguardando resultado, 9-Ignorado | Contexto e taxa de testagem |
| `POS_PCRFLU` | 72 | `Varchar2(1)` | 1-Sim, 2-Não, 9-Ignorado | **Critério Influenza** |
| `TP_FLU_PCR` | 72 | `Varchar2(1)` | 1-Influenza A, 2-Influenza B; habilitado se `POS_PCRFLU = 1` | Subtipo A/B |
| `POS_PCROUT` | 72 | `Varchar2(1)` | 1-Sim, 2-Não, 9-Ignorado | Porta de entrada de `PCR_SARS2` e `PCR_VSR` |
| `PCR_SARS2` | 72 | `Varchar2(1)` | 1-marcado; **vazio = não marcado**; habilitado se `POS_PCROUT = 1`. O PDF oficial grafa `PCR_ SARS2`, com espaço; **[CONFERIDO] no PARQUET o nome é `PCR_SARS2`** | **Critério SARS-CoV-2** |
| `PCR_VSR` | 72 | `Varchar2(1)` | 1-marcado; **vazio = não marcado**; habilitado se `POS_PCROUT = 1` | **Critério VSR** |

## Laboratório: sorologia para SARS-CoV-2

Acrescentados no CS-007, só para medir a evidência laboratorial das fichas sem o
checkbox do vírus (regra R3 do ADR-0002). Não entram na regra recomendada.

| Campo | Nº ficha | Tipo | Domínio | Uso no projeto |
|---|---|---|---|---|
| `RES_IGG` | 76 | `Varchar2(1)` | resultado da sorologia IgG; no banco aparecem 1, 2, 4 e 9; o projeto lê **1 = reagente** | Evidência laboratorial alternativa (ADR-0002, R3) |
| `RES_IGM` | 76 | `Varchar2(1)` | idem, IgM | idem |
| `RES_IGA` | 76 | `Varchar2(1)` | idem, IgA | idem |

## Classificação e desfecho

| Campo | Nº ficha | Tipo | Domínio | Uso no projeto |
|---|---|---|---|---|
| `CO_DETEC` | 79 | `Varchar2(1)` | 1-Sim, 2-Não, 9-Ignorado ("dois tipos de vírus ao mesmo tempo"). O dicionário grafa `CO-DETEC`; **[CONFERIDO] no PARQUET o nome é `CO_DETEC`** | **Não usado:** marca co-detecção com qualquer vírus (rinovírus etc.) e está vazio em 65 % das fichas; das 305 fichas com dois dos três agentes do estudo, só 76 têm `CO_DETEC = 1` (ADR-0002 §3.3) |
| `CLASSI_FIN` | 80 | `Varchar2(1)` | 1-SRAG por influenza, 2-SRAG por outro vírus respiratório, 3-SRAG por outro agente etiológico, 4-SRAG não especificado, 5-SRAG por covid-19. **Sem código 9.** Se os métodos divergirem, prioriza-se o RT-PCR | **Critério de caso** (ADR-0002). Vazio = caso não encerrado |
| `CRITERIO` | 81 | `Varchar2(1)` | 1-Laboratorial, 2-Clínico epidemiológico, 3-Clínico, 4-Clínico imagem | Descritivo; ver nota abaixo |
| `EVOLUCAO` | 82 | `Varchar2(1)` | 1-Cura, 2-Óbito, 3-Óbito por outras causas, 9-Ignorado | Não usado nesta fase |
| `DT_EVOLUCA` | 83 | Date | ≥ `DT_SIN_PRI` | Não usado nesta fase |

## Quatro consequências para o critério de caso (entrada do ADR-0002)

0. **O checkbox do vírus mede preenchimento, não confirmação.** Em 2022, 2.327 fichas
   encerradas como COVID têm resultado de teste positivo, mas o "qual vírus" em branco;
   a proporção de fichas sem checkbox cai de 27 % (2022) para 5 % (2025). Medido no
   CS-007; é o achado central do ADR-0002.

1. **"Vazio" tem dois sentidos diferentes.** Em `PCR_SARS2`, `PCR_VSR`, `AN_SARS2` e
   `AN_VSR`, vazio quer dizer "não marcado" (negativo ou não avaliado). Em
   `CLASSI_FIN`, vazio quer dizer "caso ainda não encerrado". Tratar os dois do mesmo
   jeito subestima 2025.
2. **SARS-CoV-2 e VSR ficam aninhados.** Os campos de SARS-CoV-2 e VSR só são
   habilitados quando "positivo para outros vírus" (`POS_PCROUT` ou `POS_AN_OUT`) é Sim.
   A regra de caso pode ler só o campo do vírus; a porta de entrada serve de
   conferência de consistência.
3. **Mudança de regra em 31/10/2022.** O dicionário diz que os critérios 3-Clínico e
   4-Clínico imagem deixaram de encerrar SRAG por covid-19 nessa data, e que o
   clínico-imagem nunca vale para Influenza, outros vírus e outros agentes. Portanto,
   parte dos casos de COVID de jan–out/2022 pode ter `CLASSI_FIN = 5` sem confirmação
   laboratorial. A regra estrita do PDF (classificação **e** laboratório) exclui esses
   casos, o que mantém 2022 comparável com 2023–2025. O ADR-0002 deve quantificar
   quantos são.

## Limite deste documento

O dicionário é de maio de 2023. A conferência do CS-006 mostrou que os quatro bancos
têm o mesmo conjunto de 194 colunas, então não houve campo novo entre 2022 e 2025. As
160 colunas não usadas não estão documentadas aqui.
