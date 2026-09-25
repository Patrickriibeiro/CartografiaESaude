# CS-012 — Casos e incidência por município, agente e ano

- **Data:** 2026-09-25
- **Modelo · esforço:** Opus · medium (acordado com o dono)
- **Itens:** CS-012 · aplica a D-05 (ADR-0003 aceito) · adendo ao ADR-0005 (quadrimestre)

## Verificação com número

| Critério de aceite | Resultado |
|---|---|
| Suíte completa | **241/241 expectativas em 72 testes, 8 arquivos**, 0 falhas |
| `nrow == 1104` (anual) | 1.104 (92 × 3 × 4) |
| Grade quadrimestral | 3.312 (92 × 3 × 4 × 3) |
| 0 `NA` | 0 em `casos`, `incid_100k` e `incid_100k_pop2024` |
| Município sem caso presente com 0 | 295 combinações anuais com zero caso |
| Soma preservada | 37.562 casos na grade = 37.562 casos classificados (anual e quadrimestral) |
| Teste: remover um município do input e ver a grade completar | sim; o município aparece nas 12 combinações, com zero |
| Mutação: tirar a linha que põe o zero | 6 de 11 testes do arquivo quebram |

## As duas taxas da D-05 na série do estado

| Agente | Ano | Casos | Por 100 mil (população do ano) | Por 100 mil (estimativa 2024) |
|---|---|---|---|---|
| SARS-CoV-2 | 2022 | 16.658 | 103,8 | 96,7 |
| | 2023 | 4.062 | 24,5 | 23,6 |
| | 2024 | 2.278 | 13,2 | 13,2 |
| | 2025 | 1.089 | 6,3 | 6,3 |
| Influenza | 2022 | 384 | 2,4 | 2,2 |
| | 2023 | 671 | 4,0 | 3,9 |
| | 2024 | 1.727 | 10,0 | 10,0 |
| | 2025 | 2.754 | 16,0 | 16,0 |
| VSR | 2022 | 1.169 | 7,3 | 6,8 |
| | 2023 | 921 | 5,5 | 5,3 |
| | 2024 | 2.037 | 11,8 | 11,8 |
| | 2025 | 3.812 | 22,1 | 22,1 |

O degrau do ADR-0003 aparece: em 2022 a taxa com o Censo fica cerca de 7 % acima da
taxa com a estimativa de 2024; em 2023, cerca de 3,5 %. Em 2024 as duas coincidem por
construção.

## Decisões de implementação

- **Quadrimestre epidemiológico** (semanas 1–17, 18–34, 35–53), coerente com o ano
  epidemiológico; registrado como adendo ao ADR-0005.
- A lista dos 92 municípios vem da tabela de população, e `completar_municipios()` para
  se um município com caso não estiver nela.
- `calcular_incidencia()` para se faltar população para qualquer linha da grade, em vez
  de produzir taxa `NA`.
- O resumo do estado soma casos e populações **antes** de dividir; a média das taxas
  municipais daria outro número, errado para o estado.

## Erros do caminho

Nenhum na implementação: os 241 testes passaram na primeira execução. Por isso a prova
de mutação foi feita na linha mais crítica (o zero explícito), para confirmar que os
testes não passavam por acaso.
