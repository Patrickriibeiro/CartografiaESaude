# CS-060 — A história da construção do projeto, contada do zero

- **Data:** 2026-09-28
- **Modelo · esforço:** Fable · medium (acordado com o dono)
- **Origem:** pedido da autora, ao tentar rodar os scripts: "me explique como se eu fosse uma
  pessoa burra, sem assumir que eu sei o que é R, Git, YAML, Quarto, renv, função, script,
  diretório, pipeline, pacote"; contar a "história da construção" passo a passo, dizendo de cada
  arquivo e pasta o que é, por que existe, por que aquele formato, o que tem dentro, quem usa
  depois, o que produz, como se liga ao seguinte e o que aconteceria sem ele; código explicado
  pela intenção antes dos trechos; termo técnico explicado na primeira vez; o que não estiver
  comprovado pelos arquivos marcado como "inferência técnica provável"; resumo em forma de
  história ao fim de cada parte.

## Verificação com número

| Critério de aceite | Resultado |
|---|---|
| Documento | `docs/historia-do-projeto.md`: 1.223 linhas, ~12.150 palavras, 9 partes (0 a 8) + apêndice com um mapa de uma linha por arquivo; 49 subseções; 9 trechos de código explicados pela intenção antes dos pedaços |
| Fidelidade | toda afirmação aponta o arquivo que a prova (ADR, release-history, comentário no código, commit); 4 frases marcadas literalmente como "inferência técnica provável" (zero à esquerda dos scripts, escolha do YAML, CSV nos resultados, e a advertência geral) |
| Linha do tempo | os 89 commits de 25 a 28/09/2026 lidos em ordem e usados como espinha da narrativa (ex.: a vizinhança, CS-016, veio antes da regra de caso, CS-007) |
| Word | `resultados/documentos/historia-do-projeto.docx`, gerado na etapa 07 pelo mesmo caminho da proposta: 4/4 tabelas, 11 títulos de parte, 49 subtítulos, 9 blocos de código; a etapa para se o nº de tabelas divergir |
| Não envelhece | teste novo: todo caminho de arquivo citado na história existe (mais de 40 conferidos) e as 8 etapas `01`–`08` aparecem nela; teste de integração confere as tabelas do Word |
| Nada mais mudou | `proposta-v2.docx` e `tabelas_abnt.docx` regenerados com o mesmo MD5 de antes |
| Testes | 823/823 expectativas em 23 arquivos, 0 falhas, 0 pulados (eram 810) |

## Decisões

- **Markdown no repositório + Word gerado pelo pipeline**, escolha do dono: o texto vive junto
  do código e o teste de caminhos avisa quando um arquivo citado for renomeado; o Word é para a
  autora ler onde está acostumada.
- **Tudo de uma vez**, sem validar o tom com as partes 1 e 2 antes (escolha do dono).
- **A construção com assistente de programação é dita no preâmbulo.** Está em todo commit
  (`Co-Authored-By`) e no `CLAUDE.md`, ambos públicos; esconder seria mentir por omissão num
  documento cujo contrato é "toda afirmação tem prova". O dono pode retirar o parágrafo.
- **Dois filtros do pandoc desligados em `montar_docx_texto()`**, com efeito também na
  proposta: bloco de metadados YAML e as tabelas sem `|` (simples, multilinha, grade). Os dois
  documentos só usam tabelas com `|`, que é o que `contar_tabelas_markdown()` conta; assim a
  conferência "tabelas do Markdown = tabelas do Word" vale por construção.

## Erros do caminho

1. O pandoc parou com "YAML parse exception": para ele, `---` depois de linha em branco abre um
   cabeçalho YAML, e a história usa `---` como traço entre partes. Extensão desligada.
2. Com o YAML resolvido, o Word saiu com 6 tabelas em vez de 4: nas junções entre as quatro
   partes do rascunho, `---` vinha seguido do título sem linha em branco, e o pandoc lê isso
   como o início de uma tabela "multiline", que só termina no próximo `---`. Duas seções
   inteiras (36 e 17 linhas) viraram tabela. A trava da etapa 07 (nº de tabelas) pegou antes
   de o documento chegar à autora. Correção dupla: linha em branco normalizada em volta de
   todo título e traço, e os formatos de tabela sem `|` desligados no conversor.
3. Um nome abreviado no texto (`-padronizacao.md`, por elipse) teria falhado no teste de
   caminhos; escrito por extenso antes de rodar.
