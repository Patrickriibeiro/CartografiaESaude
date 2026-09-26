# Revisão dos modelos de gráfico (CS-047)

*Documento vivo. Uma linha por figura: o que ela precisa mostrar, se a forma escolhida é a
adequada, e o que foi trocado. Critérios: a forma segue o que o dado tem de responder
(magnitude, identidade, tempo, posição); um eixo por gráfico; cor pela entidade, nunca pela
ordem; legenda sempre que há mais de uma série; nada que dependa só de cor. Revisão feita em
2026-09-26 sobre a paleta do CS-046.*

## Figuras do relatório

| Figura | Pergunta que responde | Decisão | Por quê |
|---|---|---|---|
| Guia de cores | qual cor é qual vírus e qual classe do LISA | mantida | é a legenda-mestra do relatório |
| Painel de incidência (3 vírus × 4 anos, mapas) | onde a taxa é alta, e como isso muda no tempo, por vírus | mantida | escala comum aos 4 anos de cada vírus, raiz quadrada para não achatar os anos de baixa; rampa na cor do vírus; entre vírus a escala não é comparável, e o título diz isso |
| Mapas de incidência isolados (12) | o mesmo, com classes por quintil do próprio mapa | mantidos | quintis destacam o padrão de cada ano; a legenda diz que as classes são do mapa |
| Bruta × padronizada por idade (dispersão, 12 painéis) | a padronização muda a ordem dos municípios? | mantida | dispersão contra a diagonal é a forma direta da pergunta; os extremos são nomeados na tabela ao lado, não no gráfico (92 pontos por painel) |
| Bruta × suavizada (dispersão) | quanto a suavização puxa os pequenos | mantida | idem |
| Painel LISA (3 × 4) | onde há agrupamento, por vírus e ano | mantido | cor cheia/clara para confirmado/indicativo, hachura para instável (não depende só de cor) |
| Mapa LISA isolado (VSR 2024) | quais municípios formam o agrupamento confirmado | **trocado**: rótulos retirados do mapa | Itaboraí e Tanguá se sobrepunham e o preto sumia sobre o vermelho; o subtítulo já nomeia os confirmados. O "4,6 esperados por acaso" era fixo no código e passou a ser calculado |
| Mapa de referência das regiões | qual município está em qual região | mantido | tons pastel + nome escrito + tabela (não depende só de cor) |
| Mapas regionais (12) | taxa por região | mantidos | nome e taxa escritos nas 9 regiões |
| Série semanal do estado (3 linhas) | a magnitude relativa dos três vírus no tempo | mantida | é a única figura em que os três estão na mesma escala; o pico de 2022 é o fato |
| **Série por vírus, um painel cada** | o tempo e a forma das ondas de influenza e VSR | **nova** | na escala comum, o pico de SARS-CoV-2 de 2022 (2.265/semana) achata ondas de 300/semana; painéis com escala própria mostram o tempo sem mentir sobre a altura, e o subtítulo diz para não comparar alturas |
| Painel das 9 regiões (séries) | quando cada região teve suas ondas | mantido | escala própria por região, declarada; as contagens absolutas não são comparáveis entre regiões (população varia 38 vezes), e o texto usa as taxas para isso |
| Fichas não encerradas por semana | há subida de não encerradas no fim do ano? | **trocada**: eixo duplo → dois painéis empilhados | barra e linha em dois eixos são o erro clássico: os cruzamentos entre elas não significam nada, e a razão entre as escalas é arbitrária. Dois painéis com o mesmo eixo do tempo respondem a mesma pergunta sem esse artefato |
| Versões do banco (diferença de casos) | quanto os números mudam entre versões | mantida | já trocada no CS-048 de % para diferença absoluta, pelo mesmo motivo (um eixo de 99,9 % a 100,1 % faz 3 casos parecerem uma oscilação) |
| Leitos × taxa (dispersão, 8 painéis) | a taxa acompanha a oferta de leitos? | mantida | eixo x em raiz quadrada porque metade dos municípios tem 0 leito de UTI; rho e IC escritos no painel |

## Fora do relatório

| Figura | Decisão | Por quê |
|---|---|---|
| Histograma de vizinhos | mantido | forma certa para uma distribuição de contagens |
| Séries por região (9 gráficos isolados) | mantidos | os mesmos das facetas do painel, para quem quer uma região |

## O que não foi feito, e por quê

- **Rótulo direto nas séries** (nome do vírus na ponta da linha): a legenda no topo já resolve, e
  na escala comum as linhas de influenza e VSR terminam quase juntas.
- **Escala logarítmica** na série do estado: esconderia os zeros (semanas sem caso) e o leitor
  clínico lê pior um eixo log do que dois painéis.
- **Mapa com dados por ponto** (cartograma, círculos proporcionais): a unidade de decisão é o
  polígono do município, e a taxa já corrige a população.
