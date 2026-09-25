# CS-007 — ADR-0002: critério de caso por agente e co-detecção

- **Data:** 2026-09-25
- **Modelo · esforço:** Fable 5.1 · high (acordado com o dono)
- **Itens:** CS-007 · ADR-0002 (**proposto**; o aceite é a D-04, da autora)

## Verificação com número

| Critério de aceite | Resultado |
|---|---|
| Tabela comparativa "3 regras × 4 anos" | **5 regras × 3 agentes × 4 anos**, em `resultados/tabelas/comparacao_regras_caso.csv`, gerada pelo `01_etl_sivep.R` |
| ADR aceito pelo dono | **Não cabe a mim:** ADR escrito e proposto; 3 perguntas objetivas na §8 para a D-04 |
| Suíte completa | **180/180 expectativas em 54 testes, 6 arquivos**, 0 falhas |
| Regras em código com teste de resposta conhecida | `REGRAS_CASO` (5 regras) + 6 testes em `test-criterio-caso.R` sobre 12 fichas fabricadas |
| Fichas analisadas | 99.880 (RJ, 2022–2025, versões do manifesto) |
| Intermediário | 37 colunas (34 + 3 de sorologia) |

## O achado que muda a recomendação

A leitura literal do PDF ("`CLASSI_FIN` do agente + RT-PCR ou antígeno positivo para o
vírus") exige o *checkbox* "qual vírus" marcado. Esse checkbox fica em branco em fichas
que têm resultado positivo e foram encerradas como COVID, e a frequência disso muda no
tempo:

| Ano | Encerradas como COVID | Sem checkbox | Das quais com resultado positivo/sorologia |
|---|---|---|---|
| 2022 | 18.647 | 5.096 (27,3 %) | 2.327 |
| 2023 | 4.123 | 872 (21,1 %) | 544 |
| 2024 | 2.307 | 281 (12,2 %) | 205 |
| 2025 | 1.098 | 60 (5,5 %) | 26 |

A regra literal fabricaria uma queda extra de COVID entre 2022 e 2025. A recomendação
passou a ser a regra **R2 vigilância**: `CLASSI_FIN` do agente **e** (critério de
encerramento laboratorial declarado **ou** checkbox). Ela exclui os 1.509 encerramentos
clínicos de 2022 (critério que deixou de valer em 31/10/2022) e não depende da
completude do checkbox.

Totais por regra (4 anos): SARS-CoV-2 19.866 (R1) · 24.087 (R2) · 26.175 (R4);
Influenza 5.231 · 5.536 · 5.675; VSR 7.939 em todas as regras ancoradas na classificação.

## Outros achados

- **Co-detecção entre os 3 agentes é rara:** 305 fichas (0,3 %). Nas regras ancoradas
  no `CLASSI_FIN`, cada ficha tem um agente; a co-detecção é reportada, não contada duas
  vezes. Isso **inverte** a recomendação inicial da D-04.
- **`CO_DETEC` não serve nem de conferência:** marca co-detecção com qualquer vírus e
  está vazio em 65 % das fichas; das 305, só 76 têm `CO_DETEC = 1`.
- **Maturação não é o problema deste snapshot:** fichas não encerradas por ano são
  1.028 · 481 · 760 · 138. A proposta v2 §3.10 supunha o contrário; corrigir no CS-037.
- **Cobertura de testagem com resultado:** 87,5 % → 91,7 % entre 2022 e 2025.
- **Internação:** 1.023 fichas "não internado" (1,0 %) e 2.161 sem informação (2,2 %).
  Recomendação: contar toda ficha do banco e dizer "SRAG notificada".

## Decisões de implementação

- As 5 regras são **código do projeto**, não texto do ADR: a tabela da decisão sai do
  pipeline e o CS-008 aplicará a mesma função. Se a autora escolher outra regra, muda-se
  um nome.
- 3 colunas de sorologia (`RES_IGG`, `RES_IGM`, `RES_IGA`) entraram no intermediário só
  para medir a regra R3. A recomendada não as usa.
- `diagnosticar_sivep()` ganhou cobertura de testagem e internação, porque o ADR cita
  esses números e todo número do ADR vem de um artefato.

## Erros do caminho

1. **Regra escrita antes de olhar o dado.** A D-04 nasceu na análise inicial com
   "estrita, co-detecção em cada agente". Bastou cruzar `CLASSI_FIN` com os campos de
   laboratório para ver que a regra estrita mede preenchimento. A lição já está
   registrada no Compasso: recomendação sem número é opinião.
2. **O shell recusou duas vezes o comando longo** de edição (aspas). Refeito como
   arquivo `.py` executado pelo `python`, que é a regra da memória do projeto. Nenhum
   arquivo foi corrompido nas tentativas.
3. A primeira contagem de expectativas subiu para 177 e depois 180 porque o teste do
   diagnóstico ganhou 3 expectativas ao cobrir as colunas novas.
