# ADR-0006 — Malha municipal oficial do IBGE em resolução completa, não a simplificada do geobr

- **Status:** aceito
- **Data:** 2026-09-25
- **Nasce em:** CS-014 · desvia do PDF v1 §3.3 ("malhas ... por meio do pacote geobr")

## Contexto

O PDF pede a malha municipal pelo `geobr`. A função `read_municipality()` usa por
padrão `simplified = TRUE`, que baixa a malha nacional simplificada (20,6 MB) do
release v2.0.0 do Ipea. A versão completa nacional tem 269 MB.

A matriz de vizinhança Queen do CS-016 considera vizinhos os municípios que
compartilham qualquer ponto de fronteira. Simplificar polígonos move vértices, e pode
abrir frestas ou desfazer toques.

## Evidência

Comparação em 2026-09-25 entre a malha simplificada do `geobr` e a malha oficial do
IBGE em resolução completa (`RJ_Municipios_2022.zip`, 5,3 MB, só o RJ):

| | Simplificada (geobr) | Oficial IBGE |
|---|---|---|
| Municípios | 92 | 92 |
| Ligações de vizinhança Queen | **440** | **456** |
| Componentes conexos | 1 | 1 |
| Área total | 43.860,6 km² | 43.750,4 km² |

A simplificada perde **8 pares de vizinhos** (16 ligações), afetando 15 municípios.
Exemplos: Rio de Janeiro–Seropédica, Mesquita–São João de Meriti, Campos dos
Goytacazes–Itaperuna, Petrópolis–Três Rios, Barra Mansa–Piraí. A leitura direta do
PARQUET do `geobr` reproduz 92/92 geometrias do `read_municipality()`, então a
diferença é da simplificação, não da leitura.

Detalhe secundário: o `geobr` 2.1.0 baixa com `ssl_verifypeer = 0`, ou seja, sem
verificar o certificado do servidor. O `baixar_arquivo()` do projeto verifica.

## Decisão

Usar a **malha oficial do IBGE, municípios do RJ, 2022, resolução completa**, baixada
de `geoftp.ibge.gov.br`, registrada no manifesto e lida direto do zip. Já vem em SIRGAS
2000 (EPSG:4674).

## Alternativas descartadas

- **`geobr` simplificado:** muda a estrutura de vizinhança, e portanto o Moran e o
  LISA, sem nenhum erro visível.
- **`geobr` completo (`simplified = FALSE`):** mesma geometria do IBGE, mas 269 MB
  nacionais para usar 92 polígonos.

## Consequências

- O PDF §3.3 e a proposta v2 §3.2/§3.5 citam o `geobr` para a malha municipal; o texto
  precisa mudar (CS-037). O `geobr` continua útil para a tabela de regiões de saúde
  (CS-030), usada só como atributo, dissolvendo a malha do IBGE.
- O CS-016 tem uma verificação cruzada: a vizinhança Queen sobre a malha do projeto
  deve ter 456 ligações.
- Atende melhor ao próprio argumento do PDF, de conformidade com a INDE: a fonte é o
  produtor oficial.
