# CS-058 — Influenza em amarelo

- **Data:** 2026-09-26
- **Modelo · esforço:** Opus · low (acordado com o dono)
- **Origem:** pedido da analista: cores da influenza, antes rosa, passam para amarelo.

## Verificação com número

| Critério de aceite | Resultado |
|---|---|
| Influenza amarela | `CORES_AGENTE["influenza"]` = `#eda100` (posição 4 da paleta categórica validada, o amarelo-âmbar que foi do SARS-CoV-2 até o CS-054); rampa `#fdf6e3` → `#eda100` → `#5c3a00`; teste novo: matiz HCL da influenza entre 40° e 100° (é 48,6°) e nenhum outro vírus nessa faixa |
| Distinção entre vírus | validador da skill dataviz, todos os pares: pior par amarelo × verde ΔE 16,2 sob protanopia (meta ≥ 8; era 13,0 com o rosa) e azul × verde 29,0 em visão normal (piso 15; era 27,5) |
| Pipeline | `run.R --limpar`: 8 etapas em 228 s; 45 mapas |
| Testes | 797/797 expectativas em 23 arquivos, 0 falhas, 0 pulados (eram 795) |

## Decisões

- **Reaproveitar o âmbar já validado** em vez de um amarelo puro: um amarelo mais claro teria
  contraste ainda menor no branco (o âmbar já tem 2,1:1, abaixo de 3:1; compensado por linhas
  grossas, legenda e tabela).
- Para quem tem daltonismo vermelho-verde, o amarelo fica perto do salmão do Alto-Alto indicativo do LISA (ΔE 6,7 em
  deuteranopia); aceitável porque cor de vírus nunca aparece em mapa de LISA.

## Erros do caminho

1. A faixa do teste começou em 60°–100° (chute para "amarelo"); o âmbar fica em 48,6° em HCL e o
   teste falhou. A faixa foi corrigida para 40°–100°, com a cor medida anotada no teste.
