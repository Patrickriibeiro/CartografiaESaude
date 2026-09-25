# ADR-0007 — Nomes reais dos campos do SIVEP-Gripe e chave de junção de 6 dígitos

- **Status:** aceito (registro retroativo, aberto na auditoria final, CS-027)
- **Data:** 2026-09-25
- **Nasce em:** CS-004 e CS-006 (implementados); registrado como ADR no CS-027, porque a
  trilha §2.2 exige que toda correção de erro factual do PDF passe por ADR e este era o
  único dos cinco erros sem decisão registrada

## Contexto

O PDF v1 diz que a seleção espacial usa a variável `CO_MUNIC_RES`, "código numérico oficial
do IBGE, composto por sete dígitos", e que a confirmação de influenza vem de um campo
`PCR_FLU`. Nenhum dos dois existe no SIVEP-Gripe. Implementar o PDF ao pé da letra falharia
na primeira linha: coluna inexistente, ou junção de 7 dígitos contra 6 devolvendo zero
municípios sem acusar erro.

## Fatos, conferidos no dicionário oficial e nos quatro bancos PARQUET (CS-004, CS-006)

| PDF v1 | Real | Onde está conferido |
|---|---|---|
| `CO_MUNIC_RES`, 7 dígitos | `CO_MUN_RES`, `Varchar2(6)`: **6 dígitos** (o IBGE tem 7; o sétimo é dígito verificador) | dicionário oficial, campo 24; bancos 2022–2025 |
| `PCR_FLU` | `POS_PCRFLU` (1-Sim/2-Não/9-Ignorado) + `TP_FLU_PCR` (1-A/2-B); por antígeno, `POS_AN_FLU` + `TP_FLU_AN` | dicionário oficial, campos 69 e 72 |
| *(antígeno sem campos)* | `AN_SARS2`, `AN_VSR`, `POS_AN_OUT`, `RES_AN` | dicionário oficial, campos 67 e 69 |
| `CO-DETEC` (dicionário) | `CO_DETEC` no PARQUET | bancos 2022–2025 |

Os 37 campos usados, com tipo e domínio, estão em `docs/dicionario-sivep.md`.

## Decisões

1. **Os nomes reais são a fonte de verdade**, e ficam em uma única constante,
   `COLUNAS_SIVEP` (`R/funcoes_sivep.R`); o preparo para se um deles faltar no banco.
2. **A chave de junção do projeto é `cod6`**, texto de 6 dígitos, em todas as tabelas:
   SIVEP (`CO_MUN_RES` como vem), população do IBGE (`substr(código, 1, 6)`) e malha
   (`substr(CD_MUN, 1, 6)`). A junção é testada por contagem: 92 linhas depois de juntar,
   e um teste confirma que, com 7 dígitos, **nenhum** município casaria.
3. `CO_MUN_RES` é lido e mantido **como texto**, nunca convertido para número, para não
   perder zeros à esquerda nem induzir junção numérica.

## Consequências

- O texto da proposta (v2, §3.3 e §3.5) e o relatório usam os nomes reais.
- Qualquer campo novo entra primeiro em `docs/dicionario-sivep.md`, depois em `COLUNAS_SIVEP`.
- Este ADR fecha a cobertura dos cinco erros factuais da trilha §2.1–2.5:
  §2.1 → ADR-0001 · **§2.2 → ADR-0007** · §2.3 → ADR-0003 · §2.4 → ADR-0001 · §2.5 → ADR-0005.
