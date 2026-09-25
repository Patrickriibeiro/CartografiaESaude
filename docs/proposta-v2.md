# Análise espaço-temporal de vírus respiratórios no Estado do Rio de Janeiro (2022–2025): uma prova de conceito reprodutível em R com dados do SIVEP-Gripe e IBGE

**Versão 2 — proposta de revisão** · 2026-09-25

Autora do projeto: Gabrielle Barbosa Teixeira Coelho, mestranda do Programa de Pós-Graduação
em Biologia Computacional e Sistemas (PPG-BCS), Instituto Oswaldo Cruz (IOC/Fiocruz).
Disciplina: Cartografia & Saúde: análise geoespacial como ferramenta aplicada na
parasitologia (IOC 14090).

> **Como ler esta versão.** A v1 (PDF de 23/09) foi gerada com apoio do Gemini e é o
> documento de referência. Esta v2 mantém a estrutura de seções da v1 para facilitar a
> transposição, corrige cinco erros factuais verificados em fontes oficiais (Apêndice B),
> preenche as seções que estavam vazias e amplia objetivos e fontes dentro do escopo já
> declarado. Tudo o que é proposta nova ou decisão da autora está marcado com
> **[REVISAR]**. Nada aqui é resultado: os números de resultados só existirão depois que o
> pipeline rodar.

## Sumário das mudanças em relação à v1

| # | O que mudou | Por quê |
|---|---|---|
| 1 | Extração do SIVEP-Gripe por download direto do Portal de Dados Abertos do SUS, não pelo pacote `microdatasus` | `microdatasus` não cobre o SIVEP-Gripe (Apêndice B, item 1) |
| 2 | Nomes de campos corrigidos: `CO_MUN_RES` (6 dígitos), `POS_PCRFLU` + `TP_FLU_PCR`, campos de antígeno nomeados | Dicionário oficial (Apêndice B, itens 2 e 3) |
| 3 | Denominador populacional definido ano a ano, com regra explícita para 2023 | O IBGE não publicou estimativa municipal em 2023 (Apêndice B, item 4) |
| 4 | Snapshot datado e com hash dos arquivos brutos | O banco de 2025 é atualizado semanalmente (Apêndice B, item 5) |
| 5 | Seções 1.1, 1.2 e hipótese de trabalho preenchidas | Estavam vazias na v1 |
| 6 | Objetivos específicos reescritos como produto + critério verificável | Objetivo sem critério não permite dizer se foi cumprido |
| 7 | Critério de caso por agente e regra de co-detecção explicitados | A v1 descrevia a intenção, não a regra |
| 8 | Duas escalas: município e região de saúde (9 regiões da SES-RJ) | O PDF pede "comportamento regional além das fronteiras administrativas"; a região de saúde é a unidade de gestão do SUS |
| 9 | Suavização empírica de Bayes e correção para testes múltiplos no LISA | Municípios pequenos e 92 testes simultâneos produzem falsos hotspots |
| 10 | Padronização por idade como objetivo opcional | VSR concentra-se em < 2 anos e Influenza em idosos; estruturas etárias diferem entre municípios |
| 11 | Leitos do CNES como covariável de contexto | Taxa por residência reflete também onde há hospital; discutir sem dado é especulação |
| 12 | Aspectos éticos e limitações explicitados | Exigidos em qualquer projeto de pós-graduação com dado de saúde |
| 13 | *(2026-09-25, CS-037)* §3.2, §3.3, §3.4, §3.5 e §3.10 atualizadas com os achados da implementação: critério de caso (ADR-0002), denominador (ADR-0003), malha do IBGE (ADR-0006) | Os dados reais contradisseram três suposições da versão anterior desta proposta |

---

## 1 Introdução

### 1.1 Contextualização

A Síndrome Respiratória Aguda Grave (SRAG) é a forma grave das infecções respiratórias
agudas: o paciente precisa de internação, ou evolui a óbito, com quadro de dispneia,
saturação baixa ou desconforto respiratório. No Brasil, todo caso de SRAG hospitalizado
ou óbito por SRAG é de notificação compulsória no Sistema de Informação de Vigilância
Epidemiológica da Gripe (SIVEP-Gripe), cujos microdados anonimizados o Ministério da
Saúde publica no Portal de Dados Abertos do SUS, em bancos anuais, com atualização
semanal para o ano corrente.

O período 2022–2025 é epidemiologicamente singular. Encerrada a Emergência de Saúde
Pública de Importância Nacional por COVID-19 (abril de 2022), o SARS-CoV-2 deixou de ser
o agente dominante das SRAG e passou a cocircular com a Influenza A e B e com o Vírus
Sincicial Respiratório (VSR), este último com sazonalidade de outono-inverno no Sudeste
e carga concentrada em crianças menores de dois anos. Os boletins InfoGripe da Fiocruz
mostram que, entre os casos de SRAG com agente identificado em 2025, o VSR e a
Influenza A superaram amplamente o SARS-CoV-2 **[REVISAR: transcrever os percentuais do
boletim mais recente disponível no momento da entrega, com a semana epidemiológica]**.
Esse rearranjo, e não a pandemia em si, é o objeto deste projeto.

