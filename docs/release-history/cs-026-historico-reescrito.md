# CS-026 (1ª parte) — Histórico reescrito sem o PDF da proposta

- **Data:** 2026-09-25
- **Modelo · esforço:** Opus · low (acordado com o dono)
- **Decisão do dono:** conta `Patrickriibeiro`, nome `CartografiaESaude`, opção (a) reescrever o
  histórico, criar privado primeiro

## O que foi feito

O PDF da proposta (`23092026_ Seminário…pdf`, documento da autora) estava só no primeiro
commit. O histórico foi reescrito com `git filter-branch`, nativo do git, sem instalar nada:

- **filtro de árvore:** apaga o PDF de cada commit e troca, nos arquivos de texto, os hashes
  de commits antigos citados pelos novos;
- **filtro de mensagem:** faz a mesma troca nas mensagens de commit.

A troca é possível porque o `filter-branch` reescreve do commit mais antigo para o mais novo e
grava o mapa antigo → novo à medida que avança. Um commit só cita commits anteriores, que já
estão no mapa. Os filtros ficaram fora do repositório, na pasta temporária da sessão.

## Verificação com número

| Conferência | Resultado |
|---|---|
| Ensaio num clone antes do repositório real | idêntico ao resultado real |
| Commits antes e depois | 37 e 37, na mesma ordem |
| Commits de `main` que tocam o PDF | **0** |
| Objetos com o PDF no repositório local (depois do `gc`) | **0** |
| Diferença entre a árvore final antiga e a nova | 5 arquivos: o PDF removido e 4 com hashes trocados |
| Hashes de commit citados nos documentos | 18, **todos** existentes no histórico novo |
| Hashes citados nas mensagens | 17, todos existentes |
| Suíte depois da reescrita | 491/491 |
| Backup | espelho completo do histórico original e cópia do PDF (SHA-256 conferido), na pasta temporária da sessão |

O PDF continua na pasta do projeto, na máquina do dono, fora do git (`.gitignore`).

## Mapa de commits (antigo → novo)

Para quem anotou um hash antigo fora do repositório. É o único lugar do repositório onde
hashes antigos aparecem, de propósito.

| # | Antigo | Novo |
|---|---|---|
| 1 | `04c52af` | `b66ae13` |
| 2 | `6e94e6e` | `fc7e616` |
| 3 | `eb27408` | `5f09f23` |
| 4 | `5b198bc` | `975b34a` |
| 5 | `9221b93` | `0f38200` |
| 6 | `364ae05` | `023dd90` |
| 7 | `07fa629` | `0d3d91a` |
| 8 | `59e4721` | `4af4061` |
| 9 | `365078f` | `72970cf` |
| 10 | `82aae79` | `30de450` |
| 11 | `ac3919e` | `df1606a` |
| 12 | `4b12bae` | `6c2e4b1` |
| 13 | `f4d774d` | `9cb75c1` |
| 14 | `dfbf0ee` | `327694a` |
| 15 | `eac188c` | `fd70ede` |
| 16 | `e920748` | `240e8a1` |
| 17 | `0617204` | `f2de809` |
| 18 | `4451b03` | `3bba681` |
| 19 | `0dfed34` | `7894a49` |
| 20 | `5f997a7` | `4962c0b` |
| 21 | `6eed56e` | `5ce52e5` |
| 22 | `54f9f3e` | `20dc23d` |
| 23 | `00b2710` | `e218203` |
| 24 | `bb07224` | `d9f475e` |
| 25 | `852b5f9` | `2872e49` |
| 26 | `fdd1372` | `e757212` |
| 27 | `08a4175` | `a4228e5` |
| 28 | `e9369b3` | `486e549` |
| 29 | `7092cf2` | `c4c145f` |
| 30 | `8dbce00` | `968fd97` |
| 31 | `466854f` | `e6094fe` |
| 32 | `533e695` | `ce956b8` |
| 33 | `1fdb494` | `d0eb9e0` |
| 34 | `f1c799f` | `b0b1420` |
| 35 | `97f5467` | `cb0089b` |
| 36 | `133f3b4` | `a850a92` |
| 37 | `03b45d4` | `83e6b5f` |

## Erros do caminho

Nenhum na reescrita. O `git filter-repo`, recomendado pelo próprio git, não estava instalado;
o `filter-branch` nativo bastou para 37 commits e evitou instalar ferramenta nova. Um script
auxiliar da documentação falhou antes de escrever (caminho do shell passado ao Python) e foi
refeito.
