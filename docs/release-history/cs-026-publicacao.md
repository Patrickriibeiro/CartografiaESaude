# CS-026 (2ª parte) — E-mail dos commits e publicação

- **Data:** 2026-09-25
- **Modelo · esforço:** Opus (execução de item já decidido)
- **Decisão do dono:** "CS-026, pode tornar público"; perguntado sobre o e-mail pessoal nos commits,
  escolheu "trocar e-mail, depois publicar"
- **Decisão da autora:** D-01 (Gabrielle e Patrick autores; MIT para o código, CC-BY 4.0 para o relatório)

## Por que a reescrita

Os 65 commits levavam o e-mail pessoal do dono como autor e como quem fez o commit. Num
repositório público, esse e-mail fica visível para qualquer pessoa, e não há como retirá-lo
depois. Antes de publicar, o histórico foi reescrito com o endereço noreply do GitHub
(`54336097+Patrickriibeiro@users.noreply.github.com`), pelo mesmo método da 1ª parte:
`git filter-branch` com filtro de ambiente (e-mail), de árvore (hashes citados em arquivos de
texto) e de mensagem (hashes citados nas mensagens). O filtro de árvore não entra em `dados/`,
onde o manifesto guarda SHA-256 que um hash curto poderia coincidir.

## Verificação com número

| Conferência | Resultado |
|---|---|
| Auditoria antes de publicar | único PDF no histórico = dicionário oficial do SIVEP; nenhum microdado; nenhum e-mail no conteúdo dos arquivos |
| Ensaio num clone | HEAD `065dc0f`, **idêntico** ao do repositório real depois da reescrita |
| Commits antes e depois | 65 e 65, na mesma ordem, assuntos iguais a menos dos hashes trocados |
| E-mail pessoal em commits (local, qualquer ref) | **0** de 65 |
| E-mail pessoal nos commits do GitHub (API) | **0**; os 65 com o noreply |
| Diferença entre a árvore final antiga e a nova | 8 arquivos, só as citações de hash |
| Hashes citados | 51 nos documentos e 30 nas mensagens, **todos** existentes no histórico novo; 0 antigos |
| Backup | espelho completo do histórico anterior na pasta temporária da sessão |
| Publicação | `gh repo edit --visibility public`; acesso anônimo HTTP 200; licença MIT reconhecida pelo GitHub |

## Consequências

- **Todos os hashes mudaram de novo.** Documentos e mensagens foram atualizados na reescrita; a
  tabela abaixo serve a quem anotou um hash fora do repositório.
- O repositório local tem `user.email` = noreply, para que commits novos não tragam o e-mail
  pessoal de volta.
- Commits antigos, não referenciados, podem continuar acessíveis no GitHub por SHA direto até a
  coleta de lixo do servidor; como o repositório era privado, ninguém de fora conhece esses SHA.
- Com o repositório público, o GitHub Actions é gratuito: o bloqueio de cobrança do CS-025 deixa
  de valer para este repositório.

## Mapa de commits (antigo → novo)