O Estado do Rio de Janeiro tem 92 municípios, 16.055.174 habitantes no Censo 2022 (IBGE,
tabela 4714) e uma organização do SUS em nove regiões de saúde (Metropolitana I,
Metropolitana II, Baía da Ilha Grande, Baixada Litorânea, Centro-Sul, Médio Paraíba,
Serrana, Norte e Noroeste). A concentração de leitos e serviços na região metropolitana
faz com que o município do Rio importe internações por SRAG de municípios vizinhos, como
mostrou a análise de fluxo origem-destino de Cavalcante et al. (2021). Isso torna a
escolha entre "município de residência" e "município de notificação" uma decisão
metodológica, não um detalhe.

### 1.2 Problematização

A vigilância de SRAG no Brasil é comunicada, na prática, em escala nacional e estadual:
os boletins InfoGripe e os painéis do Ministério agregam por UF. Em um estado com a
heterogeneidade demográfica e assistencial do Rio de Janeiro, a média estadual esconde
municípios com carga de doença grave muito acima ou muito abaixo do esperado, e não
diz se esses municípios se agrupam em territórios contíguos, o que teria implicação
direta para a alocação regional de leitos, testagem e vacinação.

Três obstáculos explicam por que essa leitura territorial raramente é feita:

1. **Volume e formato dos dados.** Cada banco anual do SIVEP-Gripe tem ~190 colunas e
   centenas de milhares de registros nacionais; extrair, filtrar e classificar por agente
   exige código, não planilha.
2. **Instabilidade estatística de municípios pequenos.** Em um município de 5 mil
   habitantes, três casos produzem uma taxa de 60 por 100 mil. Mapas de taxa bruta
   destacam ruído.
3. **Ausência de pipeline reprodutível.** Análises publicadas raramente disponibilizam
   código e dados de forma que outro pesquisador (ou a própria vigilância municipal)
   reexecute a análise quando o banco é atualizado.

Este projeto ataca os três obstáculos com uma prova de conceito: um pipeline aberto em
R que vai do download ao mapa, com estatística espacial que trata os pequenos números e
os testes múltiplos, e com painel interativo para a vigilância municipal.

### 1.3 Hipótese de trabalho *(decidido pela autora em 2026-09-25: H1–H3 principais; H4 opcional, junto com o OE10)*

- **H1 (dependência espacial).** As taxas municipais de SRAG por SARS-CoV-2, Influenza e
  VSR no RJ não se distribuem aleatoriamente: apresentam autocorrelação espacial
  positiva (Moran Global I > 0, p < 0,05) em pelo menos um dos anos do período.
- **H2 (especificidade por agente).** Os agrupamentos de alto risco (LISA Alto-Alto)
  ocupam territórios diferentes para cada agente: o VSR tende a concentrar-se em
  municípios densos da região metropolitana, com maior proporção de crianças pequenas; a
  Influenza, de forma mais difusa e com peso da população idosa; o SARS-CoV-2, em
  retração ao longo do período.
- **H3 (dinâmica temporal).** A localização dos hotspots muda entre 2022 e 2025,
  refletindo a transição pós-emergência e a retomada da sazonalidade dos vírus
  endêmicos.
- **H4 (viés assistencial, secundária e opcional).** Parte da heterogeneidade das taxas por
  município de residência é explicada pela oferta de leitos hospitalares (CNES), o que
  será verificado de forma descritiva, não causal.

### 1.4 Pergunta de pesquisa e justificativa do suporte cartográfico

**Pergunta:** Como as taxas de incidência de SRAG por SARS-CoV-2, Influenza A/B e VSR se
distribuem entre os 92 municípios e as 9 regiões de saúde do Estado do Rio de Janeiro,
em 2022–2025, e onde se concentram os agrupamentos espaciais de alto risco?

**Justificativa cartográfica:** a notificação é um evento pontual (um paciente, um
endereço); a decisão sanitária é territorial (um município, uma região de saúde). O
suporte cartográfico é o que permite agregar o ponto no polígono, comparar polígonos com
um denominador populacional e, sobretudo, perguntar se o que acontece em um polígono
depende do que acontece nos vizinhos, pergunta que só a estatística espacial responde.

---

## 2 Objetivos

### 2.1 Objetivo geral

Desenvolver e disponibilizar publicamente um pipeline analítico reprodutível em R que
mapeie e analise a distribuição espaço-temporal da incidência de SRAG por SARS-CoV-2,
Influenza A/B e VSR nos 92 municípios e 9 regiões de saúde do Estado do Rio de Janeiro,
2022–2025, a partir de dados abertos do SIVEP-Gripe e do IBGE, identificando
agrupamentos espaciais de alto risco por agente e por ano.

### 2.2 Objetivos específicos

Cada objetivo declara o produto e o critério pelo qual se verifica que foi cumprido.

