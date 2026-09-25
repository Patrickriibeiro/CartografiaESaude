# CS-016 — Vizinhança Queen e pesos espaciais

- **Data:** 2026-09-25
- **Modelo · esforço:** Opus · medium (acordado com o dono)

## Verificação com número

| Critério de aceite | Resultado |
|---|---|
| Suíte completa | **147/147 expectativas em 48 testes, 5 arquivos**, 0 falhas |
| 1 bloco conexo (`n.comp.nb == 1`) | 1 |
| Mínimo de vizinhos ≥ 1 | 1 (Paraty, Itatiaia, Armação dos Búzios) |
| Verificação cruzada do ADR-0006 | **456 ligações**, igual à malha oficial; o script para se der outro número |
| Vizinhança simétrica | sim (`is.symmetric.nb`) |
| Pares que o `geobr` simplificado perdia | Rio de Janeiro–Seropédica e Mesquita–São João de Meriti presentes |
| Histograma e tabela | `resultados/estatistica/histograma_vizinhos.png` e `vizinhos_por_municipio.csv` |

Distribuição do número de vizinhos (municípios): 1 → 3 · 2 → 7 · 3 → 15 · 4 → 16 ·
5 → 14 · 6 → 16 · 7 → 10 · 8 → 7 · 9 → 2 · 10 → 2 (Campos dos Goytacazes e Petrópolis).

## Testes com resposta conhecida

Grade 3 × 3 de quadrados: Queen dá 3 vizinhos no canto, 5 na borda, 8 no centro (40
ligações); Rook dá 2, 3 e 4 (24 ligações). Os pesos W do centro são 1/8 cada; os do
canto, 1/3. Município isolado e dois blocos desconectados param com erro.

## Decisões de implementação

- O `cod6` vai para o `region.id` da vizinhança. O CS-017 deve alinhar os dados aos
  pesos pela chave. Um teste embaralha a ordem da malha e confere que os vizinhos do
  quadrado central continuam os mesmos.
- `zero.policy = FALSE`: município sem vizinho é erro, nunca peso zero silencioso.
- Salvos dois objetos: a vizinhança (`nb`) e os pesos (`listw`), porque o CS-017 e a
  sensibilidade do CS-039 podem precisar de outro estilo de peso sobre a mesma
  vizinhança.

## Achado

Três municípios têm um único vizinho, e os de divisa perdem os vizinhos de SP, MG e
ES (efeito de borda). Registrado como CS-039, a decidir no ADR-0004.

## Erros do caminho

Nenhum erro de código. Os testes de ilha e de blocos desconectados deixavam avisos do
`spdep` na saída. Os avisos eram esperados e foram silenciados só nesses dois testes,
com comentário dizendo por quê.
