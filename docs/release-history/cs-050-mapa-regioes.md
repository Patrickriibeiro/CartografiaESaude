# CS-050 — Mapa de referência das regiões de saúde

- **Data:** 2026-09-26
- **Modelo · esforço:** Opus · medium (acordado com o dono)
- **Origem:** pedido da analista: mapa com a malha regional para entender qual região engloba quais
  municípios, e por que dividir por região e não só por município

## Verificação com número

| Critério de aceite | Resultado |
|---|---|
| 1 mapa | `resultados/mapas/regioes_saude_referencia.png`: 92 municípios coloridos pela região, contorno regional, nome e número de municípios de cada região |
| Tabela de 9 linhas no relatório | região, nº de municípios, população 2022 e lista dos municípios; `resultados/tabelas/regioes_municipios.csv` |
| Exportação | `exportacao/regioes_de_saude_municipios.csv`, 92 linhas (município → região) |
| Parágrafo com citação | "por que também regiões" (Decreto nº 7.508/2011, art. 2º, I; SES-RJ) e "por que a análise principal continua municipal" (Metropolitana I com 9.705.577 hab. × Baía da Ilha Grande com 253.897; MAUP) |
| Testes | 695/695 expectativas em 22 arquivos, 0 falhas (eram 683); 12 novas em `test-regioes.R` |
| Pipeline do zero | 8 etapas em 171 s |

## Decisões

- **Cores:** 9 tons pastel (ColorBrewer Set3) em `PALETA_REGIOES`, junto das outras constantes de cor
  (CS-046). Com 9 categorias nenhuma paleta separa todos os pares sob daltonismo: a identidade vem
  também do nome escrito em cada região e da tabela (codificação secundária, regra da skill dataviz).
  Tons pastel não se confundem com as cores fortes dos vírus.
- **Posição do rótulo:** polo de inacessibilidade (centro do maior círculo inscrito na maior parte da
  região, `sf::st_inscribed_circle`). A sede populacional, usada nos mapas regionais de incidência,
  põe o rótulo da Serrana em Petrópolis, na borda com o Centro-Sul.
- **Citações conferidas:** texto do art. 2º, I, do Decreto nº 7.508/2011 (Câmara dos Deputados,
  Planalto); página de regionalização da SES-RJ (HTTP 200 em 2026-09-26).

## Erros do caminho

1. 1ª versão: rótulo na sede — "Serrana" parecia estar no Centro-Sul. 2ª: maior parte do polígono —
   Metropolitana II e Baixada Litorânea se tocaram e a Baía da Ilha Grande caiu sobre as ilhas.
   3ª: polo de inacessibilidade, os 9 rótulos dentro das suas regiões (conferido na imagem).
2. Escrevi a extração do centro do círculo de forma confusa; simplificada para o centroide do círculo.
3. O teste de números digitados pegou o "7.508" do nome do decreto; a referência passou a vir de
   uma variável do chunk.