| OE | Objetivo | Produto | Critério de cumprimento |
|---|---|---|---|
| OE1 | Automatizar a obtenção, a filtragem e a curadoria das fichas de SRAG do RJ (2022–2025) a partir do Portal de Dados Abertos do SUS, com registro de proveniência | `sivep_processado.parquet` + `dados/MANIFESTO.md` | 4 bancos anuais baixados, com URL, data e hash SHA-256; 100 % dos registros com `CO_MUN_RES` iniciado em 33; contagem por agente × ano tabulada |
| OE2 | Definir e aplicar critério explícito de caso confirmado por agente (RT-PCR ou antígeno) e regra de co-detecção | Decisão registrada (ADR-0002) + coluna `agente` | Tabela comparando quantos casos cada regra alternativa incluiria |
| OE3 | Calcular incidência acumulada por 100 mil habitantes por município, agente e ano, com denominador do IBGE definido ano a ano, e a versão suavizada por Bayes empírico | `indicadores_municipais.parquet` | Grade completa 92 × 3 × 4 sem valor faltante; município sem caso registrado com zero |
| OE4 | Padronizar cartograficamente a malha municipal oficial do IBGE e a de regiões de saúde (ADR-0006) em SIRGAS 2000 (EPSG:4674) e integrá-las aos indicadores pela chave IBGE | `municipios_rj.rds`, `regioes_saude_rj.rds` | 92 feições válidas; junção com indicadores retorna 92 linhas; 9 regiões |
| OE5 | Testar dependência espacial global (Moran I, Monte Carlo) e mapear agrupamentos locais (LISA) por agente e ano, com correção para testes múltiplos | `moran_lisa.rds` + 12 mapas LISA | 12 valores de I com p-valor; tabela LISA 92 × 12 com classe e p corrigido |
| OE6 | Disponibilizar painel interativo (Shiny + leaflet) com filtros por agente e ano exibindo taxa bruta, taxa suavizada e classe LISA por município | `app.R` | 12 combinações filtram sem erro; popup com 6 campos |
| OE7 | Gerar relatório e apresentação a partir do mesmo código-fonte (Quarto), com todos os números lidos dos objetos do pipeline | `08_relatorio.qmd` | `quarto render` sem erro; zero números digitados à mão no fonte |
| OE8 | Publicar código, dados processados e documentação em repositório público com ambiente congelado (`renv`) e testes automatizados | repositório GitHub | Terceiro reexecuta do zero seguindo o README; testes verdes em integração contínua |
| OE9 *(opcional, D-10; entregue no CS-033)* | Calcular taxas padronizadas por idade (método direto, 11 faixas, Censo 2022 por faixa etária, padrão RJ 2022) para os três agentes | coluna `incid_pad_100k` | Comparação bruta × padronizada no relatório: correlação de postos ≥ 0,99; razão mediana 0,93–1,01 |
| OE10 *(opcional, D-10; entregue no CS-034)* | Descrever a relação entre taxa por residência e oferta de leitos (CNES) por município e região de saúde | `spearman_leitos.csv`, `leitos_regionais.csv`, gráfico | Coeficiente de correlação de Spearman por ano, com IC por bootstrap, sem inferência causal |

---

## 3 Metodologia e ferramentas cartográficas

### 3.1 Desenho do estudo e área de abrangência

Estudo ecológico, exploratório e espaço-temporal. Unidade de análise: o município de
**residência** do paciente (92 unidades), com agregação secundária em 9 regiões de saúde.
Período: primeiros sintomas entre 02/01/2022 (início da semana epidemiológica 1 de 2022)
e 03/01/2026 (sábado que fecha a semana 53 de 2025), no snapshot de 2025 de 14/09/2026 (ADR-0001),
agregado por ano epidemiológico e, para descrição temporal, por semana epidemiológica
recalculada de `DT_SIN_PRI` (o `SEM_PRI` do banco rotula a semana 53/2025 como 01; D-08).
Série semanal entregue no CS-032: 209 semanas, estado e 9 regiões.

**"Ano" é o ano epidemiológico (CS-036).** Cada banco anual do SIVEP reúne as fichas cujo
início de sintomas cai nas semanas epidemiológicas daquele ano, de domingo a sábado: 2022 vai
de 02/01/2022 a 31/12/2022, 2023 de 01/01/2023 a 30/12/2023, 2024 de 31/12/2023 a
28/12/2024 e 2025 de 29/12/2024 a 03/01/2026. Consequência: 2025 tem **53 semanas** (371
dias), 7 dias a mais que os outros anos; o relatório mostra quanto a semana 53 pesa. Agentes: SARS-CoV-2,
Influenza (A e B, analisadas em conjunto e separadas quando o n permitir) e VSR.

> Estudo ecológico: a unidade de observação é o grupo, não o indivíduo. Conclusões
> sobre municípios não se transferem a pessoas (falácia ecológica). Isso vai para a
> seção de limitações.

### 3.2 Fontes de dados

Todas públicas, gratuitas e de acesso aberto.

| Fonte | O que fornece | Acesso | Observação |
|---|---|---|---|
| SIVEP-Gripe, bancos anuais 2022–2025 | Fichas individuais de SRAG notificada (hospitalizados e óbitos) | Portal de Dados Abertos do SUS, conjunto "SRAG 2019 a 2026", formatos CSV e PARQUET | Bancos 2019–2024 congelados; 2025–2026 atualizados semanalmente. Download por HTTP com registro de proveniência |
| Dicionário de dados SIVEP-Gripe 2019–2025 | Nome, tipo e domínio de cada campo | Mesmo conjunto, recurso "Dicionário de Dados" | Fonte de verdade para nomes de campos; substitui os nomes usados na v1 |
| IBGE, Censo 2022 (SIDRA tabela 4714) | População residente por município, 2022 (contagem, sem ajuste de cobertura) | API SIDRA | Denominador de 2022 (ver §3.4 e ADR-0003) |
| IBGE, Estimativas populacionais (SIDRA tabela 6579) | População estimada, 1º de julho | API SIDRA | Denominadores de 2024 e 2025; **não há 2023** |
| IBGE, Censo 2022 por idade (SIDRA tabela 9514) | População por faixa etária e município | API SIDRA | Só para OE9 (padronização) |
| IBGE, Malha Municipal 2022 | Polígonos municipais do RJ, resolução completa | `geoftp.ibge.gov.br` (arquivo `RJ_Municipios_2022.zip`) | Já em EPSG:4674; registrada no manifesto com hash. **Não** a malha simplificada do `geobr`, que perde 8 pares de vizinhos (ADR-0006) |
| Regiões de saúde (tabela município → região) | Qual das 9 regiões contém cada município | pacote `geobr` (`read_health_region`), só como atributo | A geometria regional sai de dissolver a malha do IBGE (ADR-0006) |
| CNES, leitos | Leitos SUS e de UTI SUS por estabelecimento, mês a mês | Portal de Dados Abertos do SUS, conjunto "Hospitais e Leitos" (CSV anual; CS-034) | Só para OE10. Competência de julho. Preferido ao `microdatasus` (CNES-LT): mesmo portal do SIVEP, CSV em vez de `.dbc`, sem pacote fora do CRAN. Sem código IBGE em 2022–2024: junção por nome, conferida com o código de 2025 |
| Boletins InfoGripe (Fiocruz) | Composição viral e tendência nacional/estadual por semana | Agência Fiocruz / GitHub `infogripe` | Contexto e validação externa da tendência estadual, não entra no cálculo |

