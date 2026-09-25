# Nota metodológica — suavização empírica de Bayes

Texto para o relatório (CS-022, seção de métodos) e para a proposta v2 §3.4. Os números
vêm de `resultados/tabelas/suavizacao_bayes_empirico.csv`, gerado por `02_indicadores.R`.

## Por que suavizar

A incidência bruta de um município pequeno é instável: em Macuco (cerca de 5 mil
habitantes), um único caso vale 20 por 100 mil. Um mapa ou um LISA sobre a taxa bruta
tende a destacar municípios pequenos pelo acaso, não pelo risco. A suavização empírica
de Bayes corrige isso "emprestando força" da média do estado, na medida da incerteza de
cada município.

## Método

Estimador empírico de Bayes global de Marshall (1991), família de Poisson, aplicado
separadamente a cada agente e ano (`spdep::EBest`). Para cada município *i*, com *yᵢ*
casos e população *nᵢ*:

- média do estado *b* = Σ*y* / Σ*n*;
- variância das taxas ponderada pela população *s²*;
- variância entre municípios *a* = *s²* − *b* / *n̄* (zerada se negativa);
- taxa suavizada = *b* + *a* (*yᵢ/nᵢ* − *b*) / (*a* + *b*/*nᵢ*).

O peso da taxa própria cresce com a população: municípios grandes ficam quase com a
taxa bruta, e os pequenos se aproximam da média. A população é a oficial de cada ano
(ADR-0003). A implementação foi conferida contra a fórmula escrita à mão.

## O que a suavização fez nos dados

| Agente | Ano | Municípios sem caso | Maior taxa bruta | Maior taxa suavizada | Correlação de postos bruta × suavizada | Mudança mediana |
|---|---|---|---|---|---|---|
| SARS-CoV-2 | 2022 | 1 | 451,6 | 396,0 | 0,99 | 3 % |
| | 2023 | 10 | 138,5 | 135,5 | 0,97 | 6 % |
| | 2024 | 20 | 139,3 | 77,1 | 0,91 | 12 % |
| | 2025 | 27 | 22,5 | 20,0 | 0,82 | 18 % |
| Influenza | 2022 | 45 | 27,0 | 24,4 | 0,78 | 11 % |
| | 2023 | 31 | 26,4 | 17,1 | 0,84 | 17 % |
| | 2024 | 13 | 66,4 | 37,4 | 0,93 | 13 % |
| | 2025 | 11 | 114,2 | 91,7 | 0,96 | 7 % |
| VSR | 2022 | 44 | 39,7 | 30,1 | **0,40** | 26 % |
| | 2023 | 43 | 45,7 | 43,7 | 0,71 | 10 % |
| | 2024 | 31 | 44,0 | 32,0 | 0,62 | 18 % |
| | 2025 | 19 | 81,0 | 78,5 | 0,89 | 14 % |

Taxas por 100 mil habitantes. "Mudança mediana" é a mediana de |suavizada − bruta| /
bruta entre os municípios com ao menos um caso.

## Leitura

- Onde há muitos casos (SARS-CoV-2 em 2022), a suavização quase não muda a ordem dos
  municípios (correlação 0,99).
- Onde há poucos casos e muitos municípios zerados (VSR 2022–2024, influenza 2022), ela
  reordena bastante (correlação 0,40 a 0,78). É exatamente onde a taxa bruta é menos
  confiável, e onde o LISA sobre a bruta e sobre a suavizada podem discordar; por isso o
  relatório traz as duas (D-09).
- Nenhum agente × ano teve encolhimento total (variância entre municípios nula).
- Limitação: a suavização global puxa todos para a média do **estado**, sem considerar
  vizinhança. A versão local (média dos vizinhos) seria alternativa, mas usaria a mesma
  vizinhança que o LISA depois testa, o que tende a inflar a autocorrelação.

## Referência

Marshall RJ. Mapping disease and mortality rates using empirical Bayes estimators.
*Journal of the Royal Statistical Society, Series C (Applied Statistics)*.
1991;40(2):283-294.
