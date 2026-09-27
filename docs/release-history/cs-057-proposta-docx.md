# CS-057 — Proposta v2 em Word para a analista editar

- **Data:** 2026-09-26
- **Modelo · esforço:** Opus · medium (acordado com o dono)
- **Origem:** pergunta do dono: dá para devolver a proposta em Word já com as correções, ou a
  analista ajusta a partir do `proposta-v2.md`? O original que o projeto recebeu é o PDF (não há
  .docx da autora na máquina); a proposta corrigida existe só em Markdown.

## Verificação com número

| Critério de aceite | Resultado |
|---|---|
| Conteúdo completo | `resultados/documentos/proposta-v2.docx`: 7/7 tabelas do Markdown (a etapa 07 para se divergir), 10/10 fórmulas como equações do Word (editáveis, não imagem), 5/5 marcas [REVISAR] |
| Formatação | A4 retrato, margens 3/2 cm, Arial 12, corpo justificado com entrelinha 1,5, títulos em preto e negrito (14/12/12 pt; o padrão do pandoc era azul, 20 pt), tabelas no estilo ABNT do CS-051, idioma pt-BR (corretor ortográfico em português) |
| "~190 colunas" | continua texto: markdown do pandoc sem subscrito (senão "~" abriria um subscrito) |
| Reprodutível | mesma entrada → mesmos bytes (teste); gerado em 1,1 s |
| `tabelas_abnt.docx` | inalterado (o modo texto é opcional na função que cria a referência) |
| Testes | 795/795 expectativas em 23 arquivos, 0 falhas (inclui o CS-054 a CS-056); 3 testes novos em `test-abnt.R` |

## Decisões

- **Gerado pelo pipeline (etapa 07)**, como as tabelas em Word, e não à mão: toda mudança no
  `proposta-v2.md` chega ao Word na próxima execução.
- **Nova pasta `resultados/documentos/`**, versionada (documento, não tabela).
- **Para a analista ver o que mudou**: no Word, Revisão › Comparar, com o original dela à
  esquerda e este à direita; o Word marca cada diferença como alteração controlada.

## Erros do caminho

1. O pandoc regrava o XML dos estilos (atributos em outra ordem, `<w:b />` com espaço): os testes
   procuravam o texto exato e falharam 4 vezes; padrões passaram a aceitar as duas formas.
2. Barra invertida perdida de novo num script Python por heredoc (`"^\|..."`, escape inválido em
   R); corrigida pela ferramenta de edição.
3. `criar_diretorios()` ganhou a 9ª pasta e o teste de idempotência, que contava 8, pegou.
