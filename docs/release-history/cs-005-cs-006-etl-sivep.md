# CS-005 + CS-006 — Download e preparo do SIVEP-Gripe do RJ

- **Data:** 2026-09-25
- **Modelo · esforço:** Opus · medium (acordado com o dono)
- **Itens:** CS-005, CS-006 · ADR-0001 · decide D-03 (PARQUET) e D-07 (versão 14-09-2026)

## Verificação com número

| Critério de aceite | Resultado |
|---|---|
| Suíte completa | **93/93 expectativas em 29 testes, 3 arquivos**, 0 falhas |
| 4 bancos em `dados/brutos/` com hash no manifesto | 2022: 43.750.567 B · 2023: 22.121.151 B · 2024: 21.222.050 B · 2025: 26.831.527 B; cada tamanho idêntico ao `Content-Length` do servidor |
| 2ª chamada não rebaixa | 1ª: 3,1 s · 2ª: 0,4 s (só confere hash) |
| Retomada de download | teste simula queda aos 100 de 256 bytes; o arquivo final é idêntico à origem |
| 100 % das linhas com prefixo 33 | sim; e 100 % com 6 dígitos e `SG_UF = RJ` (o preparo para se não for) |
| 0 datas `NA` em `DT_SIN_PRI` | 0 em 99.880 |
| `CO_MUN_RES` é texto | `character` |
| Tempo por ano | 2022: 1,4 s · 2023: 0,5 s · 2024: 0,5 s · 2025: 0,6 s; `01_etl_sivep.R` inteiro: 5,7 s |
| Campos [CONFERIR] | 4 de 4 resolvidos contra o cabeçalho real e registrados no dicionário |
| `preparar_sivep()` confere o manifesto antes de ler | sim; teste com banco adulterado dá "SHA-256 divergente" |

## Fichas de SRAG de residentes do RJ por banco

| Banco | Fichas | Municípios com ficha | `SEM_PRI` divergente | Sintoma depois da digitação | `CLASSI_FIN` vazio | Residência ≠ notificação |
|---|---|---|---|---|---|---|
| 2022 | 38.726 | 92 | 0 | 17 | 1.028 | 8.040 |
| 2023 | 19.640 | 90 | 0 | 3 | 481 | 4.190 |
| 2024 | 18.190 | 91 | 0 | 0 | 760 | 4.117 |
| 2025 | 23.324 | 92 | 226 | 2 | 138 | 5.451 |

São todas as fichas de SRAG, não casos confirmados. A classificação por agente é o CS-008.

## Achados

1. **Datas em UTC.** Todas as 99.880 datas de início de sintomas estão à meia-noite UTC.
   A semana calculada em UTC bate com o `SEM_PRI` em 100 % (2022–2024); no fuso de
   Brasília, em 84–86 %, que é o esperado de errar um dia: muda a semana 1 vez em 7.
2. **Banco = ano epidemiológico.** 100 % das fichas de cada banco caem no ano
   epidemiológico do banco. Virou o CS-036.
3. **`SEM_PRI` errado em 226 fichas de 2025**, todas entre 28/12/2025 e 03/01/2026:
   vêm como semana 01, mas o calendário oficial (SMS-Rio) diz semana 53 de 2025.
4. **Bancos "congelados" republicados em 23/03/2026.**
5. **Para o ADR-0002:** 1.023 fichas com `HOSPITAL = 2`; `CLASSI_FIN` vazio não cresce em
   2025 (138, o menor dos quatro anos); `CO_DETEC` vazio em 65 %.
6. **Sem deriva de schema:** 194 colunas, mesmos nomes e tipos nos 4 anos.

## Decisões de implementação

- O ETL grava um **intermediário** (`dados/intermediarios/sivep_rj.parquet`, fora do git)
  com todas as fichas do RJ. A classificação (CS-008) lê dele, sem reler os bancos.
- **Parâmetros do estudo saíram do `00_setup.R`** e foram para
  `R/funcoes_utilitarias.R`, porque as funções dependem deles e os testes não rodam o
  setup.
- Campo de código com valor não numérico **para** o preparo (`para_inteiro()`), em vez
  de virar `NA` e se misturar com "não preenchido".
- Anomalias sem regra de correção (sintoma depois da digitação, semana divergente) são
  **contadas, não corrigidas**, em `resultados/tabelas/diagnostico_sivep.csv`.

## Erros do caminho

1. **Função dependendo de variável global.** Três testes falharam com "object
   'PREFIXO_UF_RJ' not found": a constante só existia depois do `00_setup.R`. Correção:
   parâmetros junto das funções.
2. **Teste que não pegava o que dizia pegar.** A mutação "converter data no fuso local"
   passou pelo teste do fuso. Causa: o banco sintético gravava `timestamp[us, tz=UTC]`,
   e o real é `timestamp[ns]` sem fuso. Correção: o sintético faz cast para o tipo real,
   e o teste confere o tipo. Depois disso, a mesma mutação é pega.
3. **Afirmação sem conferência.** O dicionário foi atualizado dizendo que `CS_SEXO` vem
   como `M/F/I` a partir de uma amostra de 4 linhas. Conferido depois na base inteira:
   F = 49.159, M = 50.698, I = 23, sem vazio.