### 3.3 Coleta, curadoria e tratamento dos dados do SIVEP-Gripe

**Extração.** Os bancos anuais são baixados diretamente do Portal de Dados Abertos por
HTTP, em PARQUET (ADR-0001), com leitura seletiva de ~25
colunas pelo pacote `arrow`, o que evita carregar em memória as ~190 colunas de cada
banco. Cada arquivo baixado recebe entrada em `dados/MANIFESTO.md` com URL, data e hora,
tamanho e hash SHA-256. O pipeline recusa-se a processar arquivo cujo hash não conste do
manifesto. O snapshot de 2025 fica assim datado e verificável.

**Seleção espacial.** Retêm-se os registros cujo `CO_MUN_RES` (código IBGE do município
de residência, 6 dígitos, tratado como texto) inicia em `33`. A escolha por residência,
e não por notificação (`CO_MUN_NOT`), segue a prática da vigilância para incidência; a
diferença entre as duas é quantificada no relatório porque mede o fluxo intermunicipal
de internações (Cavalcante et al., 2021).

**Seleção temporal (CS-036).** A data é a de primeiros sintomas (`DT_SIN_PRI`), presente
em todas as fichas dos quatro bancos; o pipeline para se faltar alguma, em vez de
substituí-la pela data de notificação. Cada ficha entra no ano do banco em que está, e o
pipeline confere que o ano epidemiológico calculado de `DT_SIN_PRI` é esse mesmo ano: 0
divergências nos quatro bancos. Não há corte em 01/01/2022: essa data é da semana 52 de
2021.

**Critério de caso por agente (decidido pela autora em 2026-09-25; ADR-0002).** A
leitura literal da v1 (classificação final **e** campo do vírus marcado) foi testada nas
99.880 fichas do RJ e descartada: o campo "qual vírus" fica em branco em fichas com
resultado positivo, em proporção que cai de 27 % (2022) para 5 % (2025) entre as
encerradas como COVID, o que fabricaria uma queda artificial no período. A regra
adotada ancora o caso na declaração da vigilância:

| Agente | Regra adotada (R2 "vigilância", ADR-0002) |
|---|---|
| SARS-CoV-2 | `CLASSI_FIN == 5` **e** (`CRITERIO == 1` laboratorial **ou** `PCR_SARS2 == 1` **ou** `AN_SARS2 == 1`) |
| Influenza | `CLASSI_FIN == 1` **e** (`CRITERIO == 1` **ou** `POS_PCRFLU == 1` **ou** `POS_AN_FLU == 1`); subtipo A/B por `TP_FLU_PCR` ou `TP_FLU_AN` |
| VSR | `CLASSI_FIN == 2` **e** (`PCR_VSR == 1` **ou** `AN_VSR == 1`) — o código 2 cobre qualquer "outro vírus", então só o campo do VSR o identifica |

A regra exclui os encerramentos clínicos e por imagem, que deixaram de valer para COVID
em 31/10/2022 (1.509 fichas em 2022; 3, 5 e 0 nos anos seguintes). O relatório traz,
como sensibilidade, a regra literal (limite inferior) e a só-classificação (limite
superior). Toda ficha do banco conta, sem filtrar o campo de internação (1,0 % marcadas
"não internado"); por isso o texto fala em **SRAG notificada**.

Onde `CLASSI_FIN` é a classificação final da vigilância (1 influenza; 2 outro vírus
respiratório; 3 outro agente etiológico; 4 não especificado; 5 COVID-19) e os campos
`PCR_*`/`AN_*` são os resultados por RT-PCR e por teste de antígeno. Ficha com
`CLASSI_FIN` vazio é caso **não encerrado**, não negativo; a proporção de não encerrados
por ano é reportada. No snapshot de 14/09/2026 ela **não** cresce no ano corrente:
1.028, 481, 760 e 138 fichas em 2022–2025 (ADR-0002 §3.4).

**Co-detecção (decidido, ADR-0002).** Uma ficha pode ter mais de um dos três vírus
detectado, mas isso é raro: 305 das 99.880 fichas (0,3 %). Como cada ficha tem uma só
classificação final, a regra adotada atribui cada caso a **um** agente, o da
classificação; as co-detecções são reportadas em tabela por agente e ano, e não contadas
duas vezes. O campo oficial `CO_DETEC` não é usado: marca co-detecção com qualquer vírus
e está vazio em 65 % das fichas.

