# CS-054, CS-055, CS-056 — SARS-CoV-2 em azul, contorno do estado, painéis por vírus

- **Data:** 2026-09-26
- **Modelo · esforço:** Opus · medium (acordado com o dono)
- **Origem:** pedidos da analista, recebidos em 2026-09-26 depois do pacote de resultados do mesmo dia:
  cor do SARS-CoV-2 "anteriormente rosa" para azul; contorno cinza-escuro em volta do estado;
  painéis de mapas organizados por agente (um painel por vírus, com todos os anos).

## Verificação com número

| Critério de aceite | Resultado |
|---|---|
| SARS-CoV-2 azul | `CORES_AGENTE["sarscov2"]` = `#2a78d6` (posição 1 da paleta categórica validada); rampa `#eef4fc` → `#2a78d6` → `#0b2e5a`, claridade Lab 95,6 → 18,7 estritamente decrescente; teste novo: matiz HCL do SARS-CoV-2 entre 220° e 270° e nenhum outro vírus nesse intervalo |
| Distinção entre vírus | validador da skill dataviz, todos os pares: pior par azul × magenta ΔE 13,0 sob protanopia (meta ≥ 8; era 16,2) e 27,5 em visão normal (piso 15; era 19,6) |
| Contorno do estado | `COR_CONTORNO_ESTADO` `#333333`, 0,5 nos mapas isolados, 0,25 nos painéis 3 × 4, 0,35 nos 2 × 2, 0,7 no mapa de referência das regiões; presente nos 45 mapas; testes conferem a camada nos mapas de incidência, LISA, regional e de referência |
| União sem fresta | malha real: 577 partes (continente e ilhas), 0 buracos; união plana em UTM 23S 1,3 s contra 6,4 s na esférica; teste: 16 quadrados colados → 1 polígono, mesma área |
| Painéis por vírus | 6 arquivos novos, `painel_incidencia_<vírus>.png` e `painel_lisa_<vírus>.png`, 4 anos em 2 × 2, 300 dpi; incidência na mesma escala dos 4 anos (raiz quadrada); LISA com o nº de confirmados no título de cada ano (VSR 2024: 5, igual ao mapa isolado) |
| Mapas gerados | 45 (eram 39), contados pela própria etapa 06 |
| Pipeline | `run.R --limpar`: 8 etapas em 235 s |
| Testes | 795/795 expectativas em 23 arquivos, 0 falhas, 0 pulados (eram 757; inclui o CS-057) |

## Decisões

- **Qual vírus fica azul.** A analista escreveu "SARS-CoV-2, anteriormente rosa", mas no pacote o
  SARS-CoV-2 era amarelo e a influenza é que era rosa. O dono decidiu: vale o nome do vírus
  (citado duas vezes), não a cor lembrada. Influenza segue rosa, VSR segue verde.
- **Concessão registrada: azul do SARS-CoV-2 × azul do Baixo-Baixo do LISA.** Ficam quase iguais
  (ΔE 7,8). Mantive o LISA na convenção do GeoDa (vermelho = Alto-Alto, azul = Baixo-Baixo), que
  quem lê estatística espacial reconhece, porque os dois azuis nunca dividem uma figura: mapa de
  LISA não usa cor de vírus. O guia de cores e o parágrafo do relatório agora dizem isso. Se a
  analista preferir, a saída é trocar o Baixo-Baixo, não o vírus. Isso reabre em parte a regra do
  CS-046 ("nenhuma cor de vírus reaparece com outro significado"): a cor exata não reaparece (o
  teste continua valendo), o matiz sim.
- **Contorno calculado uma vez** na etapa 06 e passado a todos os mapas (parâmetro `contorno`);
  as funções calculam sozinhas se ninguém passar, para os testes e usos avulsos.
- **Painéis 2 × 2** (não 1 × 4): cabem numa página A4 em retrato. O painel 3 × 4 continua no
  relatório como visão de conjunto; os por vírus são arquivos para a dissertação.

## O que não mudou, de propósito

- Paleta do LISA e das regiões; influenza e VSR.
- O mapa interativo do `app.R` (leaflet): não ganhou contorno; o mapa de fundo já traz o limite
  estadual.
- O relatório não inclui os 6 painéis novos (seriam 6 figuras de página inteira repetindo o 3 × 4).

## Erros do caminho

1. O subtítulo do guia de cores, mais longo, saiu cortado na borda da figura: quebrado em duas linhas.
2. Nos painéis 2 × 2, o subtítulo encostava no título do primeiro ano: margem inferior de 12 pt.
3. Script Python passado por heredoc do bash não casou "Litorânea" num arquivo de teste; a
   edição foi refeita pela ferramenta de edição.
