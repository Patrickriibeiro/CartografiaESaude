# CS-031 — Residência × notificação

- **Data:** 2026-09-25
- **Modelo · esforço:** Opus · medium (o BACKLOG sugeria low; o dono escolheu medium)
- **Origem:** proposta v2 §3.3; limitação 8 da proposta e do relatório §5.3

## Verificação com número

| Critério de aceite | Resultado |
|---|---|
| Tabela 92 linhas com casos_res, casos_not, razão | `resultados/tabelas/residencia_notificacao.csv`: 92 linhas, mais a decomposição de cada lado e o saldo |
| Top-10 importadores | Tabela no relatório: Rio de Janeiro (+1.719), Volta Redonda (+1.109), Niterói (+1.062), Macaé, Nova Friburgo, Petrópolis, Resende, Itaperuna, Campos dos Goytacazes, Rio Bonito |
| Conservação | 37.562 por residência = grade anual (idêntica linha a linha); 37.497 por notificação = 37.562 − 210 notificados fora do RJ − 15 sem município + 160 vindos de fora do RJ |
| Exportação | `exportacao/residencia_notificacao.csv`, 92 linhas, com nome e código IBGE |
| Testes | 547/547 expectativas em 17 arquivos, 0 falhas, 0 pulados (eram 532 em 16) |
| Pipeline do zero | `run.R --limpar`: 8 etapas em 122 s |
| Reprodutibilidade | 2ª execução do zero: 80 de 81 arquivos idênticos byte a byte; difere só o LEIA-ME (carimbo de hora) |
| Relatório | nova seção "Residência e notificação"; 0 números digitados; sem aviso na renderização |

## O que precisou ser lido a mais

O recorte do estudo é por residência: o ETL lê só fichas com `CO_MUN_RES` do RJ. Para contar
por notificação faltava o complemento — fichas **notificadas** no RJ de quem **mora fora**.
Medido nos bancos (fichas, antes da regra de caso): 151, 84, 66 e 111 por ano. Depois da regra
do ADR-0002, 160 casos. Ficam em `sivep_notificados_de_fora.parquet`, separados, para nunca
entrarem numa contagem por residência.

## Decisões dentro do escopo

- **Campo:** `CO_MUN_NOT`, como pede o item. `CO_MU_INTE` (município de internação) está vazio
  em 4.698 das fichas notificadas no RJ em 2022, então seria uma medida pior do fluxo.
- **Sem taxa por notificação:** dividir casos notificados pela população do município mistura
  pacientes de fora com moradores; o relatório explica por que a taxa de risco é por residência.
- **Razão NA sem residente:** evita `Inf` e divisão 0/0.

## Achados

- 7.286 casos (19,4 %) foram notificados em outro município do estado.
- Só 13 municípios têm saldo positivo; os polos são hospitalares (capital, Volta Redonda,
  Niterói, Macaé, Campos, Itaperuna).
- São Gonçalo é o que mais perde em números absolutos (856 casos a menos por notificação);
  Belford Roxo, em proporção: 379 casos de residentes, 8 notificados no município.

## Erros do caminho

1. `substr(NA, 1, 2) != "33"` dá NA, e o filtro do arrow descarta a linha. Sem o `is.na()`
   explícito, fichas sem residência notificadas no RJ sumiriam. Provado por mutação: tirando o
   `is.na()`, 2 expectativas falham.
2. O auxiliar `ler()` do relatório passa todos os argumentos para `file.path()`; `colClasses`
   viraria parte do caminho. A leitura do CSV nessa seção usa `utils::read.csv` direto.
3. O rascunho do relatório dizia "os outros 79" (supondo nenhum saldo zero) e "8 notificados
   no próprio município" como se fossem residentes. As duas frases foram reescritas.
4. Na exploração, supus que o código 330340 era Nova Iguaçu; é Nova Friburgo. Os nomes das
   tabelas vêm sempre da malha, pelo código, nunca de memória.
