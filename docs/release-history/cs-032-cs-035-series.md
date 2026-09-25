# CS-032 + CS-035 — Série por semana epidemiológica e fichas não encerradas

- **Data:** 2026-09-25
- **Modelo · esforço:** Opus · low (acordado com o dono)
- **Origem:** proposta v2 §3.3, §3.10 item 2, §4.2, §5.1; D-08

## Verificação com número

| Critério de aceite | Resultado |
|---|---|
| CS-032: 1 gráfico estadual + 9 regionais | 10 PNG `serie_semanal_*.png` + 1 painel 3 × 3 para o relatório |
| CS-032: semanas do Ministério (domingo a sábado) | 209 semanas (52, 52, 52, 53), de 02/01/2022 a 03/01/2026; semana de `DT_SIN_PRI`, nunca `SEM_PRI` |
| CS-032: marcas das campanhas | 4 datas nacionais em `config/fontes.yml`, cada uma com URL de fonte oficial |
| CS-032: conservação | estado = soma das regiões = 37.562 casos; tabela 6.270 linhas (10 recortes × 3 agentes × 209) |
| CS-035: tabela 4 linhas | 1.028 · 481 · 760 · 138 fichas não encerradas (2,7 % · 2,4 % · 4,2 % · 0,6 %), idênticas à coluna do diagnóstico do SIVEP |
| CS-035: gráfico 2025 | `nao_encerrados_2025.png`, 53 semanas |
| Exportação | `serie_semanal.csv` e `nao_encerrados.csv` (10 arquivos na pasta) |
| Testes | 575/575 expectativas em 18 arquivos, 0 falhas, 0 pulados (eram 547 em 17) |
| Pipeline do zero | 8 etapas em 125 s |
| Reprodutibilidade | 2ª execução do zero: 97 de 98 arquivos idênticos byte a byte; difere só o LEIA-ME |
| Relatório | seção "Série por semana epidemiológica" com 2 tabelas e 3 figuras; 0 números digitados |

## Datas das campanhas (início nacional, regiões Sudeste, Sul, Nordeste e Centro-Oeste)

| Ano | Início | Fonte |
|---|---|---|
| 2022 | 04/04 | notícia do Ministério da Saúde de 04/04/2022 |
| 2023 | 10/04 | BVS/MS: campanha de 10/4 a 31/5/2023 |
| 2024 | 25/03 | notícia do Ministério da Saúde de 25/03/2024 (campanha antecipada) |
| 2025 | 07/04 | Prefeitura do Rio: "desde o dia 7 de abril, quando começou a campanha nacional" |

Em 2025 o RJ antecipou a campanha estadual para o fim de março; o gráfico marca a data
nacional e o relatório diz isso.

## Achados

- **O banco de 2025 já amadureceu.** O BACKLOG esperava uma "curva de maturação" (não encerradas
  subindo nas últimas semanas). Os dados dizem outra coisa: 2025 tem a MENOR proporção dos 4
  anos (0,6 %); nas últimas 8 semanas a proporção agregada é 0,9 %, contra 0,6 % nas anteriores.
  A versão do banco é de 14/09/2026, nove meses depois do fim do ano.
- **Pico de influenza de 2022 antes da campanha.** A semana de mais casos é a 1 (111 casos), 13
  semanas antes da campanha: a série começa em alta, com a epidemia que vinha de 2021. Nos
  outros anos o pico vem 2 a 5 semanas depois do início da campanha. O relatório diz que isso
  é descritivo, não efeito da vacina.
- **Maior pico do período:** SARS-CoV-2, semana 3 de 2022, 2.265 casos.

## Erros do caminho

1. O primeiro subtítulo do gráfico de não encerradas afirmava "a linha sobe nas semanas mais
   recentes", e o comentário da função falava em "perda que cresce nos anos recentes". Os dois
   foram escritos a partir da expectativa do BACKLOG, antes de ver o dado, e eram falsos.
   Agora o texto descreve o gráfico, e a frase interpretativa do relatório depende de uma conta
   (últimas 8 semanas × anteriores).
2. Na tabela do pico de influenza, a coluna "semanas após a campanha" tinha valor negativo em
   2022; o título virou "da campanha ao pico (negativo = antes)" e o texto trata o caso.
3. Ao corrigir a proposta, escrevi que a semana 53/2025 terminava em 02/01/2026; termina no
   sábado 03/01/2026. Conferido com `weekdays()` antes do commit.
4. A proposta dizia que a série usaria `SEM_PRI` e que o período começava em 01/01/2022 (que é
   da semana 52 de 2021). Corrigido para a semana recalculada e 02/01/2022.
