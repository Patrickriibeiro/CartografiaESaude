# ADR-0003 — Denominador populacional por ano

- **Status:** **proposto**. Implementado como padrão provisório; a escolha final é da
  autora (D-05), à luz do achado 2 abaixo.
- **Data:** 2026-09-25
- **Nasce em:** CS-011

## Contexto

A incidência é `casos / população × 100 000`. O estudo cobre os anos
epidemiológicos 2022 a 2025 (CS-036). O IBGE oferece, para os municípios do RJ:

| Ano | Fonte | Data de referência | RJ |
|---|---|---|---|
| 2021 | Estimativa (SIDRA 6579), pré-Censo | 01/07/2021 | 17.463.349 |
| 2022 | Censo (SIDRA 4714) | 01/08/2022 | 16.055.174 |
| 2023 | **não publicada** | — | — |
| 2024 | Estimativa (SIDRA 6579) | 01/07/2024 | 17.219.679 |
| 2025 | Estimativa (SIDRA 6579) | 01/07/2025 | 17.223.547 |

## Achados

1. **Não existe população municipal oficial para 2023.** O IBGE não publicou
   estimativa naquele ano.
2. **O Censo 2022 fica abaixo das estimativas dos dois lados.** A estimativa de 2024 é
   maior que o Censo em **todos os 92 municípios**: no mínimo 3,1 % (Cambuci), na
   mediana 5,7 %, no máximo 8,4 % (Rio de Janeiro); no estado, 7,3 %. Isso não é
   crescimento populacional de dois anos; é consistente com a correção de cobertura
   que as estimativas pós-Censo incorporam e a contagem censitária não tem. A fonte
   primária que documenta o método de ajuste do IBGE **não foi consultada** nesta
   demanda e deve ser citada antes de a decisão ser fechada.
3. **Consequência:** com o Censo como denominador de 2022, a incidência de 2022 fica
   3–8 % mais alta do que ficaria na escala das estimativas, e a de 2023 interpolada
   herda metade desse degrau. Para comparar municípios **dentro** de um ano o efeito é
   pequeno (a razão varia de 1,031 a 1,084); para comparar **anos** entre si, é um
   degrau artificial do tamanho de uma tendência epidemiológica real.

## Decisão provisória (implementada)

- 2022: Censo. 2024 e 2025: estimativas. 2021: só diagnóstico, nunca denominador.
- 2023: interpolação linear entre o Censo (01/08/2022) e a estimativa de 2024
  (01/07/2024), avaliada em 01/07/2023. Peso 334/700 = 0,4771, não 0,5.
- O método é um parâmetro (`montar_populacao(metodo_ausente = ...)`): trocar é uma
  linha em `02_indicadores.R`.

## Alternativas para a autora decidir (D-05)

| Opção | O que faz | Custo |
|---|---|---|
| A. Provisória (acima) | Usa cada número oficial como está | Degrau de 3–8 % entre 2022 e 2024 |
| B. Repetir o Censo em 2023 | `metodo_ausente = "anterior"` | Degrau inteiro fica entre 2023 e 2024 |
| C. Escalonar o Censo pela razão estadual | Censo × 1,0725 em 2022, interpolar 2023 | Remove o degrau estadual, mantém a estrutura municipal do Censo; é uma construção do projeto, não do IBGE |
| D. Estimativa 2024 para todos os anos | Um só denominador | Sem degrau; ignora a variação entre anos (0,02 % de 2024 para 2025 no estado) |

A recomendação técnica é **D para as comparações entre anos e A no mapa de cada ano**,
reportando a sensibilidade. Mas isso muda a metodologia escrita, então é da autora.

## Consequências

- `resultados/tabelas/diagnostico_populacao.csv` guarda a razão por município, para a
  seção de limitações do relatório.
- O CS-012 (incidência) usa o que `montar_populacao()` devolver; mudar de opção não
  exige mudar o CS-012.
