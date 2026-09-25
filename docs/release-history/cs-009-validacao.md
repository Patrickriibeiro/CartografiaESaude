# CS-009 — As quatro funções de validação do PDF

- **Data:** 2026-09-25
- **Modelo · esforço:** Opus · medium (acordado com o dono)
- **Origem:** tabela de funções do PDF; `R/funcoes_validacao.R` era só um comentário "a implementar"

## Verificação com número

| Critério de aceite | Resultado |
|---|---|
| 4 funções | `validar_variaveis()`, `validar_codigos_ibge()`, `validar_municipios_rj()`, `validar_datas()` |
| ≥ 2 testes por função (1 passa, 1 falha) | 19 expectativas em `test-validacao.R`: 2 + 1 (integração), 6, 2, 4, 2, 2 |
| Usadas pelo pipeline | substituem as regras escritas à mão em `ler_banco_sivep_rj()`, `preparar_sivep()`, `preparar_sivep_notificados_de_fora()`, `completar_municipios()` e `comparar_residencia_notificacao()` |
| Dados reais | etapas 01 e 02 passam; 37.562 casos; nenhuma tabela versionada mudou (`git status` limpo em `resultados/`) |
| Testes | 600/600 expectativas em 19 arquivos, 0 falhas (eram 581 em 18) |

## Critério corrigido

O BACKLOG pedia "data < 2022-01-01 ou > data do snapshot". Depois do CS-036 isso está errado:
01/01/2022 é da semana 52 de 2021, e 30/12/2025 é da semana 53 de 2025. `validar_datas()` usa a
janela do **ano epidemiológico do banco**. Ela também cobre o limite superior: o ano
epidemiológico termina no máximo em 3 de janeiro seguinte, antes da data de versão de qualquer
banco. Anos impossíveis (1695, 5202, registrados em outro projeto sobre este banco) são
recusados, com teste.

## Mensagens

As mensagens que testes antigos esperavam foram mantidas ("ano epidemiológico diferente",
"fora da lista de municípios: X"). A única mudança: residência × notificação passou de
"fora da lista: X" para "Município de notificação fora da lista de municípios: X", igual à
de casos; o teste do CS-031 foi ajustado.

## Erros do caminho

1. No Windows, `arrow::read_parquet()` mapeia o arquivo na memória (*memory-map*), e
   sobrescrever o arquivo enquanto o mapa existe falha com "erro 1224". O teste lê com
   `mmap = FALSE`.
