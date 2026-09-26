# CS-051 — Tabelas em formatação ABNT, prontas para uso

- **Data:** 2026-09-26
- **Modelo · esforço:** Opus · medium (acordado com o dono)
- **Origem:** pedido da analista: "toda planilha também ser exportada como tabela formatação ABNT pronta para uso"

## Verificação com número

| Critério de aceite | Resultado |
|---|---|
| N tabelas no .docx = N CSVs | `tabelas_abnt.docx`: **14 tabelas** para 14 CSVs (conferido na etapa 07 contando `<w:tbl>` no XML) |
| Formatação | título acima ("Tabela N – ..."), fonte abaixo (e nota), traço no topo, sob o cabeçalho e no fim, nenhuma linha vertical nem interna, cabeçalho em negrito e repetido nas quebras de página (14/14), Arial 9 nas tabelas, A4 paisagem com margens de 3 e 2 cm, números com vírgula decimal e ponto de milhar |
| Série semanal | resumida por mês no Word (480 linhas: 10 recortes × 48 meses); a íntegra (6.270 linhas) fica no CSV, dito na nota da tabela |
| Reprodutível | 2 execuções seguidas: mesmo SHA-256; teste confere bytes iguais |
| Tempo | etapa 07 em 4,3 s (a 1ª versão, com `flextable` + `officer`, levava ~5 min) |
| Testes | 739/739 expectativas em 23 arquivos, 0 falhas (eram 717 em 22); 22 em `test-abnt.R` (o que gera o .docx é pulado sem Quarto, como na CI) |
| Pacotes | só `zip` entra no `renv.lock` |

## Decisões

- **pandoc (do Quarto) em vez de `flextable` + `officer`.** A gravação do `officer` cresce mais que
  linearmente com o tamanho do documento (medido: 400 linhas 9 s; 1.104 linhas 50 s; documento todo
  ~5 min; o perfil aponta expressões regulares sobre o XML inteiro). O pandoc gera o mesmo documento
  em segundos. O estilo ABNT vai num documento de referência criado pelo código a partir do padrão do
  próprio pandoc (estilo "Table" com os três traços, Arial, página em paisagem). Os 11 pacotes que
  o `flextable` trouxe foram removidos da biblioteca do projeto.
- **Mesmos objetos dos CSV**, na mesma ordem: Word e Excel nunca divergem.
- **Norma:** ABNT NBR 14724 remete às Normas de Apresentação Tabular do IBGE (título acima, fonte
  abaixo, traços horizontais só no topo, sob o cabeçalho e no fim).
- Sem Quarto na máquina, a etapa avisa e não gera o .docx (como o relatório).

## Erros do caminho

1. `flextable` + `officer`: ~5 min por execução; medido, perfilado e trocado (acima).
2. Contagem de tabelas com `docx_summary()` errou (índice por célula, não por tabela) e levava
   29 s; trocada por contar `<w:tbl>` no XML.
3. Expressão regular sem `(?s)` não casava o estilo de várias linhas; a trava (`stop` se o estilo
   não for aplicado) pegou antes de gerar um Word sem formatação ABNT.
4. Rótulos sem acento ("Codigo IBGE"): dicionário de palavras acentuadas e rótulos especiais.
5. O .docx mudava a cada execução: primeiro pelas datas internas (resolvido com `SOURCE_DATE_EPOCH`),
   depois pelas datas de 4 partes copiadas do documento de referência (resolvido fixando a data dos
   arquivos da referência). Conferido por hash.
6. `snapshot.type: all` do `renv` registrava todo pacote instalado, inclusive os descartados.
