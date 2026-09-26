# CS-049 — Como a população de cada ano foi obtida: fórmulas e exemplo no texto

- **Data:** 2026-09-26
- **Modelo · esforço:** Fable · medium (acordado com o dono)
- **Origem:** pedido da analista: "Censo não é anual; como foi feita a estimativa da população (número de
  indivíduos e faixa etária)? com base em que e com qual fórmula, de forma mais detalhada e didática"

## Verificação com número

| Critério de aceite | Resultado |
|---|---|
| Subseção com 3 fórmulas | relatório, "Como a população de cada ano foi obtida": AiBi do IBGE, interpolação de 2023, faixas etárias; mais a fórmula da taxa |
| 1 exemplo numérico calculado pelo código | Niterói: 481.749 (Censo) → 516.720 (2024, +7,3 %) → 498.435 em 2023 (peso 334/700 = 0,4771); 3.683 bebês em 2022 (0,76 %) → 3.811 em 2023; taxa de VSR 2023 = 86 ÷ 498.435 × 100 mil = 17,3 |
| 0 números digitados | teste `test-relatorio.R` verde; peso, dias, números das tabelas do SIDRA e todos os valores do exemplo vêm de código |
| Método do IBGE citado da nota oficial | *Estimativas da População 2024, Nota metodológica n. 01*, p. 5–6 (AiBi) e 6–8 (ajuste pela Pesquisa de Pós-Enumeração), texto extraído do PDF |
| Proposta v2 §3.4 | mesma explicação, com os números desta data e a remissão ao relatório |
| Testes | 741/741 expectativas em 23 arquivos, 0 falhas |

## O que a nota do IBGE diz (conferido no PDF)

- Municípios: **método de tendência do crescimento populacional (AiBi)**, Madeira e Simões (1972):
  $P_i(t) = a_i P(t) + b_i$, com $a_i$ e $b_i$ ajustados aos Censos de 2010 e 2022 (deslocados para
  1º de julho e ajustados); a soma dos municípios reproduz a UF (p. 5–6).
- UF: projeções pelo método das componentes demográficas, Revisão 2024 (p. 4–5).
- Ajuste dos Censos: Taxa de Erro Líquido de Enumeração da PPE 2022 em 9 classes de tamanho,
  maior nos municípios grandes (13,2 % acima de 1 milhão; 3,9 % abaixo de 14 mil), combinada
  em escala logito com o ajuste da UF (p. 6–8).

## Erros do caminho

1. O resumo automático do PDF (WebFetch) atribuiu aos municípios o "método das componentes
   demográficas", que é o das UF. O texto foi extraído do PDF (pypdf, instalado no perfil do
   usuário) e a descrição segue as páginas 5–8.
2. O detector de números digitados pegou "4714", "9514" e as datas "01/08/2022" da fórmula: os
   números das tabelas passaram a vir de `config/fontes.yml`, e as datas foram escritas por extenso.
