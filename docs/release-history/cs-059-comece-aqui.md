# CS-059 — Guia "Comece aqui" e projeto do RStudio

- **Data:** 2026-09-28
- **Modelo · esforço:** Opus · low (acordado com o dono)
- **Origem:** a analista, rodando os scripts na máquina dela: não sabia quais arquivos são
  necessários para rodar do zero, nem a ordem; estava perdida com o renv; a pasta parecia
  "poluída".

## Verificação com número

| Critério de aceite | Resultado |
|---|---|
| Projeto do RStudio | `CartografiaESaude.Rproj` na raiz: dois cliques abrem o RStudio na pasta do projeto, e o `.Rprofile` liga o renv |
| renv liga sozinho numa cópia limpa | cópia do repositório numa pasta nova, R aberto nela: `renv::project()` = a pasta, 1ª biblioteca = `renv/library/...` da própria pasta, `renv::status()` lista os pacotes do lock como ainda não instalados (o estado esperado antes do `restore`), em 2,8 s |
| Guia | `COMECE-AQUI.md`: caminho curto no Windows, 3 passos, o que é o renv, a ordem das 8 etapas, mapa de pastas (rodar / gerado / ler); README aponta para ele |
| Guia não envelhece | teste novo: toda etapa `01`–`08` aparece no guia e todo script citado existe; `.Rproj` com `RestoreWorkspace: No` |
| Testes | 810/810 expectativas em 23 arquivos, 0 falhas (eram 797) |

## Decisões

- **`RestoreWorkspace: No` e `SaveWorkspace: No`** no `.Rproj`: sem um `.RData` guardado entre
  sessões, cada execução parte do zero, e um objeto antigo não mascara um erro.
- **O `renv::restore()` não foi repetido na cópia limpa**: nesta máquina ele usaria o cache global
  do renv e não representaria a máquina da analista. O restore do zero já foi medido no CS-024
  (clone limpo).
- **Não achatei a estrutura de pastas.** O "poluído" era falta de mapa, não pastas demais; o
  guia separa o que é para rodar, o que o pipeline gera e o que é só para ler.

## Erros do caminho

1. O heredoc do bash comeu a barra invertida duas vezes (num teste em R e num script Python);
   o R parou com "unrecognized escape", o Python com erro de sintaxe antes de gravar qualquer
   coisa. Ambos refeitos pela ferramenta de edição.
