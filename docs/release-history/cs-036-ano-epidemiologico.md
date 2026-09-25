# CS-036 — O "ano" do estudo é o ano epidemiológico

- **Data:** 2026-09-25
- **Modelo · esforço:** Opus · low (acordado com o dono)
- **Origem:** ADR-0001, "Fatos descobertos"; a proposta v2 falava em "01/01/2022"

## Verificação com número

| Critério de aceite | Resultado |
|---|---|
| Proposta v2 §3.1 corrigida | parágrafo novo com os limites dos 4 anos e as 53 semanas de 2025 |
| Proposta v2 §3.3 corrigida | "Seleção temporal" reescrita: não há substituição por `DT_NOTIFIC` nem corte em 01/01/2022, como o texto dizia; o pipeline exige `DT_SIN_PRI` e confere ano epidemiológico = ano do banco |
| Nota no relatório | limites de cada ano, peso da semana 53 e distância do denominador, todos calculados |
| ADR-0003 cita a convenção | nota "Convenção de datas (CS-036)" no Contexto |
| Testes | 581/581 expectativas em 18 arquivos, 0 falhas (eram 575); +6 no teste de `limites_ano_epi()` |

## Números

| Ano | Início | Fim | Dias | Meio do ano × 1º de julho |
|---|---|---|---|---|
| 2022 | 02/01/2022 | 31/12/2022 | 364 | −2 dias (o Censo é de 01/08: +29) |
| 2023 | 01/01/2023 | 30/12/2023 | 364 | −1 |
| 2024 | 31/12/2023 | 28/12/2024 | 364 | +1 |
| 2025 | 29/12/2024 | 03/01/2026 | 371 | −1 |

A semana 53 de 2025 soma 28 casos (0,4 % do ano): a taxa de 2025 a inclui sem desconto, e o
efeito é desprezível.

## Achados

- O BACKLOG dizia "diferença de no máximo 3 dias"; o máximo medido é 2 — mas o denominador
  de 2022 é o Censo, de 1º de agosto, a 29 dias do meio do ano. Documentado no ADR-0003 como
  desprezível diante do degrau de 7,3 % entre Censo e estimativa.
- A §3.3 da proposta descrevia uma regra que o código nunca implementou (data de notificação
  como substituta e corte em 01/01/2022). O texto passou a descrever o código.

## Erros do caminho

Nenhum.
