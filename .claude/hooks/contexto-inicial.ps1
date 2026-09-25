# ============================================================================
# contexto-inicial.ps1 — SessionStart (CS-029)
#
# Injeta o mínimo que toda sessão precisa saber sobre o Cartografia & Saúde.
# Regra herdada do padrão do dono (evidence → Compasso, 2026-08-01): hook que fala
# demais deixa de ser lido. Aqui vai só o que muda decisão; o detalhe está no CLAUDE.md.
# ============================================================================
$ErrorActionPreference = 'SilentlyContinue'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$null = [Console]::In.ReadToEnd()

$contexto = @"
[Cartografia & Saúde — contexto da sessão]

PROJETO: SRAG (SARS-CoV-2, influenza, VSR) nos 92 municípios do RJ, 2022-2025, em R.
Constituição = proposta da autora (PDF local + docs/proposta-v2.md); método é decisão DELA,
registrada em ADR (docs/decisoes/). Repositório PÚBLICO desde 2026-09-25: nunca commitar microdado,
segredo ou o e-mail pessoal do dono (use o noreply do GitHub, já configurado).

ANTES DE IMPLEMENTAR: recomende modelo + esforço e ESPERE o dono confirmar.
DEPOIS: explicação didática em 7 itens, com todo jargão explicado na 1ª ocorrência.

INVARIANTES: microdado fora do git; todo download no MANIFESTO (SHA-256); nenhum número
digitado no relatório (e frase interpretativa também depende de conta); zero explícito;
chave cod6 texto; semente fixa; ano = ano epidemiológico; fail-closed (validar_*()).

DOCS: ADR e release-history são APPEND-ONLY (correção = "Errata" no fim).
FECHAR ITEM: release-history + BACKLOG (Encerrados) + commit + commit do hash + push.
Commit de código sem docs/release-history/*.md staged é NEGADO por hook.

VERIFICAÇÃO COM NÚMERO: "630/630 em 20 arquivos" vale; "testes passando" não vale.
FONTE DE VERDADE: docs/BACKLOG.md (CS-0NN). Leia antes de começar.
"@

@{ hookSpecificOutput = @{ hookEventName = 'SessionStart'; additionalContext = $contexto } } |
    ConvertTo-Json -Depth 4 -Compress
exit 0
