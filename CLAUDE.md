# Cartografia & Saúde — Guia Claude Code

Análise espaço-temporal de SRAG (SARS-CoV-2, influenza, VSR) nos 92 municípios do RJ,
2022–2025, em R. Proposta de mestrado de Gabrielle Barbosa Teixeira Coelho (PPG-BCS,
IOC/Fiocruz, IOC14090).

**Constituição:** a proposta original (PDF, só na máquina do dono, fora do git) e a sua
revisão `docs/proposta-v2.md`. Em conflito entre código e proposta, a proposta vence até
decisão registrada em ADR (`docs/decisoes/ADR-00NN`, numeração sequencial). Quem decide
método é a **autora**; o código aplica a decisão e, se ela for provisória, diz isso.

**Posição (2026-09-25):** pipeline completo (01–08), relatório Quarto, painel Shiny,
escala regional, leitos do CNES, padronização por idade, introdução e conclusão. Repositório
**público** desde 2026-09-25 (github.com/Patrickriibeiro/CartografiaESaude, CS-026); commits com o
e-mail noreply do GitHub, nunca o pessoal (`git config user.email` já configurado no repositório).

---

## 0. Antes de qualquer implementação — o que o dono exige

1. **Recomende modelo e esforço e ESPERE confirmação.** Fable = análise profunda,
   auditoria, texto científico; Opus = executar item já especificado. Fallback do Fable:
   Opus · high. Esforço: `low` mecânico · `medium` armadilha real ou modo de falha
   silencioso · `high` espaço de solução aberto. Se ele disser o item sem modelo, pergunte.
2. **Explique o que mudou, sem esperar pedido**, em 7 itens: diff real · mecânica · alternativa
   descartada · armadilha da linguagem · o que NÃO mudou de propósito · erros do caminho ·
   **todo jargão explicado na 1ª ocorrência** (R, estatística espacial, epidemiologia e
   siglas nossas: CS-0NN, ADR, D-NN, LISA, FDR, EB). Ele está aprendendo os três domínios.

## 1. Ler antes de qualquer tarefa

- `docs/BACKLOG.md` — fonte única de feito/não-feito (itens `CS-0NN`, decisões `D-NN`).
  **Achado fora de escopo vira item com id antes de fechar o trabalho**; prosa não conta.
- `docs/trilha-desenvolvimento.md` — arquitetura, contratos entre etapas (§3.2),
  invariantes (§3.3), classes de documento (§3.4).
- Os ADRs do escopo (0001–0007) e o release-history dos itens vizinhos.

## 2. Invariantes (trilha §3.3) — cada um com a cicatriz que o originou

1. `dados/brutos/` e `dados/processados/` **nunca** entram no git (microdado; LGPD).
   Tudo que é baixado passa por `baixar_e_registrar()` e ganha SHA-256 em `dados/MANIFESTO.md`;
   ler arquivo fora do manifesto é erro. `dados/externos/**` é `binary` no `.gitattributes`
   (sem isso o git mexe na quebra de linha e o hash do clone diverge — CS-011).
2. **Nenhum número digitado no relatório**: todo número sai de `resultados/` por código
   embutido. `test-relatorio.R` procura números soltos no `.qmd`. Frase interpretativa
   ("a maior", "em todos os anos", "sobe") também tem de depender de uma conta — em 2026-09-25
   três rascunhos afirmaram o que o dado não dizia (CS-032, CS-034, CS-041).
3. **Zero explícito**: município sem caso aparece com 0, nunca some numa junção.
4. **Chave `cod6`** (6 dígitos, texto) em todas as tabelas (ADR-0007). `read.csv` a lê como
   número: use `colClasses`.
5. **Semente fixa** (`SEMENTE`) e 9.999 permutações/reamostras (ADR-0004).
6. **Ano = ano epidemiológico** do banco (domingo a sábado; 2025 tem 53 semanas). Semana
   vem de `DT_SIN_PRI`, nunca do `SEM_PRI` (erra a semana 53/2025). CS-036.
7. **Fail-closed**: dado inesperado para com `stop()` e mensagem clara (funções
   `validar_*()`, CS-009); nunca corrigir em silêncio nem inventar padrão.
8. **Verificação com número**: "532/532 em 16 arquivos" vale; "testes passando" não vale.
   Reprodutibilidade: `run.R --limpar` duas vezes → arquivos idênticos byte a byte (só o
   `LEIA-ME.txt` muda: carimba a hora).

## 3. Classes de documento (trilha §3.4)

| Classe | Arquivos | Regra |
|---|---|---|
| Intocável | PDF da proposta | não se edita |
| Append-only | `docs/decisoes/ADR-*.md`, `docs/release-history/*.md` | só se acrescenta; correção = seção "Errata" no fim |
| Vivo | `docs/BACKLOG.md`, `docs/trilha-desenvolvimento.md`, `docs/proposta-v2.md`, `README.md` | reflete o estado atual |

