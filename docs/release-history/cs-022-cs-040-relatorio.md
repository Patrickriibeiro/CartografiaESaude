# CS-022 + CS-040 — Relatório e apresentação em Quarto

- **Data:** 2026-09-25
- **Modelo · esforço:** Opus · medium (acordado com o dono)
- **Itens:** CS-022 · CS-040 (tabelas de sensibilidade) fechado junto, porque o aceite dele é
  "3 tabelas no `08_relatorio.qmd`"

## Verificação com número

| Critério de aceite | Resultado |
|---|---|
| `quarto render` sem erro | 0 avisos, 0 erros; 12 s para os dois formatos |
| 2 formatos do mesmo fonte | `08_relatorio.html` (2,2 MB, autocontido) e `08_apresentacao.html` (revealjs, 16 seções) |
| Números digitados no `.qmd` = 0 | `test-relatorio.R`: 0 encontrados; a mutação "Foram 37.562 casos" é pega |
| Seções 4.1–4.5 e 5.1–5.3 do PDF preenchidas | sim, na ordem do PDF; 4.4 (painel) aponta para o CS-021 |
| Data do snapshot no cabeçalho | versão dos bancos no texto da seção 4.1, lida do manifesto |
| Tabelas e figuras | 9 tabelas numeradas, 3 figuras, 9 referências resolvidas de `referencias.bib` |
| CS-040: regra × agente × ano, co-detecção, nota dos 941 | as três no relatório, todas calculadas |
| Suíte completa | **367/367 expectativas em 110 testes, 13 arquivos**, 0 falhas (+13 do relatório) |

## Como o relatório garante que nenhum número é digitado

Todo número do texto é código R embutido (`` `r fi(total_casos)` ``) que lê
`resultados/` e `dados/`; as tabelas são geradas por `knitr::kable`. As referências ficam em
`referencias.bib`, e o texto só tem chaves de citação. O teste retira do `.qmd` o cabeçalho, os
blocos de código, o código embutido, comentários, caminhos e citações, e procura números
soltos no que sobra. Anos, "100 mil" e identificadores (ADR-0004, SARS-CoV-2, H1, 1ª) são
permitidos.

## Conteúdo

Resumo; 4.1 pipeline; 4.2 fichas e casos, incidência com os dois denominadores, painel de
incidência, suavização, subtipos, sensibilidade ao critério de caso e co-detecção; 4.3 Moran
global (três rodadas), LISA antes e depois do FDR, painel LISA e mapa do VSR 2024; 4.4 painel
(pendente, CS-021); 4.5 arquivos e hashes; 5.1 hipóteses H1–H3; 5.2 impacto; 5.3 limitações
com números; referências.

## Decisões

- **Relatório e apresentação do mesmo fonte**, com a apresentação rolável e em fonte menor, em
  vez de dois textos que poderiam divergir.
- **HTML autocontido** (`embed-resources`): um único arquivo para mandar à banca.
- A nota metodológica da suavização (`docs/nota-metodologica-suavizacao.md`) tinha números
  digitados; no relatório, o mesmo conteúdo sai de `suavizacao_bayes_empirico.csv`.
- O Quarto precisa de `QUARTO_R` apontando para o R nesta máquina (o PATH do usuário foi
  atualizado no CS-001, mas shells abertos antes não o herdam).

## Erros do caminho

1. O detector de números digitados passava em falso na 1ª versão: no modo `perl`, o ponto não
   casa quebra de linha, e os blocos de código de várias linhas não eram removidos. Corrigido
   com `(?s)`; a mutação prova que ele pega número digitado.
2. `formatC` avisava porque o separador de milhar e o decimal ficavam ambos como ponto.
3. Três tabelas saíram sem número (rótulo `tab-` em vez de `tbl-`) e duas com os agentes em
   ordem alfabética; corrigidos depois de ler o texto renderizado.
