# CS-046 — Paleta única por vírus, sem colisão com o LISA

- **Data:** 2026-09-26
- **Modelo · esforço:** Opus · medium (acordado com o dono)
- **Origem:** pedido da analista: "manter paleta de cores para todas as análises, padronizar também por
  vírus para não causar confusão na interpretação dos painéis"

## O problema medido

Antes, o vermelho era SARS-CoV-2 nas séries e Alto-Alto no LISA; o azul, influenza nas séries e
Baixo-Baixo no LISA; o verde, VSR nas séries e Baixo-Alto no LISA. Distância de cor entre esses
pares: **0** (a mesma cor com dois significados). Os mapas de incidência dos três vírus usavam a
mesma escala `magma`, então o mapa não dizia de qual vírus era.

## A paleta nova

| Uso | Cores |
|---|---|
| SARS-CoV-2 · Influenza · VSR | `#eda100` amarelo · `#e87ba4` magenta · `#008300` verde (posições 4, 5 e 6 da paleta categórica validada da skill dataviz) |
| Incidência | uma rampa por vírus: quase branco → cor do vírus → tom escuro do mesmo matiz (interpolação em Lab) |
| LISA | Alto-Alto vermelho, Baixo-Baixo azul (convenção GeoDa), Alto-Baixo roxo, Baixo-Alto cinza; tom claro = indicativo |
| Marcas sem vírus | `#52514e` neutro (total de SRAG, histograma, proporção não encerrada) |

Todas as cores ficam em `R/funcoes_mapas.R` (`CORES_AGENTE`, `rampa_agente()`, `PALETA_LISA`,
`COR_NEUTRA`); o resto do código só as referencia.

## Verificação com número

| Critério de aceite | Resultado |
|---|---|
| 1 constante usada em 100 % dos gráficos | 0 cores escritas à mão e 0 `magma`/`viridis` fora de `funcoes_mapas.R` (teste; mutação: cor plantada é pega) |
| 0 cores compartilhadas entre vírus e LISA | 0 hex em comum (teste); pior distância vírus × LISA 11,2 em visão normal (antes 0) |
| Contraste conferido (validador da skill dataviz) | vírus entre si, todos os pares: 16,2 sob daltonismo (meta ≥ 8), 19,6 em visão normal (piso 15); LISA confirmado entre si: 9,5 e 15,5 |
| Rampas | claridade estritamente decrescente nas 3 (teste com `farver`) |
| Mapas e painel regerados | 38 mapas, 18 gráficos, painel Shiny usa a rampa do vírus; guia de cores novo no relatório |
| Testes | 683/683 expectativas em 22 arquivos, 0 falhas (eram 661 em 21) |
| Dados | nenhuma tabela mudou (só PNGs) |

## Decisões

- **LISA mantém vermelho e azul** (convenção que leitores de estatística espacial conhecem); os vírus
  é que saíram dessas cores. Buscados 22 trios de vírus e 308 combinações de LISA; escolhido o trio
  com a maior separação entre vírus, porque é o que aparece junto (séries, painéis).
- **Contraste abaixo de 3:1** do amarelo (2,11) e do magenta (2,62) sobre branco: regra de alívio da
  skill — linhas mais grossas (0,55 → 0,8), legenda sempre presente e a mesma série em tabela
  (`serie_semanal.csv`).
- Pior par vírus × LISA: magenta (influenza) × vermelho (Alto-Alto), 11,2 em visão normal. Os dois
  nunca aparecem no mesmo gráfico: mapa LISA não tem cor de vírus.

## Erros do caminho

1. A 1ª proposta (laranja, violeta, verde-água + LISA com marrom) falhava: marrom × vermelho 1,6 sob
   daltonismo. A busca sistemática substituiu a escolha a olho.
2. O guia de cores saiu com rótulos sobre as cores e quadrados de larguras desiguais; corrigido e
   conferido na imagem.
3. Um teste terminava em `|| TRUE` (nunca falharia); trocado por uma verificação real da escala.
4. No gráfico da suavização, a coluna de rótulo ia ser criada no próprio `anual`; passou para uma
   cópia, para não vazar para os arquivos gravados.

## Errata (2026-09-26)

Na tabela de verificação, "18 gráficos" está errado: são **17** PNG em `resultados/estatistica/`
(16 de antes + o guia de cores). Os 38 mapas estão certos.