**Validação.** Funções de validação verificam presença das colunas, pertencimento dos
92 códigos ao RJ, plausibilidade de datas e consistência entre `SEM_PRI` e `DT_SIN_PRI`.
Toda função é coberta por teste automatizado sobre uma base sintética rotulada como
fabricada, o que permite testar sem baixar dados reais.

### 3.4 Indicadores territoriais

**Incidência acumulada bruta** por município, agente e ano:
`casos / população × 100 000`.

**Denominador ano a ano (decidido pela autora em 2026-09-25; ADR-0003).** O IBGE não publicou
estimativa municipal em 2023, e as estimativas de 2024 e 2025 partem do Censo 2022
**ajustado** pela Pesquisa de Pós-Enumeração, com ajuste maior nos municípios grandes
(IBGE, Estimativas da População 2024, Nota metodológica n. 01, p. 6–7). Por isso a
estimativa de 2024 fica de 3,1 % (Cambuci) a 8,4 % (Rio de Janeiro) acima da contagem do
Censo, em todos os 92 municípios. Usar o Censo como denominador de 2022 infla a taxa
daquele ano na mesma proporção. Por isso o projeto usa dois denominadores, cada um com
um uso: o **mapa e o LISA de cada ano** usam a população oficial daquele ano (Censo em
2022; 2023 interpolado nas datas de referência reais, peso 0,4771; estimativas em
2024–2025); as **comparações entre anos** usam a estimativa de 2024 como denominador
único, o que remove o degrau. Cada uso traz o outro como sensibilidade. A fonte de cada ano consta de uma coluna `fonte` da tabela de
população.

**Grade completa.** A tabela final tem exatamente 92 × 3 × 4 linhas; município sem caso
registrado aparece com zero, nunca desaparece (uma junção que descarta o zero
distorce o Moran).

**Suavização empírica de Bayes** (`spdep::EBest`): taxa que encolhe os municípios de
população pequena em direção à média estadual, proporcionalmente à sua incerteza. O
relatório apresenta bruta e suavizada lado a lado; o LISA roda sobre a suavizada, e a
bruta entra como sensibilidade (decidido pela autora, D-09). Método, fórmula e efeito
medido em `docs/nota-metodologica-suavizacao.md` (Marshall, 1991).

**Padronização por idade (OE9, opcional).** Método direto, faixas etárias do Censo 2022
(tabela 9514), população-padrão = RJ 2022. Justificativa: VSR e Influenza têm perfis
etários opostos e os municípios do RJ diferem muito em estrutura etária.
*Entregue no CS-033 (2026-09-25):* 11 faixas (<1, 1-4, 5-9, 10-19, ..., 70-79, 80+); a estrutura
etária de 2022 é aplicada à população de cada ano (o IBGE não tem estrutura municipal para
2023–2025); calculada para os três agentes; `docs/nota-metodologica-padronizacao.md`.

**Escala regional.** Os mesmos indicadores agregados por região de saúde (soma de casos
e de população das unidades), com mapa próprio. É a escala em que a SES-RJ e as
Comissões Intergestores Regionais decidem.
*Entregue no CS-030 (2026-09-25):* tabela município → região do geobr 2025, conferida
contra a SES-RJ; geometria dissolvida da malha IBGE; 12 mapas regionais; Moran global
regional só descritivo (n = 9), sem LISA.

### 3.5 Processamento cartográfico e padronização geodésica

Malha Municipal 2022 do IBGE para o RJ, em resolução completa, baixada do servidor
oficial, registrada no manifesto com hash e lida direto do arquivo compactado; já vem em
SIRGAS 2000 (EPSG:4674) e as 92 geometrias são válidas. A malha simplificada do `geobr`,
prevista na v1, foi descartada: comparada à oficial, ela perde 8 pares de municípios
vizinhos (440 contra 456 ligações de contiguidade), o que mudaria o Moran e o LISA sem
erro aparente (ADR-0006). A geometria das regiões de saúde sai de dissolver essa malha.
A junção atributiva com os indicadores usa a chave `cod6 = substr(CD_MUN, 1, 6)`, porque
o IBGE registra 7 dígitos (o último é verificador) e o SIVEP registra 6. Teste automatizado exige 92 feições após a
junção; a junção direta com 7 dígitos retornaria zero linhas sem acusar erro.

### 3.6 Estatística espacial (AEDE e LISA)

**Vizinhança.** Matriz de contiguidade Queen de 1ª ordem (`spdep::poly2nb`), pesos
padronizados por linha (estilo W). Verifica-se que o grafo tem um único componente
conexo (`n.comp.nb`) e que nenhum município fica sem vizinho. Análise de sensibilidade
com contiguidade Rook.

**Moran Global.** `moran.mc` com 9.999 permutações e semente fixa, por agente × ano
(12 testes), hipótese alternativa de autocorrelação positiva (H1). Reporta-se I, pseudo
p-valor e o gráfico de dispersão de Moran. Com 999 permutações o menor p possível
(0,001) ficaria acima do limiar mais exigente da correção FDR para 92 testes (0,00054),
e a correção seria decidida pela resolução da simulação (ADR-0004 §3).

