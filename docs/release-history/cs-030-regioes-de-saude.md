# CS-030 — Escala de região de saúde

- **Data:** 2026-09-25
- **Modelo · esforço:** Opus · medium (acordado com o dono)
- **Origem:** proposta v2 §3.4; D-10 (autora pôs a escala regional no escopo)

## Verificação com número

| Critério de aceite | Resultado |
|---|---|
| 9 feições | 9 regiões, 3 a 16 municípios cada, 92 no total; geometria válida |
| Tabela 9 × 3 × 4 | 108 linhas; soma dos casos = 37.562, igual à grade municipal |
| 12 mapas regionais | 12 PNG em `resultados/mapas/regional_<agente>_<ano>.png`; total da etapa 06 = 38 |
| Vizinhança regional | 14 pares (28 ligações), **idênticos** aos implicados pela vizinhança municipal |
| Moran regional | 12 combinações, 9.999 permutações; I abaixo do esperado (−0,125) em 11 de 12; p < 0,05 em 0 de 12 |
| Exportação | `indicadores_regionais.csv` (108 linhas) e `moran_regional.csv` (12) |
| Testes | 532/532 expectativas em 16 arquivos, 0 falhas, 0 pulados (eram 491 em 15) |
| Pipeline do zero | `run.R --limpar`: 8 etapas em 140 s |
| Reprodutibilidade | 2ª execução do zero: 76 de 77 arquivos idênticos byte a byte; o que difere é o LEIA-ME, que carimba a hora |
| Relatório | 0 números digitados (teste verde); nova seção "Escala de região de saúde", 2 tabelas e 1 figura; renderização sem aviso |

## Fonte da tabela município → região

`healthregions_2025_simplified.parquet` da versão de dados v2.0.0 do geobr (IPEA), 21 MB,
registrada no manifesto com SHA-256 e guardada em `dados/brutos/` (fora do git, como os
bancos do SIVEP). Só as colunas `code_muni` e `code_health_region` são lidas; a geometria
do arquivo não é usada.

Conferências feitas antes de adotar:

1. **Estabilidade:** as edições 2013, 2023, 2024 e 2025 do geobr põem os 92 municípios nas
   mesmas 9 regiões — 0 diferenças.
2. **Fonte oficial:** as páginas "Retratos Municipais" do TabNet da SES-RJ, uma por região,
   listam 91 municípios; todos estão na mesma região do geobr. A capital não aparece na
   lista da página da Metropolitana I; o geobr a põe lá, o que concorda com a SES-RJ.
3. **Nomes:** o geobr 2023+ traz os nomes com acentuação corrompida ("Baixada Litorã¢Nea").
   O código usa o código da região como chave e um nome canônico nosso
   (`REGIOES_SAUDE_RJ`); código desconhecido faz a leitura parar.

## Decisões de método (dentro do escopo do CS-030, sem ADR novo)

- **Geometria:** malha IBGE dissolvida (ADR-0006), união feita em UTM 23S.
- **Taxa:** soma dos casos / soma da população, dois denominadores como no município
  (ADR-0003). Sem Bayes empírico: a menor região tem 254 mil habitantes.
- **Estatística:** só Moran global, descritivo. Sem LISA: com 9 unidades, a correção FDR
  do ADR-0004 anularia quase tudo.
- **Rótulo no mapa:** no município mais populoso de cada região (regra fixa, sem ajuste
  à mão), porque o ponto interno do polígono sobrepunha Metropolitana II e Baixada
  Litorânea e jogava a Baía da Ilha Grande sobre as ilhas.

## Achados

- **Metropolitana I e II não são vizinhas** na malha IBGE: estão a 189 m, separadas pela Baía
  de Guanabara e por Guapimirim (Serrana). Nenhum par de municípios das duas se toca, então
  não é artefato da dissolução.
- **Autocorrelação regional negativa ou nula:** os agrupamentos municipais (VSR 2024 no leste
  da Baía de Guanabara) não reaparecem entre regiões. A Metropolitana II é a região de maior
  taxa de VSR em 2024 (21,0 por 100 mil) e contém os três Alto-Alto confirmados (Itaboraí,
  Maricá, Tanguá). É o problema da unidade de área modificável, citado no relatório.
- **Limitações do relatório:** "Escalas não entregues" virou "Padronização por idade não
  entregue" e entrou "Escala regional só descritiva" (17 itens no §5.3).

## Erros do caminho

1. `spdep::moran.mc` recusa `nsim` maior que n! (3 regiões → no máximo 6 permutações). O
   teste sintético usa `nsim = 5`; nas 9 regiões reais o teto é 362.880.
2. `geom_sf_label(label.size = )` está obsoleto no ggplot2 4.x (`linewidth`), e o
   `point_on_surface` padrão avisava sobre coordenadas em graus: os rótulos agora recebem
   pontos prontos e `fun.geometry = identity`.
3. A frase "a região de maior taxa contém os agrupamentos confirmados" foi escrita
   primeiro como texto fixo; calculada, ela mostrou que os 5 confirmados de VSR 2024 incluem
   Comendador Levy Gasparian (Baixo-Baixo, Centro-Sul) e Petrópolis (Alto-Baixo, Serrana).
   Passou a filtrar só os Alto-Alto e a ter um ramo para o caso contrário.
4. Comentário de código dizia "até 6,8 milhões de habitantes"; a Metropolitana I tem 9,7
   milhões. Corrigido antes do commit.
