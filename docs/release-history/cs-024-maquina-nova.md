# CS-024 — `renv.lock` congelado e README de máquina nova

- **Data:** 2026-09-25
- **Modelo · esforço:** Opus · low (acordado com o dono)

## Verificação com número

O roteiro do README foi executado num **clone limpo** do repositório, numa pasta temporária,
sem dados brutos, processados nem mapas.

| Passo do README | Resultado no clone |
|---|---|
| `renv::restore()` | 124 pacotes em **6 s**, porque vieram do cache local do `renv` (ver limitação) |
| Testes antes dos dados | **383 expectativas**, 0 falhas; **6 de 119 testes pulados** (integração, sem dados) |
| `Rscript run.R --sem-relatorio` | 7 etapas em **89 s**, inclusive o **download real** dos 4 bancos (113,9 MB) |
| Downloads conferidos | cada banco baixado de novo bateu com o SHA-256 do manifesto versionado |
| Testes depois dos dados | **491/491**, 0 pulados |
| Resultados iguais aos do repositório | `git diff` no clone: só o `LEIA-ME.txt` (data e commit) muda; todas as tabelas e estatísticas iguais |

## Limitação desta verificação

O clone foi feito na mesma máquina. Os pacotes vieram do cache do `renv` em vez de serem
baixados, e o R, o Quarto e o `renv` já estavam instalados. O tempo de instalação numa máquina
realmente nova (R + ~140 pacotes binários do CRAN) não foi medido. O CS-025 (integração
contínua) é que roda o `restore` num ambiente sem nada.

## O que o README passou a ter

Pré-requisitos (R ≥ 4.6, Quarto ≥ 1.10 só para o relatório, Git), os 5 passos (clonar,
restaurar, testar, rodar, abrir o painel), o que sai e onde, os documentos, a estrutura, e
a nota sobre microdados fora do git. Os tempos citados são os medidos.

## Erros do caminho

Um `git stash` desnecessário antes do `git clone .` (o clone copia só o que está commitado).
Conferido depois: o README não commitado voltou intacto e a pilha do stash ficou vazia.