**LISA.** `localmoran_perm` (9.999 permutações, p bicaudal), quadrante pelo diagrama de
Moran (Alto-Alto, Baixo-Baixo, Alto-Baixo, Baixo-Alto). Como são 92 testes simultâneos
por mapa, os p-valores são corrigidos por FDR (Benjamini-Hochberg, α = 0,05) e o
resultado sai em **dois níveis**: *confirmado* (significativo após a correção) e
*indicativo* (significativo só sem correção); o restante é não significativo. O mapa
distingue os dois níveis; a tabela conta ambos e o esperado por acaso (4,6 por mapa). Os
três municípios com um único vizinho (Paraty, Itatiaia, Armação dos Búzios) mantêm a
classe, marcada como instável (ADR-0004). A variável de entrada é a taxa suavizada; a
taxa bruta e a vizinhança Rook entram como sensibilidade.

> FDR (taxa de falsas descobertas): correção que limita a proporção esperada de falsos
> positivos entre os municípios declarados significativos. Sem ela, 92 testes a 5 %
> produzem ~4,6 "hotspots" por acaso.

### 3.7 Interface interativa e reprodutibilidade computacional

O pipeline segue a organização de scripts numerados da v1 (`00_setup` a
`07_exportacao`, `run.R`, funções em `R/funcoes_*.R`), com ambiente congelado por
`renv`, testes com `testthat` executados em integração contínua (GitHub Actions) sobre a
base sintética, relatório e apresentação em Quarto (`08_relatorio.qmd`) e painel Shiny +
leaflet (`app.R`) com filtros por agente e ano, mapa coroplético, camada LISA e popup
com casos, população, taxa bruta, taxa suavizada e classe. Todo número do relatório é
lido dos objetos de `resultados/`; nenhum é digitado. O repositório público inclui
licença, arquivo de citação e o manifesto de proveniência.

### 3.8 Aspectos éticos **[REVISAR: confirmar com o orientador e a secretaria do PPG]**

O projeto usa exclusivamente bases secundárias públicas, anonimizadas pelo Ministério da
Saúde antes da publicação, e divulga apenas agregados por município e região. Enquadra-se
no art. 1º da Resolução CNS nº 510/2016, que dispensa de registro no sistema CEP/CONEP a
pesquisa com informações de acesso público (Lei nº 12.527/2011) e com bancos de dados
sem possibilidade de identificação individual. Nenhum microdado é redistribuído pelo
repositório; o `.gitignore` exclui `dados/brutos/`.

### 3.9 Articulação com a disciplina e justificativa das exclusões

Mantida da v1: o projeto integra geoprocessamento (malhas, SIRGAS 2000, junção
espacial), mineração de dados abertos em saúde e estatística espacial frequentista. Não
incorpora sensoriamento remoto e Google Earth Engine (o objeto é a notificação clínica,
sem superfícies ambientais nesta fase), levantamento por GPS (dado secundário agregado
por polígono) nem Random Forest, métricas de paisagem, lógica fuzzy e redes neurais
(prioridade à robustez da estatística espacial e à entrega da interface). A v2
acrescenta um argumento: as exclusões deixam explícito o que uma segunda fase poderia
incluir, em especial covariáveis ambientais (temperatura, umidade) para o VSR.

### 3.10 Limitações antecipadas no desenho

1. **O SIVEP mede doença grave, não infecção.** Taxas de SRAG notificada dependem de
   acesso a leito e de testagem; um município com hospital de referência pode aparecer
   "quente" por captar casos graves da vizinhança (mitigado ao usar residência) ou por
   testar mais (não mitigável; discutido com CNES, OE10).
2. **Maturação do banco e testagem.** O relatório declara a data de corte do banco de
   2025 (14/09/2026). Neste snapshot, 2025 tem a menor proporção de fichas não encerradas
   (0,6 %), então a maturação não é a limitação principal; a cobertura de testagem com
   resultado sobe de 87,5 % (2022) para 91,7 % (2025) e pode, sozinha, produzir aumento
   de casos confirmados.
6. **Degrau do denominador.** O Censo 2022 é uma contagem sem ajuste de cobertura; as
   estimativas de 2024–2025 são ajustadas (3,1–8,4 % acima, por município). Sem tratamento,
   a taxa de 2022 fica inflada em relação aos anos seguintes (ADR-0003).
7. **Efeito de borda.** Municípios de divisa não têm os vizinhos de SP, MG e ES na
   matriz; Paraty, Itatiaia e Armação dos Búzios têm um único vizinho, e a classe LISA
   deles aparece no mapa marcada como "instável" (decidido pela autora, CS-039).
8. **Residência × notificação.** 8.040 (2022), 4.190, 4.117 e 5.451 (2025) fichas foram
   notificadas fora do município de residência. O CS-031 mede o fluxo em casos (7.286
   notificados em outro município do RJ; 13 municípios "importadores"), não por hospital
   nem por distância.
9. **Confirmação declarada.** 941 casos de COVID de 2022 entram só pela confirmação
   laboratorial declarada pela vigilância, sem resultado nos campos exportados (ADR-0002).
10. **Agrupamentos de zeros.** Zero caso em município pequeno pode ser ausência de
    notificação; por isso a taxa bruta é só sensibilidade (ADR-0004).
11. **Banco vivo, dicionário antigo e semana do Ministério.** A versão do banco de 2025 é
    citada no relatório; o dicionário oficial é de maio de 2023; 226 fichas da última
    semana de 2025 vêm com a semana rotulada errada, e o projeto a recalcula (ADR-0001).
12. **Suavização global e malha do painel.** O Bayes empírico puxa para a média do estado,
    não dos vizinhos; o painel desenha uma malha simplificada, a análise usa a completa.