| # | Antigo | Novo | Assunto |
|---|---|---|---|
| 1 | `3855138` | `b66ae13` | CS-001 + CS-002: ambiente R 4.6.1 e esqueleto do repositório |
| 2 | `80f9959` | `fc7e616` | BACKLOG: registra o commit b66ae13 no encerramento de CS-001/CS-002 |
| 3 | `97acac1` | `5f09f23` | CS-003 + CS-004: manifesto de proveniência e dicionário oficial do SIVEP |
| 4 | `75530ef` | `975b34a` | BACKLOG: registra o commit 5f09f23 no encerramento de CS-003/CS-004 |
| 5 | `a6d58fb` | `0f38200` | CS-005 + CS-006: download e preparo do SIVEP-Gripe do RJ (ADR-0001) |
| 6 | `568bfec` | `023dd90` | BACKLOG: registra o commit 0f38200 no encerramento de CS-005/CS-006 |
| 7 | `436080a` | `0d3d91a` | CS-011 + CS-014: população do IBGE e malha municipal oficial (ADR-0003, ADR-0006) |
| 8 | `beb11a5` | `4af4061` | BACKLOG: registra o commit 0d3d91a no encerramento de CS-011/CS-014/CS-015 |
| 9 | `6b4701d` | `72970cf` | CS-016: vizinhança Queen e pesos espaciais estilo W |
| 10 | `9b01d0e` | `30de450` | BACKLOG: registra o commit 72970cf no encerramento do CS-016 |
| 11 | `bc49756` | `df1606a` | CS-007: ADR-0002 (proposto) — critério de caso por agente e co-detecção |
| 12 | `78b97f8` | `6c2e4b1` | BACKLOG: registra o commit df1606a no encerramento do CS-007 |
| 13 | `702b262` | `9cb75c1` | CS-037 + CS-038: proposta v2 com os achados dos ADRs e nota do IBGE citada |
| 14 | `cc676a4` | `327694a` | BACKLOG: registra o commit 9cb75c1 no encerramento de CS-037/CS-038 |
| 15 | `6e9fb76` | `fd70ede` | Registra o aceite da autora: D-01, D-04, D-05, D-06, D-08, D-09, D-10 e CS-039 |
| 16 | `0ec910c` | `240e8a1` | CS-008 + CS-010: classificação por agente e base sintética de testes |
| 17 | `af00a12` | `f2de809` | BACKLOG: registra o commit 240e8a1 no encerramento de CS-008/CS-010 |
| 18 | `9b3d166` | `3bba681` | CS-012: casos e incidência por município, agente e ano (D-05) |
| 19 | `d2be065` | `7894a49` | BACKLOG: registra o commit 3bba681 no encerramento do CS-012 |
| 20 | `5d449e8` | `4962c0b` | CS-013: suavização empírica de Bayes (D-09) |
| 21 | `e1304e4` | `5ce52e5` | BACKLOG: registra o commit 4962c0b no encerramento do CS-013 |
| 22 | `8914676` | `20dc23d` | CS-017 + CS-018: Moran global e LISA com ADR-0004 |
| 23 | `fb110f0` | `e218203` | BACKLOG: registra o commit 20dc23d no encerramento de CS-017/CS-018/CS-039 |
| 24 | `b797103` | `d9f475e` | CS-019: mapas de incidência e de LISA |
| 25 | `8232c81` | `2872e49` | BACKLOG: registra o commit d9f475e no encerramento do CS-019 |
| 26 | `fa3db4a` | `e757212` | CS-020: tabelas finais para planilha (Excel pt-BR) |
| 27 | `00b722f` | `a4228e5` | BACKLOG: registra o commit e757212 no encerramento do CS-020 |
| 28 | `d1ee4a6` | `486e549` | CS-022 + CS-040: relatório e apresentação em Quarto |
| 29 | `b1e8b6f` | `c4c145f` | BACKLOG: registra o commit 486e549 no encerramento de CS-022/CS-040 |
| 30 | `89441d4` | `968fd97` | CS-021: painel Shiny + leaflet para a vigilância |
| 31 | `63c8d53` | `e6094fe` | BACKLOG: registra o commit 968fd97 no encerramento do CS-021 |
| 32 | `7bb40cd` | `ce956b8` | CS-023: run.R executa o pipeline do zero, com tempo por etapa |
| 33 | `4340710` | `d0eb9e0` | BACKLOG: registra o commit ce956b8 no encerramento do CS-023 |
| 34 | `4e0df3a` | `b0b1420` | CS-024: README de máquina nova, testado num clone limpo |
| 35 | `1d9a135` | `cb0089b` | BACKLOG: registra o commit b0b1420 no encerramento do CS-024 |
| 36 | `8927f96` | `a850a92` | CS-025: workflow de integração contínua (falta a 1ª execução no GitHub) |
| 37 | `061aa39` | `83e6b5f` | CS-026 (preparação): licenças MIT e CC-BY 4.0 e CITATION.cff |
| 38 | `abb582d` | `0365ebe` | CS-026: histórico reescrito sem o PDF da proposta; endereço do repositório |
| 39 | `063c476` | `35c5ea1` | BACKLOG: repositório privado criado; CI bloqueada pela cobrança da conta |
| 40 | `924806a` | `96fc3a2` | CS-027: auditoria final |
| 41 | `da1e108` | `5ccda74` | BACKLOG: registra o commit 96fc3a2 no encerramento do CS-027 |
| 42 | `ed6d257` | `ac8853a` | CS-043 + CS-044: contagens pequenas e limitações completas |
| 43 | `5c65d82` | `5abe171` | BACKLOG: registra o commit ac8853a no encerramento de CS-043/CS-044 |
| 44 | `d903767` | `df78168` | CS-030: escala de região de saúde |
| 45 | `71a6f70` | `f0d3338` | BACKLOG: registra o commit df78168 no encerramento do CS-030 |
| 46 | `48c019f` | `bfa1e24` | CS-031: residência × notificação |
| 47 | `b713636` | `d582c56` | BACKLOG: registra o commit bfa1e24 no encerramento do CS-031 |
| 48 | `f4c5195` | `798711f` | CS-032 + CS-035: série semanal e fichas não encerradas |
| 49 | `5579f31` | `49df8ec` | BACKLOG: registra o commit 798711f no encerramento de CS-032/CS-035 |
| 50 | `8908ccf` | `b9dfe7b` | CS-036: o ano do estudo é o ano epidemiológico |
| 51 | `b19acc2` | `a2a25e5` | BACKLOG: registra o commit b9dfe7b no encerramento do CS-036 |
| 52 | `c38d414` | `7989ac4` | CS-009: as quatro funções de validação do PDF |
| 53 | `4e364f1` | `4eb151e` | BACKLOG: registra o commit 7989ac4 no encerramento do CS-009 |
| 54 | `26f7854` | `df0304d` | CS-034: leitos SUS do CNES e taxa por residência (OE10) |
| 55 | `7c74f02` | `1c649d8` | BACKLOG: registra o commit df0304d no encerramento do CS-034 |
| 56 | `be032f9` | `6eadb5f` | CS-041: o agrupamento de zeros da taxa bruta |
| 57 | `b93151a` | `88f7cd0` | BACKLOG: registra o commit 6eadb5f no encerramento do CS-041 |
| 58 | `55f468c` | `3125536` | CS-029: ecossistema .claude/ do projeto |
| 59 | `2d19320` | `ccdd134` | BACKLOG: registra o commit 3125536 no encerramento do CS-029 |
| 60 | `5b06889` | `d666f60` | CS-045: hook de append-only para ADR e release-history |
| 61 | `6693973` | `50e05e1` | BACKLOG: registra o commit d666f60 no encerramento do CS-045 |
| 62 | `59b1f4d` | `a035515` | CS-033: padronização por idade pelo método direto (OE9) |
| 63 | `bb63700` | `bb2d930` | BACKLOG: registra o commit a035515 no encerramento do CS-033 |
| 64 | `d163e05` | `b71d4b5` | CS-028: Introdução e Conclusão do relatório |
| 65 | `05d9618` | `065dc0f` | BACKLOG: registra o commit b71d4b5 no encerramento do CS-028 |
