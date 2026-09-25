# CS-019 — Mapas de incidência e de LISA

- **Data:** 2026-09-25
- **Modelo · esforço:** Opus · medium (acordado com o dono)
- **Itens:** CS-019 · aplica o ADR-0004 (dois níveis, instáveis)

## Verificação com número

| Critério de aceite | Resultado |
|---|---|
| Suíte completa | **337/337 expectativas em 102 testes, 11 arquivos**, 0 falhas |
| 12 mapas de incidência + 12 LISA, 300 dpi | 24 em `resultados/mapas/`, mais 2 painéis 3 × 4 para o relatório |
| Sem texto sobreposto (inspeção visual registrada) | conferidos o LISA do VSR 2024, o de incidência do SARS-CoV-2 2022 e os dois painéis; ver "Inspeção" abaixo |
| Tempo do script | ~45 s para os 26 PNG |
| Mutação: tirar a reconstrução do sf em `dados_mapa()` | o teste certo quebra |

## O que os mapas mostram

- **Incidência:** classes por quintil do próprio mapa (5 cores), paleta *magma*, taxa
  suavizada. As cores não são comparáveis entre anos; para comparar, o painel de
  incidência usa escala comum aos 4 anos de cada agente (raiz quadrada).
- **LISA:** 9 categorias fixas na legenda (4 quadrantes × 2 níveis + não significativo),
  cor cheia para confirmado após FDR, cor clara para indicativo, hachura nos 3
  municípios de um vizinho; os confirmados são nomeados no subtítulo e rotulados no mapa.

## Inspeção visual (o que foi visto e corrigido)

1. **Tanguá sumiu do mapa do VSR 2024.** O rótulo colidia com o de Itaboraí e a opção
   `check_overlap = TRUE` descarta o que colide. Corrigido: rótulos sem descarte, fonte
   menor, e todos os confirmados listados no subtítulo. Os rótulos de Itaboraí e Tanguá
   ainda se tocam no mapa; a lista do subtítulo garante a leitura.
2. **Legenda com categorias sem cor.** No `ggplot2` 4.0.3 a camada só desenha a chave
   das categorias presentes nos seus dados; `drop = FALSE` e `override.aes` não
   bastaram. Corrigido com `show.legend = TRUE` na camada de preenchimento (testado
   isoladamente antes).
3. **Subtítulo cortado** quando a lista de confirmados é longa. Corrigido com quebra de
   linha em 105 caracteres.

## Decisões de implementação

- **Hachura com `sf`**, recortando linhas diagonais pelo contorno dos instáveis, porque
  o `ggplot2` não hachura e o `ggpattern` não está no ambiente.
- **Ponto do rótulo** calculado em SIRGAS 2000 / UTM 23S (metros) e devolvido ao
  sistema original: em graus, o `sf` avisa que o ponto interno pode sair errado.
- **Roxo e verde para os discrepantes** (Alto-Baixo, Baixo-Alto), para não se confundirem
  com o vermelho e o azul dos agrupamentos.
- Os PNG ficam em `resultados/mapas/`, fora do git (regeneráveis em 45 s).

## Erros do caminho

1. `merge()` sobre um objeto `sf` devolveu `data.frame` comum: o método de junção do
   `sf` só é usado quando o pacote está anexado com `library()`, e o projeto usa `sf::`.
   Corrigido com `st_as_sf()` explícito e um teste.
2. Os dois defeitos visuais acima (rótulo descartado, legenda sem cor) passaram por
   todos os testes automáticos e só apareceram olhando a imagem.
3. Um script de edição em Python parou por um espaço no fim de linha no padrão de busca;
   nada foi gravado pela metade (a checagem `assert` vem antes da escrita).
