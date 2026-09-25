# CS-037 + CS-038 — Proposta v2 atualizada e método do IBGE citado

- **Data:** 2026-09-25
- **Modelo · esforço:** Opus · low (acordado com o dono)
- **Itens:** CS-037, CS-038 · só documentação, nenhum código alterado

## Verificação com número

| Critério de aceite | Resultado |
|---|---|
| CS-037: seções da v2 corrigidas, cada uma citando o ADR | **6 trechos + referências:** §2.2 OE4 (ADR-0006), §3.2 fontes (ADR-0003, ADR-0006), §3.3 critério e co-detecção (ADR-0002), §3.4 denominador (ADR-0003), §3.5 malha (ADR-0006), §3.10 limitações 2, 6 e 7; item 13 no sumário de mudanças |
| CS-038: nota do IBGE citada com URL e página | *Estimativas da População 2024, Nota metodológica n. 01*, p. 6–7, liv102112.pdf; citada no ADR-0003 e na proposta v2 |
| Menções ao `geobr` na v2 | 6, todas corretas: tabela de regiões de saúde, explicação do descarte, referência e apêndice |

## O que a nota do IBGE disse

As estimativas municipais de 2024 partem das populações do Censo 2022 **ajustadas** para
somar as Projeções da População (Revisão 2024). O ajuste de cada UF é distribuído entre
os municípios pela Taxa de Erro Líquido de Enumeração da Pesquisa de Pós-Enumeração
(PPE) 2022, em 9 classes de tamanho, e é maior nos municípios grandes. Isso explica o
padrão medido no CS-011 (Rio de Janeiro +8,4 %, Cambuci +3,1 %). A população ajustada de
2022 por município não é publicada na nota, então a opção C do ADR-0003 (fator estadual
único) é uma aproximação que subcorrige os grandes e sobrecorrige os pequenos.

## O que NÃO foi feito, de propósito

- **D-04 e D-05 continuam abertas.** A v2 traz a recomendação de cada ADR marcada
  `[REVISAR: ... pendente]`, não a decisão.
- **CS-036** (ano epidemiológico na §3.1) não entrou: é outro item.
- A nota do IBGE não foi baixada para o manifesto: é referência bibliográfica, não
  dado de entrada do pipeline.

## Erros do caminho

Nenhum.
