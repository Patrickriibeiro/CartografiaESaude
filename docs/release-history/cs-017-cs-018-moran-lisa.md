# CS-017 + CS-018 (+ CS-039) — Moran global, LISA e testes de padrão conhecido

- **Data:** 2026-09-25
- **Modelo · esforço:** Fable 5.1 · high (acordado com o dono)
- **Itens:** CS-017 · ADR-0004 · CS-018 e CS-039 fechados junto, com aviso ao dono

## Verificação com número

| Critério de aceite | Resultado |
|---|---|
| Suíte completa | **309/309 expectativas em 93 testes, 10 arquivos**, 0 falhas |
| 12 combinações agente × ano com I e p | 12, em três rodadas: suavizada Queen, bruta Queen, suavizada Rook |
| Tabela LISA 92 × 12 | 1.104 linhas, 0 NA em Ii, p, p_fdr, classe |
| HH antes e depois do FDR reportados | `lisa_resumo.csv`: por mapa, sem correção, confirmados, HH/LL por nível |
| CS-018: tabuleiro, gradiente, ruído em 20 sementes | Rook: I < −0,9 · Queen ≈ 0 · gradiente I > 0,5 · ruído: ≥ 15 de 20 sementes com p > 0,05 |
| CS-018: testes rodam em < 10 s | arquivo `test-moran-lisa.R` dentro dos 11,7 s da suíte inteira |
| CS-039: instáveis marcados | 3 por mapa (`instavel`); Itatiaia é o único significativo (indicativo) |
| Tempo do script | 32 s para 36 rodadas de Moran + 36 de LISA, 9.999 permutações |
| Mutação: tirar o alinhamento pela chave | o teste "embaralhar as linhas" quebra |

## Resultado principal (suavizada, Queen)

- Moran global significativo em **6 de 12** mapas (influenza 2022, 2023, 2025;
  SARS-CoV-2 2023, 2025; VSR 2024), com I entre 0,11 e 0,33.
- LISA **confirmado** (após FDR) só no **VSR 2024**: Tanguá, Itaboraí e Maricá
  (Alto-Alto), Comendador Levy Gasparian (Baixo-Baixo), Petrópolis (Alto-Baixo).
- Nos outros 11 mapas, entre 0 e 12 municípios significativos sem correção (esperado por
  acaso: 4,6), nenhum confirmado. Entram no mapa como **indicativos**.
- Bruta × suavizada: a bruta acha mais autocorrelação (9 de 12), com a maior diferença no
  VSR 2022 (44 municípios sem caso): "cluster de zeros". Virou o CS-041.

## Decisões (detalhadas no ADR-0004)

9.999 permutações (a resolução de 999 não alcança o limiar do FDR); p bicaudal no LISA;
FDR-BH por mapa; dois níveis no resultado; instáveis marcados, não excluídos; Rook só no
global; alinhamento pela chave com erro se o dado não bater com os pesos.

## Erros do caminho

1. **Tabuleiro de xadrez sob Queen.** O teste esperava I < −0,5 e obteve −0,08. Sob
   Queen, 4 dos 8 vizinhos de cada casa têm a mesma cor (diagonais), e o efeito quase se
   cancela; o tabuleiro só é o exemplo de autocorrelação negativa sob Rook. O teste
   passou a cobrir as duas vizinhanças, e o comentário registra o erro.
2. **FDR calculado à mão errado** no teste de classificação (0,02 com m = 5 dá ajustado
   0,033, que é confirmado, não indicativo). Refeito com valores em que a conta está
   escrita passo a passo no próprio teste.
3. Nenhum erro no código do pipeline: os dois erros foram de expectativa nos testes, e
   os dois ensinaram algo sobre o método.
