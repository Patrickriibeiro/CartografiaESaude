# CS-041 — "Agrupamento de zeros" na taxa bruta

- **Data:** 2026-09-25
- **Modelo · esforço:** Opus · medium (acordado com o dono)
- **Origem:** ADR-0004 §4.1 — no VSR 2022 a taxa bruta dá Moran p = 0,008 e 13 LISA; a suavizada, p = 0,103 e 0

## Verificação com número

| Critério de aceite | Resultado |
|---|---|
| Tabela zeros × notificação própria por município | `resultados/estatistica/zeros_diagnostico.csv`, 12 linhas (agente × ano), e tabela no relatório |
| Parágrafo no relatório | subseção "Agrupamento de zeros na taxa bruta" + limitação do §5.3 com números |
| Testes | 630/630 expectativas em 20 arquivos, 0 falhas (eram 619) |
| Pipeline do zero | 8 etapas em 140 s |

## O que a tabela mede, por agente × ano

Zeros observados; zeros **esperados pelo acaso** se todo município tivesse a taxa do estado
(soma da probabilidade de Poisson de zero caso, `exp(−população × taxa)`); zeros sem notificação
própria (nenhuma ficha de SRAG notificada no município no ano); zeros sem leito SUS (CNES,
CS-034); fichas de SRAG dos residentes dos municípios sem caso e a proporção delas com
resultado de RT-PCR ou antígeno, contra a dos demais municípios.

## Achados

- **A hipótese do BACKLOG explica pouco.** No VSR 2022, só 10 dos 44 municípios sem caso não
  notificaram nenhuma ficha no ano; 7 não têm leito SUS.
- **Não é só acaso de município pequeno.** Os zeros observados superam os esperados em 12 de 12
  mapas (VSR 2022: 44 contra 14,2; VSR 2025: 19 contra 2,1).
- **Não é ausência de SRAG.** Os residentes dos 44 municípios sem caso de VSR em 2022 tiveram
  2.064 fichas de SRAG.
- **É compatível com menos confirmação laboratorial.** Fichas testadas: 76 % nos municípios sem
  caso contra 88 % nos demais (VSR 2022); maior diferença em VSR 2025, 34 % contra 93 %.
- 12 dos 13 municípios com LISA significativo na taxa bruta do VSR 2022 têm zero caso, 12 são
  Baixo-Baixo e nenhum é confirmado após a correção FDR.

## Erros do caminho

1. O primeiro texto dizia "o que os distingue é a testagem", "a maior diferença é a do VSR de
   2025" (fixo) e concluía "e não de ausência de doença". A testagem é **uma** diferença, não
   a única medida; o máximo passou a ser calculado; e a conclusão virou "compatível com (...),
   mais do que com ausência de doença; os dados não permitem separar as duas coisas por completo".
