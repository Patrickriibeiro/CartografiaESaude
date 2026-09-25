# CS-013 — Suavização empírica de Bayes

- **Data:** 2026-09-25
- **Modelo · esforço:** Opus · medium (acordado com o dono)
- **Itens:** CS-013 · aplica a D-09 (LISA sobre a taxa suavizada)

## Verificação com número

| Critério de aceite | Resultado |
|---|---|
| Suíte completa | **263/263 expectativas em 81 testes, 9 arquivos**, 0 falhas |
| Coluna preenchida 92 × 12 | `incid_eb_100k` em 1.104/1.104 linhas, 0 NA |
| Gráfico de dispersão bruta × suavizada | `resultados/estatistica/ebayes_bruta_vs_suavizada.png` (12 painéis) |
| Nota metodológica | `docs/nota-metodologica-suavizacao.md`, pronta para o relatório |
| Conferência independente | igual à fórmula de Marshall (1991) escrita à mão no teste |
| Propriedade de encolhimento | nos dados reais, 1.104/1.104 taxas ficam entre a bruta e a média do estado |
| Mutação: desligar a guarda do 0/0 | o teste de "agente × ano sem caso" quebra |

## Achado para o CS-017

A suavização reordena pouco onde há muitos casos (SARS-CoV-2 2022: correlação de postos
0,99) e muito onde há poucos (VSR 2022: 0,40; VSR 2024: 0,62; influenza 2022: 0,78).
O LISA sobre a bruta e sobre a suavizada pode discordar justamente nesses anos.
Registrado como evidência no CS-017 (ADR-0004).

## Decisões de implementação

- **Bayes empírico global** (média do estado), não local (média dos vizinhos): o local
  usaria a mesma vizinhança que o LISA testa depois, o que tende a inflar a
  autocorrelação. Registrado na nota metodológica.
- **População do ano** como denominador, a mesma do mapa e do LISA (ADR-0003).
- **Guarda para agente × ano sem nenhum caso:** taxa suavizada 0, em vez do `NaN` que o
  `spdep` devolveria (0/0). Não ocorre nos dados reais; a guarda protege recortes futuros.
- Os parâmetros *a* e *b* de cada agente × ano ficam como atributo e vão para a tabela
  de resumo.

## Erros do caminho

Nenhum na implementação (263/263 na primeira execução; por isso a mutação). O subtítulo
do gráfico foi corrigido depois de olhar a imagem: descrevia só os pontos puxados para
baixo, e os municípios sem caso são puxados para cima.
