# CS-021 — Painel Shiny + leaflet

- **Data:** 2026-09-25
- **Modelo · esforço:** Opus · medium (acordado com o dono)

## Verificação com número

| Critério de aceite | Resultado |
|---|---|
| 12 combinações filtram sem erro | `shiny::testServer` percorre 12 agente × ano × 2 camadas = 24 estados; em todos, 92 municípios e popup sem NA (109 expectativas no arquivo) |
| Popup com 6 campos | município, casos, população, taxa bruta, taxa suavizada, classe LISA (+ aviso de instável); HTML do nome escapado |
| Inicia em < 5 s | app 1,5 s + dados 0,5 s |
| 3 estados | carregando: `useBusyIndicators()`; vazio: `validate(need(...))`; erro: pipeline não rodado → mensagem dizendo o que falta (testado) |
| Só lê `dados/processados` e `resultados/` | `ARQUIVOS_PAINEL` lista os 3 arquivos |

## O que o painel faz

Barra lateral com agente, ano epidemiológico e camada (incidência suavizada ou Moran
local), nota metodológica e um resumo (casos no estado, confirmados, indicativos). Mapa
leaflet com fundo CartoDB Positron, cores idênticas às dos mapas estáticos (quintis *magma*;
paleta LISA de 9 categorias), borda tracejada nos 3 municípios de um vizinho.

## Decisões

- **Malha simplificada só para o desenho** (100 m em UTM, `preserveTopology = TRUE`,
  19.157 vértices): a malha completa pesaria no navegador. Nenhum cálculo usa a versão
  simplificada; a vizinhança do LISA continua a da malha completa (ADR-0006).
- **Instável marcado por borda tracejada**, porque o leaflet não hachura.
- Funções do painel em `R/funcoes_mapas.R`, testáveis sem subir o servidor; o `app.R` só
  monta a interface.

## Limitação da verificação

O painel **não foi aberto no navegador embutido**: a execução do servidor pelo painel de
visualização foi negada pelo classificador de permissões desta sessão. A verificação foi
feita por `testServer` (lógica e saídas do servidor, 24 estados), pelo tempo de carga e pela
exportação do mapa do VSR 2024 como widget HTML (1,1 MB). A inspeção visual do painel rodando
fica para o dono (`shiny::runApp()` na raiz do projeto).

## Erros do caminho

1. Exportar o widget exigiu o `pandoc`; usado o que vem com o Quarto (`RSTUDIO_PANDOC`).
2. O heredoc do shell comeu uma barra invertida de novo, num script de medição: refeito com
   a ferramenta de escrita (regra já registrada na memória do projeto).
3. A entrada temporária no `launch.json` do Compasso foi revertida logo após a negativa; o
   repositório do Compasso ficou limpo.
