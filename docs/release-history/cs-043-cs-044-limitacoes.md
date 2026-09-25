# CS-043 + CS-044 — Contagens pequenas e limitações completas

- **Data:** 2026-09-25
- **Modelo · esforço:** Opus · low (acordado com o dono)
- **Origem:** achados 4 e 5 e lista consolidada de limitações da auditoria final (CS-027)

## Verificação com número

| Critério de aceite | Resultado |
|---|---|
| CS-044: 16 itens no §5.3, todos com número lido de `resultados/` | 16 limitações no §5.3 (eram 6); as 10 novas usam 11 valores calculados |
| Teste de números digitados | 13/13 expectativas, 0 falhas |
| Renderização | 0 avisos |
| Proposta v2 §3.10 | itens 8 a 13 acrescentados |
| CS-043: decisão registrada | D-11, provisória: publicar com nota; 349 combinações com 1 a 4 casos |

## As 10 limitações novas no relatório

Residência × notificação (8.040 · 4.190 · 4.117 · 5.451 fichas); 941 casos de COVID de 2022
com confirmação só declarada; agrupamentos de zeros; banco vivo (versão 14-09-2026);
dicionário de 25/05/2023; 226 fichas com a semana epidemiológica do Ministério errada;
suavização global; malha simplificada no painel (100 m); escalas não entregues; contagens
pequenas.

## Premissa assumida (CS-043)

A decisão é da autora. Foi aplicada a opção que não apaga informação e se reverte com uma
mudança pequena: publicar sem supressão, com nota. O argumento é que o microdado por ficha já é
publicado, anonimizado, pelo Ministério da Saúde; suprimir agregados derivados dele não protege
ninguém a mais. Se a autora preferir suprimir, a mudança fica em `07_exportacao.R` e no painel.

## Nota sobre os dois percentuais dos 941 casos

O §4.2 diz 5,6 % (dos casos confirmados pela regra adotada em 2022); o §5.3 diz 5,0 % (das
fichas encerradas como COVID em 2022). Os dois estão certos; cada frase diz o denominador.

## Erros do caminho

Nenhum.
