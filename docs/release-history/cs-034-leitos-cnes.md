# CS-034 — Leitos SUS do CNES e taxa por residência (OE10)

- **Data:** 2026-09-25
- **Modelo · esforço:** Opus · high (recomendado high por espaço de solução aberto; o BACKLOG dizia medium)
- **Origem:** proposta v2 OE10 e §3.10; D-10 (opcional, autorizado pelo dono)

## Verificação com número

| Critério de aceite | Resultado |
|---|---|
| 4 coeficientes (um por ano) com IC | 4 com leitos SUS + 4 com leitos de UTI SUS, IC 95 % por bootstrap percentil, 9.999 reamostras, semente fixa |
| Sem linguagem causal | relatório: "descritiva e não indica que leitos causem ou evitem SRAG"; duas hipóteses (verificação e composição), nenhuma afirmada |
| Por região | `leitos_regionais.csv`: leitos e taxa por região e ano (descritivo; sem coeficiente com n = 9) |
| Dados | 92 × 4 = 368 linhas; leitos SUS no estado em julho: 24.195 · 24.142 · 24.147 · 24.110 |
| Testes | 619/619 expectativas em 20 arquivos, 0 falhas (eram 600 em 19); 18 em `test-leitos.R` |
| Pipeline do zero | 8 etapas em 145 s |
| Reprodutibilidade | 2ª execução do zero: 103 de 104 arquivos idênticos byte a byte (difere só o LEIA-ME) |

| Ano | Leitos SUS: rho (IC 95 %) | Leitos de UTI SUS: rho (IC 95 %) |
|---|---|---|
| 2022 | 0,18 (−0,05 a 0,40) | 0,40 (0,20 a 0,57) |
| 2023 | 0,27 (0,06 a 0,47) | 0,33 (0,11 a 0,52) |
| 2024 | 0,04 (−0,18 a 0,26) | 0,37 (0,16 a 0,55) |
| 2025 | 0,11 (−0,10 a 0,32) | 0,35 (0,15 a 0,53) |

## Decisões

- **Fonte:** conjunto "Hospitais e Leitos" do Portal de Dados Abertos do SUS (CSV anual,
  mesmo portal do SIVEP), e não o `microdatasus` previsto: evita `.dbc`, compilação no
  Windows e pacote fora do CRAN. 4 arquivos, ~82 MB, em `dados/brutos` com SHA-256 no manifesto.
- **Competência de julho**, como a população (ADR-0003). O total mensal do RJ varia < 4 %.
- **Dois indicadores, não somados.** O item pedia "clínicos + UTI"; o arquivo não separa
  "clínicos", e não está documentado se `LEITOS_SUS` inclui a UTI (em nenhuma linha a UTI passa
  do total). Somar arriscaria contar o mesmo leito duas vezes.
- **Taxa:** SRAG dos três agentes por residência, população do ano; Spearman nos 92 municípios.
- **Formatos declarados em `config/fontes.yml`**, não adivinhados: 2022 UTF-8 com espaços nos
  nomes de coluna; 2023–2024 latin-1; 2025 latin-1, ";" e zip, com `CO_IBGE`.

## Achados

- Os arquivos de 2022–2024 não têm código IBGE: junção por nome, com 2 grafias antigas
  (PARATI → Paraty, TRAJANO DE MORAIS → Trajano de Moraes). Em 2025, nome e `CO_IBGE`
  concordam em 100 % dos estabelecimentos — validação independente da junção por nome.
- 7 municípios sem leito SUS e 51–52 sem leito de UTI SUS em cada ano. A diferença entre ter e
  não ter UTI aparece nas medianas: a da taxa com UTI de 1,7 a 2,0 vezes a sem UTI nos 4 anos.

## Erros do caminho

1. `read.csv()` ignora `fileEncoding` quando recebe uma conexão; e `unz(encoding = "latin1")`
   também não converteu os acentos. O teste com fixture latin-1 ("NITERÓI") pegou isso; o
   código passou a ler as linhas e converter com `iconv()`, parando se algum byte for inválido.
   **Nos dados reais o bug estava latente:** nenhum nome de município do RJ tem acento nos
   quatro arquivos, então a saída não muda.
2. Conexão aberta por `read.csv` é fechada por ele; o `close()` posterior falhava
   ("invalid connection"). Resolvido com a leitura por `readLines` + `close` explícito.
3. **Avaliação preguiçosa** no teste: com `ler_leitos_ano(item_zip(...))`, o `item_zip()` (que
   registra o arquivo no manifesto) só rodava depois de `verificar_manifesto()` já ter lido o
   manifesto. O teste da codificação passava "por acaso", porque aceitava qualquer erro;
   agora cada `expect_error` exige a mensagem certa.
4. Heredoc do bash comeu barras invertidas duas vezes (regex e comentário); corrigido com `sed`
   sem escape. A lição de 2026-09-25 continua valendo: código com barra invertida vai por
   arquivo, não por heredoc.
5. Primeiro rascunho do relatório tinha "entre 7 e 7 municípios", "positiva em todos os anos"
   fixo e "grande parte disso" sem medida; as três frases passaram a depender dos números.
