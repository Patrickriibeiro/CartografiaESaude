# CS-052 — Decisões de método (ADRs) integradas ao texto

- **Data:** 2026-09-26
- **Modelo · esforço:** Fable · medium (acordado com o dono)
- **Origem:** pedido da analista: "integrar ADRs ao projeto de texto"

## Verificação com número

| Critério de aceite | Resultado |
|---|---|
| 7 ADRs cobertos | relatório: seção nova "Decisões de método", uma subseção por ADR (0001 a 0007), em linguagem de artigo: o que foi decidido, por quê, alternativa descartada |
| Tabela de rastreio ADR → parágrafo | proposta v2, §3.11 nova; ADR-0005 e ADR-0007, que não apareciam na proposta, entraram em §3.7 e §3.3 |
| Teste | `test-relatorio.R`: todo `ADR-NNNN` de `docs/decisoes/` é citado no relatório e na proposta v2, e a seção existe (falha se um ADR novo não entrar no texto) |
| 0 números digitados | os números da seção vêm de objetos do pipeline: 37 colunas lidas, versões dos bancos, perda da regra literal (19 % em 2022, 5 % em 2025), razão estimativa/Censo (3,1 % a 8,4 %), 228 pares de vizinhos, 9.999 permutações, limiar FDR (0,00054), 3 instáveis, 8 scripts |
| Testes | 757/757 expectativas em 23 arquivos, 0 falhas (eram 741) |

## Nota sobre um número

A proposta v2 §3.3 diz que a regra literal perde "27 % (2022) a 5 % (2025)" **entre as fichas
encerradas como COVID**; a seção do relatório diz "19 % dos casos de SARS-CoV-2 de 2022", que é a
perda **em relação aos casos da regra adotada** (R2). São denominadores diferentes e os dois
estão certos; o relatório calcula o seu.

## Erros do caminho

1. Três números digitados escaparam ("999" duas vezes, "92 polígonos"); passaram a variáveis
   do chunk.
2. A tabela de rastreio foi inserida como "§3.9a" antes da §3.10; movida para uma §3.11 no fim
   dos métodos.
