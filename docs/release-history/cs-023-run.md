# CS-023 — `run.R`: o pipeline inteiro, do zero, com tempo por etapa

- **Data:** 2026-09-25
- **Modelo · esforço:** Opus · low (acordado com o dono)

## Verificação com número

| Critério de aceite | Resultado |
|---|---|
| Execução do zero completa | `Rscript run.R --limpar`: 58 arquivos derivados apagados, 8 etapas refeitas em **97 s** |
| Log com 8 tempos | `resultados/execucao.log`: 01 4,4 s · 02 2,1 s · 03 1,2 s · 04 2,9 s · 05 32,5 s · 06 42,0 s · 07 0,3 s · 08 11,5 s |
| Para no primeiro erro | provado sem querer na 1ª execução: a etapa 08 falhou, as anteriores ficaram, o erro foi para o log |
| **Reprodutibilidade** | depois de apagar e refazer tudo, **todos os arquivos versionados de `resultados/` saíram byte a byte idênticos** aos commitados (inclusive `moran_lisa.rds`, com 9.999 permutações por mapa); só o `LEIA-ME.txt` muda, porque carrega data e commit |
| Testes | 15 expectativas em `test-run.R` (ordem, isolamento entre etapas, parada na falha, limpeza que preserva `.gitkeep` e brutos) |

## Decisões

- **Cada etapa num ambiente próprio**, filho do global: uma etapa não enxerga as variáveis
  da anterior, só os arquivos que ela gravou. É o que torna cada script executável sozinho.
- **`--limpar` apaga só o derivado.** Brutos e externos ficam: são cache conferido pelo
  manifesto, e baixá-los de novo não prova reprodutibilidade, só testa a internet.
- **`--sem-relatorio`** para máquinas sem Quarto (a CI do CS-025, por exemplo).
- `resultados/execucao.log` fora do git: muda a cada execução.

## Erros do caminho

1. **`system2(env = ...)` no Windows não define variável de ambiente**: cola o texto antes do
   comando, e o Quarto recebeu `QUARTO_R=...` como se fosse um subcomando. Corrigido com
   `withr::with_envvar()`. Foi a falha que provou a parada na primeira etapa com erro.
