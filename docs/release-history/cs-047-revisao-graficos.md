# CS-047 — Revisão dos modelos de gráfico

- **Data:** 2026-09-26
- **Modelo · esforço:** Fable · medium (acordado com o dono)
- **Origem:** pedido da analista: "os modelos de gráficos escolhidos realmente são os mais adequados
  para compreensão e visualização das análises realizadas?"

## Verificação com número

| Critério de aceite | Resultado |
|---|---|
| `docs/revisao-graficos.md` com 1 linha por figura | 15 figuras do relatório + 2 de fora, cada uma com pergunta, decisão e motivo; seção "o que não foi feito" |
| Figuras trocadas regeradas | 2 trocadas (eixo duplo → 2 painéis; rótulos do LISA retirados) + 1 nova (série com um painel por vírus); conferidas na imagem |
| Teste de figuras do relatório | verde: toda figura citada existe; 0 números digitados |
| Testes | 741/741 expectativas em 23 arquivos, 0 falhas (eram 739) |
| Pipeline do zero | 8 etapas em 158 s |

## O que mudou e por quê

1. **Fichas não encerradas: eixo duplo → dois painéis empilhados.** Barra e linha em dois eixos
   fazem o olho ler cruzamentos que não existem, porque a razão entre as escalas é arbitrária.
   Os dois painéis partilham o eixo do tempo e respondem à mesma pergunta.
2. **Série do estado: figura nova com um painel por vírus, escala própria.** Na escala comum o
   pico de SARS-CoV-2 de 2022 (2.265 casos/semana) achata ondas de 300/semana de influenza e
   VSR. A figura original fica (é a única em que a magnitude é comparável) e a nova mostra o
   tempo das ondas; o subtítulo avisa para não comparar alturas entre painéis.
3. **Mapa LISA isolado: rótulos retirados.** Itaboraí e Tanguá se sobrepunham e o preto sumia
   sobre o vermelho; o subtítulo já nomeia os confirmados. O "4,6 esperados por acaso" era um
   número fixo no código e passou a ser calculado (municípios × α).

Todas as outras figuras foram mantidas, com o motivo registrado no documento.

## Erros do caminho

Nenhum na implementação. O eixo duplo estava no projeto desde o CS-035 e passou pelo CS-046
sem ser questionado: a revisão por pergunta (o que a figura responde?) é o que o pegou.
