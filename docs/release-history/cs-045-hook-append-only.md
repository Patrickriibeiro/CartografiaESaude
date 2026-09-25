# CS-045 — Hook de append-only para ADR e release-history

- **Data:** 2026-09-25
- **Modelo · esforço:** Opus · medium (acordado com o dono)
- **Origem:** achado do CS-029 — no commit `6eadb5f` duas frases do release-history do CS-034,
  já commitado, foram reescritas em vez de corrigidas por errata

## Verificação com número

| Critério de aceite | Resultado |
|---|---|
| Hook registrado | `PreToolUse (Edit\|Write\|MultiEdit)` → `guarda-append-only.ps1` em `.claude/settings.json` (JSON conferido: 1 evento SessionStart, 2 matchers PreToolUse) |
| ≥ 4 casos testados | 14/14 num repositório descartável + 1 no repositório real (reescrever a errata do CS-034 → `deny`) |
| Nega reescrita | Edit que troca frase; Edit que apaga linha (new vazio); MultiEdit com uma edição destrutiva; Write com conteúdo diferente; caminho com maiúsculas |
| Deixa acrescentar | Edit com o trecho antigo contido no novo; MultiEdit só de acréscimos; Write = conteúdo atual + errata (arquivo CRLF, conteúdo novo LF) |
| Deixa o resto | release-history ainda não commitado; arquivo novo; doc vivo (BACKLOG); arquivo fora do projeto; ferramenta Bash; sem `CLAUDE_PROJECT_DIR` |

## Como decide (fato binário)

- Só olha `docs/decisoes/ADR-*.md` e `docs/release-history/*.md` que existem no `HEAD`
  (`git cat-file -e HEAD:<caminho>`): rascunho do próprio item ainda pode ser reescrito.
- **Edit / MultiEdit:** cada `old_string` tem de reaparecer inteiro no `new_string`.
- **Write:** o conteúdo novo tem de começar com o conteúdo atual do arquivo.
- Quebras de linha normalizadas (CRLF → LF) antes de comparar: o git do Windows grava CRLF na
  cópia de trabalho, e sem isso toda errata via Write seria negada.

## Limites conhecidos (registrados no CLAUDE.md §5)

- Garante que **nada é apagado nem alterado**, não que o acréscimo vá para o fim: inserir um
  parágrafo no meio passa (é o caso da nota do CS-036 no ADR-0003, que só acrescentou).
- Edição por Bash (`sed`, Python) não passa pelo hook — foi assim que o deslize do CS-034
  aconteceu. Para isso vale a regra escrita; bloquear comandos de shell por conteúdo seria
  julgamento, não fato binário.

## Erros do caminho

Nenhum.
