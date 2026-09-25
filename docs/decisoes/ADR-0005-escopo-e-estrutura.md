# ADR-0005 — Escopo e estrutura do pipeline

- **Status:** aceito (itens 1 e 2 em 2026-09-25; item 3 pela autora em 2026-09-25, D-06 e D-08)
- **Data:** 2026-09-25
- **Nasce em:** CS-002

## Contexto

O PDF v1 define a organização de scripts do projeto. Três pontos precisavam de decisão
explícita antes do primeiro commit, porque moldam o esqueleto.

## Decisões

1. **Scripts numerados + `run.R`, não o pacote `targets`.** `targets` reexecuta só o
   que mudou, o que economiza tempo em pipelines pesados. Aqui o pipeline tem 92
   polígonos e 4 anos, e quem avalia é a banca da disciplina, que precisa ler o fluxo em
   ordem sem aprender uma ferramenta de orquestração. O custo aceito é reexecutar tudo a
   cada rodada.
2. **Árvore de diretórios idêntica à do PDF**, acrescida de `config/` (URLs de fontes
   fora do código, trilha §6) e `docs/`. Nada do PDF foi renomeado.
3. **Escopo municipal, não por bairro; quadrimestre só descritivo.** O "por bairro" da
   seção 4.2 do PDF é tratado como erro de digitação. O LISA roda em escala anual.
   Confirmado pela autora em 2026-09-25 (D-06, D-08).

## Consequências

- Cada script numerado começa com `source("00_setup.R")`, que carrega todas as funções
  de `R/`. Rodar um script isolado funciona; a ordem continua sendo responsabilidade de
  `run.R`.
- Se o pipeline crescer (mais anos, escala de setor censitário), migrar para `targets`
  vira um novo ADR.

## Adendo (2026-09-25, CS-012): quadrimestre epidemiológico

Como o ano do estudo é o ano epidemiológico do banco (ADR-0001, CS-036), o quadrimestre
também é epidemiológico, definido pela semana epidemiológica do início dos sintomas:
**semanas 1–17, 18–34 e 35–52/53**. Pelo mês de `DT_SIN_PRI`, uma ficha de 29/12/2024
do banco de 2025 cairia no 3º quadrimestre, e não no 1º. O 3º quadrimestre tem 18
semanas (19 em ano com semana 53); a taxa quadrimestral é do período, não anualizada,
e fica só no descritivo (D-08).
