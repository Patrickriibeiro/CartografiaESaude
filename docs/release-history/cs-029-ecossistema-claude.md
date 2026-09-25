# CS-029 — Ecossistema `.claude/` do projeto

- **Data:** 2026-09-25
- **Modelo · esforço:** Opus · medium (acordado com o dono)
- **Origem:** padrão do dono (evidence → Compasso, 2026-08-01): regra no CLAUDE.md, hook que
  lembra, hook que bloqueia só o binário. "Adaptar, não copiar."

## Verificação com número

| Critério de aceite | Resultado |
|---|---|
| `CLAUDE.md` ≤ 150 linhas | 127 linhas |
| 2 hooks registrados | `SessionStart` → `contexto-inicial.ps1`; `PreToolUse (Bash\|PowerShell)` → `check-release-history.ps1`, em `.claude/settings.json` (JSON válido) |
| Hook de commit testado | 10/10 casos num repositório git descartável: nega código staged sem release-history (4 casos: `R/`, script numerado, `.qmd`, opções antes do `commit`); deixa passar commit só de docs, o do hash no BACKLOG, código + release-history, comando que não é commit, índice vazio e ausência de `CLAUDE_PROJECT_DIR` |
| Hook de contexto testado | JSON `SessionStart` válido, 19 linhas, acentos corretos |

## O que foi adaptado, não copiado

- **Sem `docs/demandas/`:** aqui o item é o `CS-0NN` do BACKLOG; o hook exige só o
  release-history (o Compasso exige dois documentos).
- **"Código" deste projeto:** `R/`, `tests/`, `config/`, `.github/`, scripts `0N_*.R|qmd`,
  `run.R`, `app.R`, `renv.lock`, `_quarto.yml`. Commit só de documentação passa — é o caso do
  segundo commit de cada item, o que registra o hash no BACKLOG.
- **Constituição** = proposta da autora; decisões de método são dela (ADR).
- **Seção de armadilhas** com as cicatrizes desta máquina (heredoc, `Rscript -e`, `fileEncoding`
  em conexão, `mmap`, avaliação preguiçosa, `substr(NA)`...), cada uma com o item de origem.
- Os hooks só entram em ação numa sessão aberta na pasta do projeto: esta sessão roda com o
  diretório do Compasso, que não foi tocado.

## Achados

- **Deslize de documento append-only** (ver errata em `cs-034-leitos-cnes.md`): no commit do
  CS-041, duas frases do release-history do CS-034 foram reescritas em vez de corrigidas por
  errata. Registrado como cicatriz no `CLAUDE.md` §3 e como **CS-045** (hook que nega edição
  destrutiva de ADR e release-history já commitados).

## Erros do caminho

Nenhum na implementação dos hooks.