Cicatriz: em 2026-09-25 duas frases do release-history do CS-034, já commitado, foram
reescritas em vez de corrigidas por errata (errata registrada depois; hook no CS-045).

## 4. Fechamento de cada item (padrão do projeto)

1. `docs/release-history/<cs-0nn-slug>.md`: tabela de aceite com números, decisões,
   achados, erros do caminho.
2. `docs/BACKLOG.md`: item sai de Abertos e entra em Encerrados com data, doc e
   `commit (a registrar)`.
3. Commit do item → segundo commit só com o hash no BACKLOG → `git push`.
   Mensagens terminam com `Co-Authored-By` do modelo usado.
4. Docs vivos que a mudança tornou mentira: README (saídas, tempos), trilha (§3.2),
   proposta v2 (texto que descreve o que o código faz).

## 5. Hooks ativos (`.claude/settings.json`)

*Quem mexer nos hooks atualiza esta seção.*

- **SessionStart** → `contexto-inicial.ps1`: constituição, invariantes, comandos (curto).
- **PreToolUse (Bash|PowerShell)** → `check-release-history.ps1`: **nega** `git commit` com
  código staged (`R/`, `tests/`, `config/`, scripts `0N_*.R`, `run.R`, `app.R`, `08_relatorio.qmd`,
  `renv.lock`, `.github/`) sem nenhum `docs/release-history/*.md` staged. Commit só de
  docs (como o do hash no BACKLOG) passa.
- **PreToolUse (Edit|Write|MultiEdit)** → `guarda-append-only.ps1` (CS-045): **nega** edição
  destrutiva de `docs/decisoes/ADR-*.md` e `docs/release-history/*.md` já commitados — Edit
  cujo trecho antigo não reaparece no novo; Write que não começa com o conteúdo atual.
  Acrescentar (inclusive no meio) passa; rascunho não commitado passa. Edição por Bash
  (`sed`, Python) não passa pelo hook: aí vale a regra do §3.

Só se bloqueia o que é fato binário; julgamento (profundidade da explicação, qualidade do
texto) não vira bloqueio.

## 6. Como rodar (Windows desta máquina)

```bash
"C:/Users/Patrick/AppData/Local/Programs/R/R-4.6.1/bin/Rscript.exe" run.R            # tudo
"C:/Users/Patrick/AppData/Local/Programs/R/R-4.6.1/bin/Rscript.exe" run.R --limpar   # do zero
QUARTO_R="C:/Users/Patrick/AppData/Local/Programs/R/R-4.6.1/bin" "/c/Program Files/Quarto/bin/quarto.exe" render 08_relatorio.qmd
```

Testes: `testthat::test_dir("tests/testthat")` (contar arquivos, expectativas e falhas).
Auditoria independente antes de entrega: `tests/auditoria_independente.R`.

## 7. Armadilhas já pagas nesta máquina

- **Heredoc do bash come barra invertida** (`"\\."` virou `"\."` e quebrou o `00_setup.R`;
  de novo em 2026-09-25 no CS-034). Código com `\` vai por arquivo (ferramenta Write).
- `Rscript -e` com várias linhas roda só a primeira: use arquivo `.R`.
- Python não abre `/c/...`: use `C:/...`.
- `system2(env =)` não funciona no Windows: `withr::with_envvar`.
- `merge()` num `sf` sem `library(sf)` perde a classe: refaça com `sf::st_as_sf`.
- ggplot2 4.x: legenda de nível ausente exige `show.legend = TRUE`; `check_overlap` apaga rótulo.
- `read.csv` **ignora `fileEncoding` quando recebe conexão**; `unz(encoding =)` também não
  converteu: leia as linhas e use `iconv()` (CS-034).
- `arrow::read_parquet` mapeia o arquivo na memória: no Windows não dá para sobrescrevê-lo
  em seguida (erro 1224); use `mmap = FALSE`.
- Filtro com `substr(NA, 1, 2) != "33"` descarta a linha: `is.na()` explícito (CS-031).
- **Avaliação preguiçosa**: argumento de função só roda quando usado; um `item_zip()` passado
  direto registrou o arquivo no manifesto depois da leitura do manifesto (CS-034).
- `spdep::moran.mc` recusa `nsim` maior que n!.
- `renv` falha em caminho com mais de ~150 caracteres no Windows: clone em pasta curta.

## 8. Fora do alcance do Claude

Configurações da conta do GitHub (cobrança, visibilidade; a CI roda grátis porque o repositório é público); decisões de método da autora (D-11
provisória: contagens pequenas publicadas com nota); Apêndice A da proposta (texto pessoal da autora).
