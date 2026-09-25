# CS-028 — Seções vazias do PDF: Introdução (1.1, 1.2) e Conclusão (6)

- **Data:** 2026-09-25
- **Modelo · esforço:** Fable · medium (acordado com o dono)
- **Origem:** o PDF da proposta lista 1.1, 1.2, 6 e Apêndice A sem conteúdo; a trilha §1 registra que
  o código é insumo do texto científico, então essas seções só podiam ser escritas por último

## Verificação com número

| Critério de aceite | Resultado |
|---|---|
| Rascunho entregue à mestranda | seções "Introdução" (Contextualização, Problematização) e "Conclusão" em `08_relatorio.qmd`, com **todos os números calculados** pelo pipeline; a proposta v2 §1.1 perde o `[REVISAR]` e §6 resume a conclusão |
| Conclusão responde à pergunta (§1.4) e às hipóteses (§1.3) uma a uma | H1, H2, H3, H4 e "o que não pôde ser testado", cada uma com o número que a sustenta ou não |
| Citações verificadas na fonte | 4 referências novas, todas conferidas em 2026-09-25: Bastos et al. 2020 (Cad. Saúde Pública 36(4):e00070120), Niquini et al. 2020 (Cad. Saúde Pública 36(7):e00149420), Li et al. 2022 (Lancet 399(10340):2047–2064), Boletim InfoGripe SE 45/2025 (Fiocruz). O teste "toda citação existe no .bib" passa |
| Números digitados no texto | 0 (teste `test-relatorio.R`); idades e limiares escritos por extenso ou lidos de variáveis |
| Testes | 661/661 expectativas em 21 arquivos, 0 falhas (eram 657) |
| Renderização | HTML e revealjs sem aviso; 0 citações não resolvidas |

## O que a conclusão diz (versão 14/09/2026 do banco de 2025)

- **H1 sustentada, sinal fraco:** Moran global significativo em 6 de 12 mapas (SARS-CoV-2 em 2
  anos, influenza em 3, VSR em 1), I de 0,11 a 0,33; 0 de 12 na escala regional.
- **H2 só para o VSR:** único agrupamento Alto-Alto confirmado é VSR 2024 (Itaboraí, Maricá,
  Tanguá; Metropolitana II). Influenza e SARS-CoV-2: nenhum. A padronização por idade não muda a
  ordem (postos 0,989–0,999).
- **H3 na série, não nos mapas:** SARS-CoV-2 15,3 vezes menor em 2025 que em 2022; influenza 7,2 e
  VSR 3,3 vezes maiores. Com um só mapa confirmado, não há como dizer se os agrupamentos se
  deslocam; no nível indicativo, 2 de 6 (SARS-CoV-2), 0 de 10 (influenza) e 4 de 10 (VSR)
  municípios Alto-Alto repetem em mais de um ano.
- **H4 descritiva:** rho de Spearman 0,33–0,40 com leitos de UTI SUS, intervalos acima de zero
  nos 4 anos; fraca com o total de leitos. Sem leitura causal.
- **Não testável:** ausência de doença × ausência de testagem (CS-041).

## Decisões de escopo

- **Apêndice A não foi redigido.** A proposta v2 o define como "avaliação crítica da disciplina,
  texto pessoal da autora". Não é texto científico derivado dos resultados, e só ela pode
  escrevê-lo. Registrado na proposta v2.
- **A introdução usa os números do próprio pipeline** (proporção de cada agente entre os
  confirmados: SARS-CoV-2 de 91 % para 14 %, influenza de 2 % para 36 %, VSR de 6 % para 50 %) no
  lugar de transcrever percentuais do InfoGripe, como a v2 pedia com `[REVISAR]`. O InfoGripe é
  citado como o boletim nacional que agrega por UF, que é o ponto da problematização.
- **Rascunho, não versão final:** o texto está na voz do relatório, para a autora editar. As
  frases interpretativas dependem de contas, então uma versão nova do banco as reescreve.

## Erros do caminho

1. `mapas_conf` saiu como "vsr 2024" (rótulo interno); passou por `rot()` e "em".
2. "em 2 ano(s)" e "caiu 15,3 vezes" (não idiomático): singular/plural calculado e "foi X vezes
   menor que".
3. A frase sobre 2020 dizia "substituição da influenza pelo SARS-CoV-2", mais do que os dois
   artigos mostram; passou a "explosão das hospitalizações por SRAG com a chegada do SARS-CoV-2 e
   comparação com as da influenza".
4. O PDF não pôde ser lido nesta máquina (sem poppler nem pypdf); a estrutura das seções veio da
   trilha §1 e da proposta v2, que já a transcrevem.
