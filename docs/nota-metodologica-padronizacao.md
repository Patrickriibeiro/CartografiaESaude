# Nota metodológica — padronização por idade (CS-033, OE9)

*Documento vivo. Números lidos de `resultados/tabelas/` em 2026-09-25 (versão 14-09-2026 do banco de 2025).*

## 1. O problema que a padronização resolve

A taxa bruta de um município depende de quem mora nele. O VSR (vírus sincicial respiratório)
adoece sobretudo bebês; o SARS-CoV-2, sobretudo idosos. Um município com muitos bebês terá
taxa bruta de VSR alta mesmo que o risco de cada bebê seja igual ao do resto do estado. A taxa
**padronizada por idade** responde a outra pergunta: qual seria a taxa do município se ele
tivesse a estrutura etária do estado?

## 2. Método direto

Para cada município *m*, agente e ano:

```
incid_pad_100k(m) = 100 000 × Σ_a [ casos_a(m) / pop_a(m) ] × w_a
```

- *a* percorre as 11 faixas etárias: <1, 1-4, 5-9, 10-19, 20-29, 30-39, 40-49, 50-59, 60-69,
  70-79, 80+. As duas primeiras ficam separadas porque 74 % dos casos de VSR são de menores de
  1 ano e 20 % de 1 a 4 anos.
- `casos_a(m) / pop_a(m)` é a taxa específica da faixa no município.
- `w_a` é o peso da faixa na **população-padrão**: o Estado do Rio de Janeiro no Censo 2022
  (`resultados/tabelas/populacao_padrao.csv`; menores de 1 ano pesam 0,96 %; 80+ pesam 2,7 %).

Faixa com população zero e zero caso contribui zero; faixa com população zero e algum caso é
erro do pipeline (`padronizar_direto()` para).

## 3. Os dados

| Peça | Fonte | Observação |
|---|---|---|
| Idade do caso | SIVEP-Gripe, `NU_IDADE_N` + `TP_IDADE` | `TP_IDADE` 1 = dias, 2 = meses, 3 = anos; sem ele, "6" pode ser 6 dias ou 6 anos. Os 37.562 casos têm idade; máximo 115 anos |
| População por faixa | IBGE, Censo 2022, SIDRA tabela 9514 | sexo Total, forma de declaração Total; 21 grupos quinquenais + "Menos de 1 ano"; 1-4 = "0 a 4" − "Menos de 1". "-" no SIDRA é zero (3 municípios em "100 anos ou mais") |
| População dos outros anos | proporção de 2022 × população do ano (ADR-0003) | o IBGE não publica estrutura etária municipal fora do Censo |

**Contrato testado no pipeline:** a soma das faixas é exatamente a população do ano, então a taxa
bruta recalculada das faixas é idêntica, linha a linha, à `incid_100k` do estudo.

## 4. O que a padronização mudou

| Agente | Correlação de postos bruta × padronizada | Razão mediana padronizada / bruta | Razão mínima · máxima |
|---|---|---|---|
| SARS-CoV-2 | 0,989 a 0,994 | 1,00 a 1,01 | 0,71 · 1,49 |
| Influenza | 0,990 a 0,999 | 0,97 a 1,00 | 0,77 · 1,84 |
| VSR | 0,995 a 0,999 | 0,93 a 0,95 | 0,61 · 1,38 |

Leitura: a ordem dos municípios quase não muda, e a escala muda pouco, exceto em municípios
isolados com poucos casos. No VSR a mediana fica abaixo de 1: a maioria dos municípios tem, em
proporção, mais crianças pequenas que a população-padrão, dominada pela capital, então a taxa
bruta os superestima um pouco.

## 5. O que a padronização NÃO faz

- Não corrige testagem nem acesso (ver §5.3 do relatório e o CS-041): um município que testa
  pouco continua com taxa baixa depois de padronizar.
- Não estabiliza contagens pequenas: isso é papel da suavização por Bayes empírico
  (`docs/nota-metodologica-suavizacao.md`). Por isso a análise espacial (Moran, LISA) segue
  sobre a taxa suavizada, e a padronizada é descritiva.
- Não capta mudança na estrutura etária entre 2022 e 2025.

## 6. Onde está

- Código: `R/funcoes_padronizacao.R`; etapa `02_indicadores.R`.
- Coluna `incid_pad_100k` em `dados/processados/indicadores_municipais.parquet` e
  `taxa_padronizada_idade_100mil` em `resultados/tabelas/exportacao/indicadores_municipais.csv`.
- Tabelas: `resultados/tabelas/padronizacao_idade.csv`, `perfil_etario.csv`, `populacao_padrao.csv`.
- Gráfico: `resultados/estatistica/padronizacao_bruta_vs_padronizada.png`.
- Testes: `tests/testthat/test-padronizacao.R` (conta à mão: dois municípios com as mesmas taxas
  por idade e estruturas etárias opostas recebem a mesma taxa padronizada).
