# ADR-0001 — Extração do SIVEP-Gripe por download direto do portal

- **Status:** aceito
- **Data:** 2026-09-25
- **Nasce em:** CS-005 · decide D-03 (formato) e D-07 (data de corte)

## Contexto

O PDF v1 diz três vezes que a extração é feita "via pacote microdatasus". A
documentação de `microdatasus::fetch_datasus()` aceita SIH, SIM, SINASC, CNES, SIA e
SINAN, e não aceita SIVEP-Gripe. O SIVEP-Gripe é distribuído por outro canal: o
Portal de Dados Abertos do SUS, conjunto "SRAG 2019 a 2026", em CSV, JSON, PARQUET e
XML, com os arquivos hospedados no S3 do Ministério.

## Decisões

1. **Download HTTP direto do S3 do portal**, pela função `baixar_sivep()`, sem
   `microdatasus`. O pacote continua sendo a ferramenta certa para o CNES (OE10).
2. **Formato PARQUET** (D-03). Tamanhos em 2026-09-25: 2022 = 43,8 MB; 2023 = 22,1 MB;
   2024 = 21,2 MB; 2025 = 26,8 MB. O PARQUET é colunar (lê 34 de 194 colunas sem abrir
   as outras), já vem tipado (datas como data, não texto) e dispensa a questão de
   codificação Latin-1 do CSV.
3. **URLs em `config/fontes.yml`, uma por ano.** O nome do arquivo carrega a data da
   versão (ex.: `INFLUD25-14-09-2026.parquet`). Trocar de versão é editar uma linha; o
   arquivo antigo e sua linha no manifesto permanecem.
4. **Data de corte do banco de 2025 = versão 14-09-2026** (D-07), a vigente no primeiro
   download. Ela passa a ser citada no relatório como a data do snapshot.
5. **Retomada de download.** Queda de conexão preserva os bytes em `.parcial`; a
   próxima tentativa pede só o resto (cabeçalho HTTP Range). Até 3 tentativas.

## Fatos descobertos ao implementar

- **Os bancos "congelados" não são imutáveis.** 2022, 2023 e 2024 foram republicados
  pelo Ministério em 23/03/2026. O manifesto com SHA-256 é o que garante que a análise
  roda sobre a mesma versão.
- **Cada banco anual é um ano epidemiológico, não um ano civil.** Nas fichas do RJ, 100%
  das datas de início de sintomas de cada banco caem no ano epidemiológico do banco: o
  de 2024 começa em 31/12/2023; o de 2025 vai de 29/12/2024 a 03/01/2026. O "ano" do
  estudo é, portanto, o ano epidemiológico (ver CS-036).
- **As datas vêm como `timestamp[ns]` sem fuso, à meia-noite UTC.** Lidas no fuso de
  Brasília, caem às 21h do dia anterior. A conversão correta é `as.Date(x, tz = "UTC")`:
  com ela, a semana epidemiológica calculada bate com o `SEM_PRI` do Ministério em 100%
  das fichas de 2022–2024; no fuso de Brasília, bate em cerca de 86%.
- **O `SEM_PRI` do banco de 2025 tem um erro.** As 226 fichas do RJ com início entre
  28/12/2025 e 03/01/2026 vêm com `SEM_PRI = 01`, mas pelo calendário oficial essa é a
  semana 53 de 2025. O projeto calcula a semana a partir de `DT_SIN_PRI` e mantém o
  `SEM_PRI` original só para conferência.

## Alternativas descartadas

- **`microdatasus`:** não cobre a fonte.
- **CSV:** maior, sem tipos, com codificação a tratar.
- **Pacote `datasus` (outro autor) ou API do portal:** a API CKAN do portal não
  respondeu JSON em 2026-09-25; um pacote de terceiro acrescentaria uma dependência
  para fazer um download HTTP simples.

## Consequências

- O pipeline depende do S3 do Ministério estar no ar só no primeiro download; depois,
  roda do disco conferido pelo manifesto.
- Uma nova versão do banco de 2025 exige decisão explícita: editar `config/fontes.yml`,
  baixar, e o relatório passa a citar a nova data de corte.