13. **Contagens pequenas.** 349 combinações município × agente × ano têm de 1 a 4 casos e
    são publicadas sem supressão, porque o microdado de origem já é público (CS-043).

*Itens 8 a 13 acrescentados em 2026-09-25 a partir da auditoria final (CS-027, CS-044); os
números são os do relatório, que os calcula de `resultados/`.*
3. **Pequenos números e MAUP.** Tratados com suavização; o problema da unidade de área
   modificável (o resultado depende do recorte) é inerente ao desenho e declarado.
4. **Ecológico.** Nenhuma inferência individual.
5. **Sem ajuste de covariáveis.** O LISA é descritivo; associação com renda, idade ou
   leitos é exploratória (Spearman), não causal.

---

## 4 Resultados (a serem produzidos pelo pipeline)

Cada subseção da v1 passa a ter conteúdo definido e o artefato de onde vem.

| Seção | Conteúdo previsto | Origem |
|---|---|---|
| 4.1 Arquitetura do pipeline | Diagrama do fluxo, tempo de execução por etapa, número de testes | `resultados/execucao.log`, CI |
| 4.2 Distribuição espacial e taxas por **município** e região de saúde | Tabela descritiva (n, mediana, IQR das taxas por agente × ano); 12 mapas coropléticos municipais; 12 regionais; série por semana epidemiológica | `indicadores_municipais.parquet`, `resultados/mapas/` |
| 4.3 Agrupamentos espaciais (LISA) | Tabela de Moran I × p por agente × ano; 12 mapas LISA; lista dos municípios Alto-Alto por agente, com persistência ao longo dos anos | `moran_lisa.rds` |
| 4.4 Protótipo de painel | Capturas de tela; descrição das interações | `app.R` |
| 4.5 Código e dados | URL do repositório; hash dos bancos; versão do `renv.lock` | README, MANIFESTO |

---

## 5 Discussão (roteiro)

- **5.1** Interpretar hotspots por agente à luz da biologia (sazonalidade do VSR, perfil
  etário, transição pós-pandemia do SARS-CoV-2), da estrutura assistencial (leitos,
  fluxo metropolitano) e das campanhas de vacinação contra Influenza de cada ano
  (2023: 10/04 a 31/05; 2024: antecipada para março; 2025: início em 07/04 no Sudeste)
  **[REVISAR: confirmar datas de 2022 e 2024 no informe técnico de cada campanha]**.
- **5.2** O que a vigilância municipal e regional ganha com um pipeline reexecutável a
  cada atualização semanal do banco; como o painel se encaixa na rotina das CIR.
- **5.3** Limitações da §3.10, com os números que as quantificam (proporção de não
  encerrados, diferença residência × notificação, sensibilidade Queen × Rook, bruta ×
  suavizada, antes × depois do FDR).

## 6 Conclusão

A ser escrita a partir dos resultados. Deve responder à pergunta da §1.4 e às hipóteses
da §1.3 uma a uma, dizendo qual foi sustentada, qual não, e qual não pôde ser testada.

## 7 Cronograma **[REVISAR: depende do prazo, D-02]**

Sem datas até o prazo ser definido. A ordem é a do caminho crítico do
`docs/BACKLOG.md`: ambiente e repositório → extração e curadoria → critério de caso
(ADR) → indicadores e denominadores → malha → pesos e LISA → mapas, painel e relatório →
publicação e auditoria.

---

## Referências (verificadas em 2026-09-25)

Anselin L. Local Indicators of Spatial Association: LISA. *Geographical Analysis*.
1995;27(2):93-115.

Bastos LS, Economou T, Gomes MFC, Villela DAM, Coelho FC, Cruz OG, et al. A modelling
approach for correcting reporting delays in disease surveillance data. *Statistics in
Medicine*. 2019;38(22):4363-4377.

Bergamaschi Novaes Á. *Determinantes sociais da COVID-19 grave na cidade do Rio de
Janeiro: uma análise espacial ecológica dos casos notificados de SRAG por COVID-19 em
dois períodos entre março de 2020 e fevereiro de 2021* [dissertação]. Rio de Janeiro:
ENSP/Fiocruz; 2022. Disponível em: https://arca.fiocruz.br/items/f64f37f8-4a05-4913-995b-4f8a8eb40a4b

Bivand RS, Pebesma E, Gómez-Rubio V. *Applied Spatial Data Analysis with R*. 2. ed. New
York: Springer; 2013.

Brasil. Conselho Nacional de Saúde. Resolução nº 510, de 7 de abril de 2016. Disponível
em: https://bvsms.saude.gov.br/bvs/saudelegis/cns/2016/res0510_07_04_2016.html

Brasil. Ministério da Saúde. Banco de dados da Síndrome Respiratória Aguda Grave (SRAG),
2019 a 2026. Portal de Dados Abertos do SUS. Disponível em:
https://dadosabertos.saude.gov.br/dataset/srag-2019-a-2026 (acesso em 25 set. 2026;
atualização semanal, última em 14 set. 2026).

Brasil. Ministério da Saúde. 25ª Campanha Nacional de Vacinação contra a Influenza,
10/4 a 31/5/2023. Disponível em:
https://bvsms.saude.gov.br/25a-campanha-nacional-de-vacinacao-contra-a-influenza-sera-realizada-no-periodo-de-10-4-a-31-5-2023/

