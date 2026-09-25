# CS-020 — Tabelas finais para planilha

- **Data:** 2026-09-25
- **Modelo · esforço:** Opus · low (acordado com o dono)

## Verificação com número

| Critério de aceite | Resultado |
|---|---|
| 3 CSV (o BACKLOG pedia 3) | **4 CSV**: indicadores (1.104 linhas), LISA (1.104), Moran global (36), incidência do estado (12) |
| Abrem no Excel sem acento quebrado | UTF-8 com BOM (bytes `EF BB BF` conferidos), `;` e `,`; "Niterói" relido intacto |
| Carimbo de data | `LEIA-ME.txt` com data, commit do código, critério de caso e versão de cada banco |
| Testes | 17 expectativas em `test-exportacao.R` (BOM, ida e volta, `;` dentro de texto, carimbo, integração) |

## Decisões

- O carimbo vai num `LEIA-ME.txt` ao lado dos CSV, não dentro deles: uma linha extra no
  topo viraria linha de dado no Excel.
- Formato do Excel com idioma pt-BR (`;` e `,`), não o CSV internacional (`,` e `.`), porque
  o público é a vigilância e a banca, no Brasil.
- Colunas com nome em português, o código IBGE de 7 dígitos (o que o gestor reconhece) e
  o nome do município.

## Erros do caminho

Nenhum.
