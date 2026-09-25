# ============================================================================
# check-release-history.ps1 — PreToolUse (Bash|PowerShell) (CS-029)
#
# NEGA `git commit` com código staged e nenhum docs/release-history/*.md staged.
# Por quê: cada item CS-0NN fecha com um resumo numérico; sem o hook, o resumo é o
# primeiro passo a ser esquecido quando a sessão está longa.
#
# Só bloqueia o que é fato binário (há ou não há o arquivo staged). Commit só de
# documentação — como o segundo commit, que registra o hash no BACKLOG — passa.
# Usa git -C $env:CLAUDE_PROJECT_DIR: nunca depende do diretório corrente.
# Qualquer falha de leitura sai em silêncio (exit 0): hook quebrado não trava o trabalho.
# ============================================================================
$ErrorActionPreference = 'SilentlyContinue'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$raw = [Console]::In.ReadToEnd()
if (-not $raw) { exit 0 }
try { $payload = $raw | ConvertFrom-Json } catch { exit 0 }

if ($payload.tool_name -notin @('Bash', 'PowerShell')) { exit 0 }

$cmd = [string]$payload.tool_input.command
if (-not $cmd -or $cmd -notmatch 'git(\s+\S+)*\s+commit') { exit 0 }

$repo = $env:CLAUDE_PROJECT_DIR
if (-not $repo) { exit 0 }

$staged = @(git -C $repo diff --cached --name-only 2>$null)
if ($staged.Count -eq 0) { exit 0 }

# Código = o que muda resultado ou comportamento do pipeline.
$padraoCodigo = '^(R/|tests/|config/|\.github/|0[0-9]_[^/]+\.(R|qmd)$|run\.R$|app\.R$|renv\.lock$|_quarto\.yml$)'
$codigo = @($staged | Where-Object { $_ -match $padraoCodigo })
if ($codigo.Count -eq 0) { exit 0 }

$doc = @($staged | Where-Object { $_ -match '^docs/release-history/.+\.md$' })
if ($doc.Count -gt 0) { exit 0 }

$exemplos = ($codigo | Select-Object -First 3) -join ', '
$motivo = "Commit NEGADO: código staged ($exemplos) sem resumo em docs/release-history/. " +
    "Crie e stageie docs/release-history/<cs-0nn-slug>.md com a verificação NUMÉRICA " +
    "(aceite, testes X/Y em N arquivos, erros do caminho) antes de commitar."

@{ hookSpecificOutput = @{
        hookEventName            = 'PreToolUse'
        permissionDecision       = 'deny'
        permissionDecisionReason = $motivo
    }
} | ConvertTo-Json -Depth 4 -Compress
exit 0
