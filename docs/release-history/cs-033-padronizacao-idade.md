# CS-033 — Padronização por idade (OE9)

- **Data:** 2026-09-25
- **Modelo · esforço:** Fable · medium (acordado com o dono)
- **Origem:** proposta v2 OE9 e §3.4; D-10 (opcional, autorizado pelo dono)

## Verificação com número

| Critério de aceite | Resultado |
|---|---|
| Coluna preenchida | `incid_pad_100k` nas 1.104 linhas da grade anual, sem NA; exportada como `taxa_padronizada_idade_100mil` |
| Gráfico bruta × padronizada | `resultados/estatistica/padronizacao_bruta_vs_padronizada.png` (3 agentes × 4 anos) |
| Nota metodológica | `docs/nota-metodologica-padronizacao.md` |
| Contrato | taxa bruta recalculada das 11 faixas == `incid_100k`, linha a linha (`all.equal`), verificado na etapa 02 |
| Fonte | SIDRA 9514 (Censo 2022 por idade): 92 municípios × 23 categorias, total 16.055.174 = Censo já usado (ADR-0003); em `dados/externos`, no manifesto |
| Idade dos casos | 37.562/37.562 com `NU_IDADE_N` e `TP_IDADE`; máximo 115 anos; 0 fora de 1-3 |
| Testes | 657/657 expectativas em 21 arquivos, 0 falhas (eram 630 em 20); 26 em `test-padronizacao.R`, com a conta à mão do método direto |
| Pipeline do zero | 8 etapas em 142 s |
| Reprodutibilidade | 2ª execução do zero: 109 de 110 arquivos idênticos byte a byte (difere só o LEIA-ME) |
| Relatório | subseção "Padronização por idade" com tabela e figura; limitação reescrita; 0 números digitados |

## Decisões de método (dentro do OE9; sem ADR novo)

- **11 faixas:** <1, 1-4, 5-9, 10-19, 20-29, ..., 70-79, 80+. As duas primeiras separadas porque
  74 % dos casos de VSR são de menores de um ano e 20 % de 1 a 4 anos. 1-4 sai de "0 a 4" menos
  "Menos de 1 ano" do SIDRA.
- **População-padrão:** RJ no Censo 2022 (menores de um ano pesam 0,96 %; 80+, 2,7 %).
- **Estrutura etária de 2022 em todos os anos:** o IBGE não publica estrutura municipal fora do
  Censo. A proporção de cada faixa em 2022 é aplicada à população do ano; a soma das faixas é
  a população do ano, e a taxa bruta recalculada das faixas é a do estudo. Está na limitação
  do relatório.
- **Três agentes**, não só VSR e influenza como o item dizia: a coluna existe em toda a grade e
  o SARS-CoV-2 (65 % dos casos com sessenta anos ou mais) é o agente mais sensível à idade.
- **"-" do SIDRA = zero** (3 municípios em "100 anos ou mais"); "X" e "..." param.
- A padronizada é **descritiva**: Moran e LISA continuam sobre a taxa suavizada (ADR-0004).

## Achados

- A estrutura etária explica pouco do padrão entre municípios: correlação de postos bruta ×
  padronizada de 0,989 a 0,999 nos 12 mapas; razão mediana padronizada / bruta de 0,93 a 1,01.
- No VSR a mediana fica abaixo de 1 nos 4 anos: 73 % dos municípios têm proporção de bebês
  maior que a da população-padrão, dominada pela capital.
- As correções grandes são de municípios com poucos casos: das 52 combinações com razão fora
  de 0,8–1,2, 71 % têm menos de 10 casos; os extremos (0,61 Varre-Sai, VSR 2022; 1,84 Armação
  dos Búzios, influenza 2025) têm 1 caso cada.

## Erros do caminho

1. **Avaliação preguiçosa no teste, de novo** (mesma armadilha do CS-034): a função que criava
   o JSON falso e o registrava no manifesto foi passada como argumento e rodou depois de
   `verificar_manifesto()` já ter lido o manifesto. Criada antes da chamada.
2. `tapply()` devolve um array com nomes, não um vetor: `expect_equal` contra `c(a = 100, b = 100)`
   falhava pela classe. Comparado com `as.numeric()`.
3. O auxiliar `ler()` do relatório passa tudo a `file.path()` (armadilha do CS-031, repetida no
   rascunho): `colClasses` viraria parte do caminho. `read.csv` direto.
4. O teste de números digitados pegou 10 números soltos no rascunho ("menores de 1 ano", "60 anos
   ou mais", "0,8 a 1,2", "menos de 10 casos"). Idades viraram palavras; os limiares da frase
   (0,2 e 10) viraram variáveis do chunk, e o texto os lê de lá.
5. Três frases do rascunho afirmavam sem medir: "quase sempre onde há poucos casos", "a maior
   parte dos municípios tem mais crianças" e "no VSR a mediana fica abaixo de 1 em todos os
   anos". As três passaram a depender de contas (71 %, 73 %, `all()`), e "1 casos" ganhou
   singular/plural.
6. O subtítulo do gráfico dizia "acima da diagonal: município mais jovem (ou mais velho)", que
   não diz nada; passou a dizer o que a posição significa (menos gente que o estado nas idades
   em que o vírus incide; a bruta subestima).
