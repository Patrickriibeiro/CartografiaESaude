# ADR-0003 — Denominador populacional por ano

- **Status:** **aceito em 2026-09-25** pela autora (D-05): opção D para comparar anos, opção A
  para o mapa de cada ano. Texto original preservado abaixo; ver a seção "Aceite" no fim.
- **Data:** 2026-09-25
- **Nasce em:** CS-011

## Contexto

A incidência é `casos / população × 100 000`. O estudo cobre os anos
epidemiológicos 2022 a 2025 (CS-036). O IBGE oferece, para os municípios do RJ:

> **Convenção de datas (CS-036, 2026-09-25).** O numerador é o ano **epidemiológico**
> (2024 começa em 31/12/2023; 2025 tem 53 semanas e termina em 03/01/2026); o denominador
> é a população de 1º de julho do ano **civil** de mesmo número. O dia do meio de cada ano
> epidemiológico fica a no máximo 2 dias de 1º de julho (−2, −1, +1, −1 em 2022–2025;
> `limites_ano_epi()`, testado). A exceção é 2022, cujo denominador oficial é o Censo, de
> 01/08/2022: 29 dias depois do meio do ano, desprezível diante do degrau de 7,3 % entre
> Censo e estimativa descrito abaixo. A semana 53 de 2025 não é descontada: a taxa de 2025
> cobre 371 dias, contra 364 dos outros anos, e o relatório informa quantos casos ela soma.

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
   crescimento populacional de dois anos: é a correção de cobertura que as estimativas
   pós-Censo incorporam e a contagem censitária não tem. **Fonte primária (CS-038):** IBGE,
   *Estimativas da População 2024, Nota metodológica n. 01*, p. 6–7
   (https://biblioteca.ibge.gov.br/visualizacao/livros/liv102112.pdf). As populações
   municipais do Censo 2022 "foram ajustadas, de modo que a soma das populações dos
   municípios coincida" com as Projeções da População, Revisão 2024; o ajuste de cada UF
   é distribuído entre os municípios pela Taxa de Erro Líquido de Enumeração da Pesquisa
   de Pós-Enumeração (PPE) 2022, em 9 classes de tamanho, e é **maior nos municípios
   grandes**. Isso explica o padrão medido: Rio de Janeiro (maior município) com o maior
   ajuste, Cambuci (pequeno) com o menor.
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

**Consequência da fonte para as alternativas:** a população "Censo 2022 ajustada" que
o IBGE usa internamente (data de 1º de julho de 2022) é o denominador de 2022 coerente
com as estimativas, mas **não é publicada por município** na nota. A opção C abaixo
aproxima esse ajuste com um fator único estadual; o ajuste real varia por classe de
tamanho, então a opção C subcorrige municípios grandes e sobrecorrige pequenos.

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

## Aceite (2026-09-25)

A autora aceitou a recomendação: **dois denominadores, cada um com um uso**.

| Uso | Denominador | Por quê |
|---|---|---|
| Mapa e LISA de **cada ano** | População oficial daquele ano: Censo 2022; 2023 interpolado (peso 0,4771); estimativas 2024 e 2025 (opção A) | Dentro de um ano, a razão estimativa/Censo varia pouco entre municípios (1,031 a 1,084); o número oficial é o mais fácil de defender |
| **Comparação entre anos** (séries, variação 2022→2025, H3) | Estimativa 2024 para todos os anos (opção D) | Remove o degrau de 3–8 % entre a contagem do Censo e as estimativas ajustadas |

Cada uso tem a outra versão como sensibilidade no relatório. Implementação: CS-012
(`incid_100k` e `incid_100k_pop2024`), com um modo "denominador único" em
`montar_populacao()`.
