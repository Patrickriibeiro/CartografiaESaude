# ============================================================================
# guarda-append-only.ps1 — PreToolUse (Edit|Write|MultiEdit) (CS-045)
#
# NEGA edição destrutiva de documento append-only JÁ COMMITADO (trilha §3.4):
#   docs/decisoes/ADR-*.md  e  docs/release-history/*.md
#
# Fato binário verificado (não julgamento):
#   Edit / MultiEdit — cada old_string precisa reaparecer inteiro dentro do new_string
#                      (acrescentar mantém o trecho antigo; reescrever o apaga);
#   Write            — o conteúdo novo precisa começar com o conteúdo atual do arquivo.
# Arquivo ainda não commitado (rascunho do próprio item) passa: o documento só vira
# histórico depois do commit.
#
# Cicatriz: 2026-09-25, commit 6eadb5f — duas frases do release-history do CS-034
# foram reescritas em vez de corrigidas por errata.
# Limite conhecido: edição por Bash (sed, Python) não passa por aqui; a regra continua
# no CLAUDE.md. Falha de leitura sai em silêncio (exit 0): hook quebrado não trava o trabalho.
# ============================================================================
$ErrorActionPreference = 'SilentlyContinue'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$raw = [Console]::In.ReadToEnd()
if (-not $raw) { exit 0 }
try { $payload = $raw | ConvertFrom-Json } catch { exit 0 }

$ferramenta = [string]$payload.tool_name
if ($ferramenta -notin @('Edit', 'Write', 'MultiEdit')) { exit 0 }

$repo = $env:CLAUDE_PROJECT_DIR
if (-not $repo) { exit 0 }

$caminho = [string]$payload.tool_input.file_path
if (-not $caminho) { exit 0 }

# Caminho relativo ao projeto, com barras normais, sem diferenciar maiúsculas.
$raiz = ([System.IO.Path]::GetFullPath($repo)).TrimEnd('\', '/').Replace('\', '/')
$abs = ([System.IO.Path]::GetFullPath($caminho)).Replace('\', '/')
if (-not $abs.StartsWith($raiz + '/', [System.StringComparison]::OrdinalIgnoreCase)) { exit 0 }
$rel = $abs.Substring($raiz.Length + 1)

if ($rel -notmatch '^(docs/decisoes/ADR-[^/]+\.md|docs/release-history/[^/]+\.md)$') { exit 0 }

# Só vale para o que já está no último commit.
$null = git -C $repo cat-file -e "HEAD:$rel" 2>$null
if ($LASTEXITCODE -ne 0) { exit 0 }

function Normalizar([string]$t) { if ($null -eq $t) { return '' } ; return $t.Replace("`r`n", "`n") }

$destrutiva = $false
switch ($ferramenta) {
    'Edit' {
        $velho = Normalizar $payload.tool_input.old_string
        $novo = Normalizar $payload.tool_input.new_string
        if ($velho -and -not $novo.Contains($velho)) { $destrutiva = $true }
    }
    'MultiEdit' {
        foreach ($e in @($payload.tool_input.edits)) {
            $velho = Normalizar $e.old_string
            $novo = Normalizar $e.new_string
            if ($velho -and -not $novo.Contains($velho)) { $destrutiva = $true }
        }
    }
    'Write' {
        $atual = if (Test-Path -LiteralPath $caminho) { Normalizar ([System.IO.File]::ReadAllText($caminho)) } else { '' }
        $novo = Normalizar $payload.tool_input.content
        if (-not $novo.StartsWith($atual)) { $destrutiva = $true }
    }
}
if (-not $destrutiva) { exit 0 }

$motivo = "Edição NEGADA: $rel é append-only e já está commitado (trilha §3.4). " +
    "Não reescreva nem apague texto: acrescente uma seção '## Errata (data)' no FIM do " +
    "documento dizendo o que estava errado e qual é a forma correta."

@{ hookSpecificOutput = @{
        hookEventName            = 'PreToolUse'
        permissionDecision       = 'deny'
        permissionDecisionReason = $motivo
    }
} | ConvertTo-Json -Depth 4 -Compress
exit 0
