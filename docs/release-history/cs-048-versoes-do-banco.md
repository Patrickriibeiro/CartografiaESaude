# CS-048 — Quanto os números mudam depois do fim do ano

- **Data:** 2026-09-26
- **Modelo · esforço:** Opus · medium (acordado com o dono)
- **Origem:** pedido da analista: "tempo de atualização dos dados após o encerramento do ano; alguns
  casos são alterados após o lançamento"

## Achado que mudou o escopo

O BACKLOG supunha que só havia a versão atual do banco de 2025 e que a comparação entre versões
rodaria só na próxima atualização. O portal lista só a atual, e o S3 recusa listagem, mas os
arquivos antigos continuam lá: testando o endereço de cada data (`INFLUD25-DD-MM-AAAA.parquet`,
só o cabeçalho HTTP), foram achadas **19 versões semanais do banco de 2025** (09/03 a 24/08/2026) e
**1 versão anterior do banco de 2024** (26/06/2025). Foram usadas 6 de 2025 (uma por mês) e a de
2024, registradas no manifesto em `dados/brutos/versoes/` (fora do git).

## Verificação com número

| Critério de aceite | Resultado |
|---|---|
| Tabela por ano (dias até encerrar; % em 30/60/90 d) | `tempo_encerramento.csv`: mediana 22 · 18 · 17 · 15 dias (2022–2025); p90 84 · 90 · 56 · 55; em até 90 dias 85 · 85 · 90 · 93 % |
| Função testada com 2 snapshots sintéticos | `comparar_versoes()` e `resumir_versao()` testadas; `resumir_versao()` dá os mesmos casos que o caminho normal na base sintética |
| Comparação entre versões | **feita com dados reais**: 2025, da versão de 65 dias após o fim do ano à do estudo (254 dias): fichas 23.240 → 23.324 (+84); casos por vírus variam no máximo 3 (0,09 %). 2024: versão de 180 dias idêntica à atual (450 dias) |
| Contrato | a versão de referência resumida dá exatamente os casos do pipeline principal (`stopifnot` na etapa 01) |
| Nota no relatório | seção "Quanto os números mudam depois do fim do ano", tabela e figura; limite declarado (primeiros 65 dias não mensuráveis) |
| Exportação | `versoes_do_banco.csv` (9 linhas), `tempo_ate_encerramento.csv` (4) |
| Testes | 717/717 expectativas em 22 arquivos, 0 falhas (eram 695) |
| Pipeline do zero | 8 etapas em 164 s |

## Outros achados

- Uma ficha **encerrada foi reaberta** entre 24/08 e 14/09/2026 (encerradas 23.187 → 23.186).
- Os dados abertos não têm identificador de ficha: a comparação é por contagens agregadas, não
  ficha a ficha.

## Decisões

- Gráfico em **diferença absoluta de casos**, não em %: a 1ª versão, em % da versão do estudo, tinha
  eixo de 99,9 % a 100,1 % e fazia diferenças de 1 a 3 casos parecerem oscilações grandes.
- Versões antigas não passam pelas validações do estudo: fichas fora do ano epidemiológico são
  contadas (`fora_do_ano`, 0 em todas) e descartadas, em vez de parar o pipeline.

## Erros do caminho

1. Gráfico enganoso em % (acima), trocado depois de olhar a imagem.
2. Texto dizia "comparadas 7 versões" contando a própria versão do estudo; são 6 anteriores. E
   "muito menor que qualquer diferença discutida" não era medido; virou a conta (0,09 %).
3. `formatC(big.mark = ".")` sem `decimal.mark` gera aviso no R; corrigido.
4. Heredoc do bash comeu as barras de uma expressão regular num teste (armadilha já registrada);
   trocada por comparação de prefixo.