Castro MC, Kim S, Barberia L, Ribeiro AF, Gurzenda S, Ribeiro KB, et al. Spatiotemporal
pattern of COVID-19 spread in Brazil. *Science*. 2021;372(6544):821-826.
doi:10.1126/science.abh1558

Cavalcante JR, et al. Análise espacial do fluxo origem-destino das internações por
síndrome respiratória aguda grave por COVID-19 na região metropolitana do Rio de
Janeiro. *Revista Brasileira de Epidemiologia*. 2021;24:e210054. Disponível em:
https://www.scielo.br/j/rbepid/a/DNyHxvjJ9vHGjmVF6J5NDjq/

Fiocruz. Boletim InfoGripe, resumos semanais 2025–2026. Agência Fiocruz de Notícias.
Repositório: https://github.com/infogripe/Boletim_InfoGripe

Fiocruz, Instituto Fernandes Figueira. Sazonalidade do Vírus Sincicial Respiratório no
Brasil. Portal de Boas Práticas. Disponível em:
https://portaldeboaspraticas.iff.fiocruz.br/biblioteca/sazonalidade-do-virus-sincicial-respiratorio-no-brasil/

IBGE. Sistema IBGE de Recuperação Automática (SIDRA). Tabela 4714 (Censo 2022,
população residente); tabela 6579 (estimativas populacionais); tabela 9514 (Censo 2022
por idade). https://sidra.ibge.gov.br

IBGE. Estimativas da População 2024: estimativas da população residente para os
Municípios e para as Unidades da Federação brasileiros, com data de referência em 1º de
julho de 2024. Nota metodológica n. 01. Rio de Janeiro: IBGE; 2024. Disponível em:
https://biblioteca.ibge.gov.br/visualizacao/livros/liv102112.pdf

IBGE. Malha Municipal 2022, Rio de Janeiro. Disponível em:
https://geoftp.ibge.gov.br/organizacao_do_territorio/malhas_territoriais/malhas_municipais/municipio_2022/UFs/RJ/

Marshall RJ. Mapping disease and mortality rates using empirical Bayes estimators.
*Journal of the Royal Statistical Society, Series C*. 1991;40(2):283-294.

Pebesma E. Simple Features for R: standardized support for spatial vector data. *The R
Journal*. 2018;10(1):439-446.

Pereira RHM, Gonçalves CN, et al. geobr: Download Official Spatial Data Sets of Brazil.
Pacote R, CRAN. https://ipeagit.github.io/geobr/

Saldanha RF, Bastos RR, Barcellos C. Microdatasus: pacote para download e
pré-processamento de microdados do DATASUS. *Cadernos de Saúde Pública*. 2019;35(9).
(Previsto para o CNES; não usado: os leitos vieram do Portal de Dados Abertos, CS-034.)

Secretaria de Estado de Saúde do Rio de Janeiro. Regionalização: as nove regiões de
saúde. https://www.saude.rj.gov.br/assessoria-de-regionalizacao/sobre-a-regionalizacao/2017/04/regionalizacao

**[REVISAR: acrescentar as referências da disciplina (bibliografia da ementa) e o
dicionário de dados SIVEP-Gripe com a data da versão baixada.]**

---

## Apêndice A — Avaliação crítica da disciplina (IOC 14090)

Mantido da v1, texto pessoal da autora.

## Apêndice B — Correções factuais da v1 e suas fontes

| # | v1 dizia | Fato verificado | Fonte |
|---|---|---|---|
| 1 | Extração "via pacote microdatasus" | `fetch_datasus()` aceita SIH, SIM, SINASC, CNES, SIA e SINAN; **não** aceita SIVEP-Gripe/SRAG, que é distribuído por outro canal (Portal de Dados Abertos, CSV/PARQUET) | https://rfsaldanha.github.io/microdatasus/reference/fetch_datasus.html |
| 2 | Chave `CO_MUNIC_RES`, "sete dígitos" | O campo é `CO_MUN_RES`, tipo `Varchar2(6)`: **seis** dígitos. A malha do `geobr` tem sete; a junção exige truncar | Dicionário de dados SIVEP-Gripe (campo 24, "Município de residência, código IBGE") |
| 3 | Campo `PCR_FLU` | Influenza por RT-PCR é `POS_PCRFLU` (1-Sim/2-Não/9-Ignorado) com subtipo em `TP_FLU_PCR` (1-A/2-B); por antígeno, `POS_AN_FLU` e `TP_FLU_AN`. `PCR_SARS2` e `PCR_VSR` estão corretos; os de antígeno (`AN_SARS2`, `AN_VSR`) não eram citados | Dicionário de dados SIVEP-Gripe (campos 66 e 69) |
| 4 | "Estimativas populacionais intercensitárias" para todos os anos | A tabela 6579 tem 2024, 2025 e 2026 e **não tem 2023**; 2022 está no Censo (4714). O denominador de 2023 exige regra explícita | API SIDRA: `apisidra.ibge.gov.br/values/t/6579/n6/3304557/v/9324/p/all` |
| 5 | Pipeline "reprodutível" sem menção a versão dos dados | O banco de 2025 é atualizado semanalmente (última atualização 14/09/2026); reprodutibilidade exige data de corte e hash | Portal de Dados Abertos, metadados do conjunto "SRAG 2019 a 2026" |
| 6 | Seção 4.2 "por bairro" | Todo o desenho é municipal; o SIVEP não tem bairro estruturado para o estado | v1, §3.1 e §3.3 |
