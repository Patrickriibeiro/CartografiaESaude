# CS-008 + CS-010 — Classificação por agente e base sintética de testes

- **Data:** 2026-09-25
- **Modelo · esforço:** Opus · medium (acordado com o dono)
- **Itens:** CS-008, CS-010 · aplica o ADR-0002 aceito (D-04)

## Verificação com número

| Critério de aceite | Resultado |
|---|---|
| Suíte completa | **203/203 expectativas em 61 testes, 7 arquivos**, 0 falhas |
| Contagem por agente × ano idêntica à linha R2 do ADR-0002 | 12/12 células idênticas; o `01_etl_sivep.R` para se alguma divergir |
| `sivep_processado.parquet` com ≥ 1 linha por ano | 37.562 casos; os 4 anos presentes |
| Subtipo A/B tabulado | `resultados/tabelas/subtipo_influenza.csv` |
| CS-010: base sintética FABRICADA com semente | 210 fichas, 92 municípios, 19 cenários, 4 anos; 100 % com rótulo FABRICADO |
| CS-010: testes rodam em < 5 s sem rede | 7 testes de classificação em 1,1 s; o caminho PARQUET → preparo → classificação medido dentro do teste |
| Mutação: trocar a regra por R1 é pego | sim, 4 testes falham |

## Casos por agente e ano (regra R2)

| Agente | 2022 | 2023 | 2024 | 2025 | Total |
|---|---|---|---|---|---|
| SARS-CoV-2 | 16.658 | 4.062 | 2.278 | 1.089 | 24.087 |
| Influenza | 384 | 671 | 1.727 | 2.754 | 5.536 |
| VSR | 1.169 | 921 | 2.037 | 3.812 | 7.939 |

Subtipo da influenza (A / B / sem subtipo): 2022 298/27/59 · 2023 357/269/45 ·
2024 1.343/286/98 · 2025 2.458/188/108. "Sem subtipo" são os casos que entraram pelo
critério laboratorial declarado, sem o campo do vírus marcado.

## Decisões de implementação

- **A resposta esperada da base sintética é escrita à mão**, por cenário, em
  `tests/gerar_fixture.R`. Se ela fosse calculada pelas mesmas funções, o teste só
  confirmaria que o código concorda consigo mesmo.
- **Trava de atribuição única** em `classificar_agente()`: se uma regra marcar a mesma
  ficha em dois agentes, a função para. Com a R2 isso não ocorre; a trava protege contra
  uma troca futura de regra (testado com a R5).
- **Regra em um só lugar:** `REGRA_CASO <- "R2_vigilancia"` nos parâmetros do estudo.
- O construtor de banco PARQUET falso foi para o helper dos testes, compartilhado pelos
  testes do ETL e da classificação.
- A base sintética tem 32 municípios sem nenhum caso, que o CS-012 usará para testar o
  zero explícito da grade.

## Fora do escopo, registrado

- CS-009 (funções de validação nomeadas do PDF) continua aberto; o BACKLOG anota que o
  preparo já cobre as mesmas travas.

## Erros do caminho

1. O leitor da base sintética quebrou porque o CSV não tem todas as colunas do SIVEP.
   Correção: completar as ausentes como vazias, como no banco real.
2. Uma asserção sobre "municípios sem caso" estava escrita de forma confusa e errada.
   Reescrita como duas afirmações diretas.
3. O bloco de diagnóstico do teste ficha a ficha imprimia uma tabela vazia (lógica
   errada). Trocado por uma checagem por cenário, que diz qual situação divergiu.
