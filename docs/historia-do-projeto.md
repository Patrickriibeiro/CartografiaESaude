# A história da construção do projeto, contada do zero

*Documento vivo, escrito em 2026-09-28 (CS-060) a pedido da autora. Conta, na ordem em que
aconteceu, como o projeto foi montado: cada pasta, cada arquivo, por que existe, o que tem
dentro, quem usa depois e o que aconteceria se não existisse. Não presume nenhum
conhecimento de programação.*

## Como ler este documento

Três combinados:

1. **Todo termo técnico é explicado na primeira vez que aparece**, ali mesmo, entre
   parênteses ou logo depois. Se um termo aparecer sem explicação, é falha deste texto, não sua.
2. **Tudo o que está afirmado aqui tem uma prova no repositório** (o conjunto de arquivos do
   projeto). Quando cito um arquivo, é lá que está a prova. Quando algo não está escrito em lugar
   nenhum e é uma dedução minha, a frase vem marcada assim: **"Isso é uma inferência técnica
   provável."**
3. **Cada parte termina com um resumo em forma de história curta.** Se você só ler os resumos,
   já entende a espinha dorsal.

A construção foi feita por Patrick entre 25 e 28 de setembro de 2026, com apoio de um
assistente de programação (um programa de inteligência artificial chamado Claude Code, que
escreve código sob orientação de uma pessoa). Isso está registrado em cada "commit" do
projeto (vou explicar o que é commit na Parte 0). Digo isso já no início porque explica duas
coisas que você vai ver: a velocidade (quatro dias) e a quantidade de documentação (o
assistente foi obrigado, por regra do projeto, a registrar cada decisão por escrito).

---

## Parte 0. Antes de qualquer arquivo: as palavras que vamos usar

Esta parte não fala do projeto ainda. Ela monta o vocabulário mínimo. Se você já sabe o que é
uma pasta e um arquivo, pule para "Programa, linguagem e R".

### Pasta e arquivo

Um **arquivo** é qualquer coisa guardada no computador com um nome: um texto, uma foto, uma
planilha. Uma **pasta** (o nome técnico é **diretório**) é uma gaveta que guarda arquivos e
outras pastas. O projeto inteiro é uma pasta chamada `CartografiaESaude`, com gavetas dentro.

Quando eu escrever `dados/brutos/`, leia assim: "a pasta `brutos`, que fica dentro da pasta
`dados`". A barra separa os níveis. Quando escrever `R/funcoes_sivep.R`, é "o arquivo
`funcoes_sivep.R`, dentro da pasta `R`".

*Analogia:* um armário de escritório. `CartografiaESaude` é o armário; `dados`, `resultados`,
`docs` são as gavetas; dentro de cada gaveta há pastas suspensas e, nelas, as folhas.

### A extensão do arquivo

O que vem depois do ponto no nome (`.R`, `.md`, `.yml`, `.csv`, `.png`) se chama **extensão**.
Ela diz de que tipo é o arquivo, e por isso diz que programa abre ele. Ao longo deste
documento vou explicar cada extensão que aparecer. As mais frequentes:

| Extensão | O que é | Abre com |
|---|---|---|
| `.R` | texto com instruções na linguagem R (explico abaixo) | RStudio ou qualquer editor de texto |
| `.md` | texto comum com marcações simples de formatação (Markdown) | Bloco de Notas, RStudio, e o GitHub o mostra formatado |
| `.yml` | texto de configuração no formato "nome: valor" (YAML) | Bloco de Notas |
| `.csv` | tabela em texto, uma linha por registro, colunas separadas por vírgula ou ponto e vírgula | Excel |
| `.parquet` | tabela em formato compacto, organizado por coluna | só por programa (R, Python) |
| `.rds` | um objeto do R guardado do jeito que estava na memória | só pelo R |
| `.png` | imagem | qualquer visualizador |
| `.html` | página que abre no navegador | Chrome, Edge |
| `.qmd` | texto misturado com código, que vira relatório (Quarto) | RStudio |
| `.docx` | documento do Word | Word |

*Analogia:* a extensão é a etiqueta no pote. "Farinha" e "açúcar" parecem iguais de longe; a
etiqueta diz o que tem dentro e para que serve.

### Programa, linguagem e R

Um **programa** é uma sequência de instruções que o computador executa. Uma **linguagem de
programação** é o idioma em que essas instruções são escritas. **R** é uma linguagem feita
para estatística e dados: nela é natural dizer "leia esta tabela, some esta coluna por
município, desenhe um mapa".

O **RStudio** é o programa em que a pessoa escreve e executa código R. Não é o R; é a mesa de
trabalho onde o R fica aberto. O R também roda sem o RStudio, por uma janela de texto chamada
**terminal** (ou **console**): você digita um comando, aperta Enter, ele responde.

### Script e função

Um **script** é um arquivo `.R` com uma lista de instruções, executadas de cima para baixo.
**Rodar** um script é mandar o R executar essa lista.

*Analogia:* um script é uma receita. "Pegue a farinha, misture com o ovo, leve ao forno." Rodar
é cozinhar.

Uma **função** é uma receita menor, com nome, que outras receitas chamam. Em vez de escrever
"bata as claras até formar picos" em dez receitas, você escreve uma vez, dá o nome "bater
claras em neve" e nas dez receitas só diz: "bata as claras em neve". No projeto, as funções
ficam na pasta `R/`, e os scripts numerados as chamam. Uma função recebe **argumentos** (os
ingredientes) e **devolve** um resultado.

### Pacote

Um **pacote** é um conjunto de funções que outras pessoas escreveram e publicaram para
qualquer um usar. Para ler mapas há o pacote `sf`; para estatística espacial, `spdep`; para
gráficos, `ggplot2`. Um pacote precisa ser **instalado** uma vez (baixado para o computador) e
**carregado** cada vez que se usa. O projeto usa cerca de 140 pacotes, contando os que os
pacotes principais precisam por baixo.

*Analogia:* caixa de ferramentas emprestada. Você não fabrica a chave de fenda; pega
emprestada a de quem já fez.

### Tabela, linha, coluna

Quase todo dado do projeto é uma **tabela**: linhas e colunas, como uma planilha. Cada
**linha** é um registro (uma ficha de paciente, um município num ano) e cada **coluna** é uma
característica (data, código do município, número de casos). Em R uma tabela se chama
`data.frame`.

### Pipeline

**Pipeline** é uma sequência de etapas em que cada uma pega o que a anterior produziu e
produz algo para a seguinte. Neste projeto são oito etapas: baixar os dados, limpar, calcular
taxas, montar o mapa, achar vizinhos, fazer a estatística espacial, desenhar, exportar.

*Analogia:* linha de montagem de uma fábrica de pão. Uma estação peneira a farinha; a próxima
mistura; a próxima sova; a próxima assa. Ninguém assa antes de sovar. Se a estação da farinha
parar, nada sai do forno.

### Git, commit e GitHub

**Git** é um programa que guarda o histórico de um projeto: toda vez que a pessoa manda, ele
tira uma "foto" de todos os arquivos e guarda com data, autor e uma frase de legenda. Essa
foto se chama **commit**. Com isso dá para voltar a qualquer versão anterior, ver o que mudou
entre duas versões e provar quando cada coisa foi feita.

**GitHub** é um site que guarda esse histórico na internet, para que outras pessoas possam
baixar o projeto inteiro (isso se chama **clonar**) e para que ele não se perca se o
computador quebrar. O projeto está em `github.com/Patrickriibeiro/CartografiaESaude`, público.

O **repositório** é o conjunto "arquivos do projeto + histórico do Git". Quando eu disser
"está no repositório", quero dizer "está nos arquivos que qualquer pessoa pode baixar".

*Analogia:* Git é um diário de bordo com fotos. Cada commit é uma foto com legenda e data. O
GitHub é o cofre onde o diário fica guardado, com cópia fora de casa.

Neste projeto há 89 commits entre 25/09 e 28/09/2026. A lista está no próprio repositório
(no GitHub, no botão "commits"), e eu a usei como linha do tempo deste documento.

### Resumo da Parte 0

> Antes de existir o projeto, existem as ferramentas: o R (o idioma), o RStudio (a mesa),
> scripts (receitas), funções (sub-receitas), pacotes (ferramentas emprestadas) e o Git (o
> diário de bordo com fotos). O projeto é um armário de pastas onde essas coisas foram
> organizadas numa linha de montagem de oito etapas.

---

## Parte 1. O ponto de partida: a proposta e o que ela pedia

### O PDF de 23 de setembro

Tudo começa com um documento seu: o PDF da proposta apresentada no seminário da disciplina,
com data de 23/09/2026 no nome do arquivo. Ele pedia:

- uma análise da incidência de SRAG (Síndrome Respiratória Aguda Grave: o caso grave, em geral
  internado, de infecção respiratória) por três vírus, SARS-CoV-2, influenza e VSR, nos 92
  municípios do Rio de Janeiro, de 2022 a 2025;
- dados do SIVEP-Gripe (o sistema do Ministério da Saúde onde os hospitais registram cada
  caso de SRAG) e população do IBGE;
- mapas por município, uma estatística chamada Moran e outra chamada LISA (as duas serão
  explicadas na Parte 4), um painel interativo e um relatório;
- e uma organização de pastas específica: scripts numerados, uma pasta `R/` com funções, pastas
  de dados e de resultados.

Esse PDF é o que o projeto chama de **constituição**: onde o código e o PDF discordarem, o PDF
vence, a menos que exista uma decisão registrada explicando por que se desviou dele. O PDF
não está no repositório público, por decisão sua (registrada no BACKLOG como D-01; explico o
BACKLOG na Parte 7). Fica só na máquina do Patrick.

### A leitura crítica (25 de setembro, de manhã)

Antes de escrever qualquer código, o PDF foi lido linha a linha e conferido contra as fontes
oficiais. Essa leitura está no arquivo `docs/trilha-desenvolvimento.md` (o primeiro documento
criado; a pasta `docs/` nasce aqui, e é dela que falo na Parte 7). Ela encontrou cinco pontos
em que o PDF, se fosse seguido ao pé da letra, quebraria o trabalho sem avisar:

1. **O pacote `microdatasus` não baixa o SIVEP-Gripe.** O PDF dizia três vezes que a extração
   seria por ele. A documentação do pacote lista outros sistemas (SIH, SIM, SINASC...), não o
   SIVEP. Os bancos do SIVEP estão em outro canal, o Portal de Dados Abertos do SUS.
2. **Os nomes dos campos estavam diferentes do dicionário oficial.** O PDF escrevia
   `CO_MUNIC_RES` com sete dígitos; o campo real chama-se `CO_MUN_RES` e tem seis. Isso
   importa muito, e explico por quê na Parte 3.
3. **O IBGE não publicou estimativa de população para 2023** (ano em que divulgou o Censo).
   Sem população, não há taxa. Alguém teria de decidir o que fazer.
4. **O banco de 2025 é "vivo":** o Ministério o republica toda semana. Baixar hoje e baixar
   daqui a um mês dá mapas diferentes.
5. **"Por bairro"** aparecia numa seção, mas todo o desenho era por município.

Cada um desses pontos virou uma decisão formal, chamada **ADR** (do inglês *Architecture
Decision Record*, "registro de decisão"). Um ADR é um arquivo curto que diz: qual era o
problema, o que foi decidido, o que foi descartado e por quê. A pasta `docs/decisoes/` guarda
os sete ADRs do projeto. Você aceitou as decisões que eram suas em 25/09 (o commit `fd70ede`
registra esse aceite).

*Analogia:* um ADR é a ata de uma reunião em que se decidiu algo importante. Seis meses
depois, quando alguém perguntar "por que fizemos assim?", a ata responde.

### Resumo da Parte 1

> Havia um PDF com o desenho do estudo. Antes de programar, ele foi conferido contra as fontes
> e apareceram cinco pontos que quebrariam tudo em silêncio. Cada um virou uma decisão escrita
> (ADR), tomada por você. Só então o código começou, sabendo exatamente de onde os dados vêm
> e o que fazer nos pontos em que o PDF não podia ser seguido.

---

## Parte 2. A fundação: as pastas e as ferramentas (25 de setembro, primeiro commit `b66ae13`)

### Instalar o R e o Quarto

O primeiro item de trabalho (chamado CS-001; explico a numeração CS na Parte 7) foi instalar
o R versão 4.6.1 e o Quarto versão 1.10.18 na máquina, e conferir que os nove pacotes
principais carregavam. O registro disso está em `docs/release-history/cs-001-cs-002-fundacao.md`,
inclusive um erro no caminho: o instalador do R falhou pelo instalador automático do Windows e
teve de ser rodado à mão.

**Quarto** é um programa que transforma um arquivo de texto misturado com código em relatório
(HTML, Word, apresentação). Vou explicá-lo com calma na Parte 5.

### Criar a árvore de pastas

Em seguida foi criada a pasta do projeto com esta estrutura (a decisão está no
`docs/decisoes/ADR-0005-escopo-e-estrutura.md`, item 2: "árvore de diretórios idêntica à do
PDF, acrescida de `config/` e `docs/`. Nada do PDF foi renomeado"):

```
CartografiaESaude/
  00_setup.R … 07_exportacao.R     os scripts das etapas, numerados
  08_relatorio.qmd                 o relatório
  run.R                            o script que roda todos os outros em ordem
  app.R                            o painel interativo
  R/                               as funções (sub-receitas)
  config/                          endereços das fontes de dados
  dados/brutos/                    o que foi baixado, do jeito que veio
  dados/externos/                  arquivos pequenos de referência (IBGE, dicionário)
  dados/intermediarios/            meio do caminho
  dados/processados/               pronto para análise
  resultados/tabelas/              tabelas de resultado
  resultados/mapas/                mapas
  resultados/estatistica/          estatística espacial e gráficos
  resultados/objetos/              objetos do R (vizinhança, pesos)
  tests/                           testes automáticos
  docs/                            documentação e decisões
```

**Por que os scripts são numerados de 00 a 08?** O ADR-0005 (item 1) explica a escolha de
fundo: scripts numerados executados em ordem, e não uma ferramenta de orquestração (o pacote
`targets`, que só refaz o que mudou). Motivo registrado: "quem avalia é a banca da disciplina,
que precisa ler o fluxo em ordem sem aprender uma ferramenta". O custo aceito é refazer tudo a
cada execução, o que aqui leva uns quatro minutos. Quanto ao zero à esquerda (`01`, não `1`):
serve para a lista de arquivos aparecer na ordem certa em qualquer programa, porque `10` viria
antes de `2` numa ordenação por texto. Isso é uma inferência técnica provável; o ADR não fala
do zero.

**Por que separar `dados/` em quatro pastas?** Cada pasta é um estágio do pão: `brutos` é a
farinha como veio do moinho (nunca editada), `intermediarios` é a massa, `processados` é o pão
pronto para fatiar. `externos` guarda arquivos pequenos e públicos de referência (população do
IBGE, mapa, dicionário) que, ao contrário dos brutos, entram no Git. A diferença entre
`brutos` e `externos` está escrita em `config/fontes.yml` e no `.gitignore` (dois arquivos que
explico já abaixo): os brutos são grandes e contêm fichas individuais de pacientes; os
externos são pequenos e agregados.

### Os arquivos `.gitkeep`

Dentro de pastas como `dados/brutos/` você vai encontrar um arquivo vazio chamado `.gitkeep`.
O Git não fotografa pastas vazias, só arquivos. Para a pasta existir quando alguém clonar o
projeto, coloca-se dentro dela um arquivo vazio de nome combinado. É só isso: um peso de papel
para a gaveta não sumir. O nome não é uma regra do Git, é uma convenção entre programadores.

### O renv: a lista de compras exata

Aqui está o ponto que mais confunde quem chega. Vou com calma.

Cada pacote do R tem versões (1.0, 1.1, 2.0...). Duas pessoas podem ter o mesmo pacote em
versões diferentes, e uma função pode se comportar diferente entre versões. Se você rodasse o
projeto com versões diferentes das que Patrick usou, poderia obter números diferentes sem
ninguém saber por quê.

O **renv** é um pacote cujo trabalho é congelar isso. Ele deixa três coisas no projeto:

- **`renv.lock`**: um arquivo de texto que lista cada pacote usado com a versão exata e de onde
  baixar. Abra-o e vai ver, por exemplo, `"Package": "sf", "Version": "1.1.3"`. É a lista de
  compras com marca e tamanho de cada item.
- **`renv/activate.R`**: um script pequeno que "liga" o renv quando o R abre nesta pasta.
- **`renv/settings.json`**: as preferências do renv para este projeto.
- **`.Rprofile`**: um arquivo de uma linha só, `source("renv/activate.R")`. O R, ao abrir numa
  pasta, procura um arquivo com esse nome e executa o que está nele. É por isso que abrir o
  projeto pela pasta certa importa: é o `.Rprofile` que liga o renv.

Quando você roda `renv::restore()`, o renv lê o `renv.lock` e instala exatamente aquelas
versões numa biblioteca só deste projeto, a pasta `renv/library/`. Por isso a pasta cresce
depois: são os pacotes instalados. Eles não mexem nos pacotes que você já tinha para outros
trabalhos.

*Analogia:* o `renv.lock` é a foto da despensa no dia em que o bolo saiu perfeito, com marca e
peso de cada ingrediente. O `renv::restore()` é ir ao mercado com a foto na mão e comprar
exatamente aquilo.

**Se não existisse:** cada pessoa instalaria "a versão mais nova" de cada pacote, e o projeto
poderia dar números diferentes em máquinas diferentes, ou nem rodar. O registro
`cs-001-cs-002-fundacao.md` confirma que o `renv.lock` foi criado no primeiro dia com 140
pacotes.

### O `.gitignore`: o que o Git não deve fotografar

`.gitignore` é uma lista de arquivos e pastas que o Git deve ignorar. No projeto ele diz, com
comentários explicando cada linha:

- `dados/brutos/*`, `dados/intermediarios/*`, `dados/processados/*`: os dados de pacientes nunca
  vão para o Git (o comentário cita a LGPD, a lei de proteção de dados, e o fato de os
  processados serem regeneráveis pelo pipeline).
- `resultados/mapas/*`, `resultados/objetos/*`, os HTML do relatório: saídas que o pipeline
  refaz; não faz sentido guardar o histórico delas.
- `renv/library/`: os pacotes instalados (grandes e refeitos pelo `renv::restore()`).
- `/23092026_*.pdf`: o PDF da sua proposta, por sua decisão.

**Se não existisse:** o repositório público no GitHub conteria as fichas do SIVEP e ficaria
enorme; e cada execução do pipeline apareceria como "mudança" no histórico.

### O `.gitattributes`: uma cicatriz

Esse arquivo diz ao Git como tratar quebras de linha e arquivos binários. Ele tem uma linha
que diz que tudo em `dados/externos/` é binário, com um comentário explicando por quê: esses
arquivos são conferidos por uma "impressão digital" (explico na Parte 3), e o Git, se pudesse
mexer nas quebras de linha ao copiar, mudaria a impressão digital e a conferência falharia em
outra máquina. Isso aconteceu de verdade no item CS-011 e foi corrigido aqui. O projeto chama
esse tipo de regra nascida de um erro real de **cicatriz**.

### `00_setup.R`: o "bom dia" de todos os scripts

É o menor script do projeto. Ele faz duas coisas: carrega todas as funções da pasta `R/` e
cria as pastas de dados e resultados se não existirem. Todo script numerado começa com a
linha `source("00_setup.R")`, que significa "execute o 00_setup antes de mim".

A intenção do código é: "pegue cada arquivo da pasta `R/` cujo nome começa com `funcoes_` e
carregue-o". O trecho central:

```r
for (arquivo in list.files("R", pattern = "^funcoes_.*\\.R$", full.names = TRUE)) {
  source(arquivo, encoding = "UTF-8", local = TRUE)
}
```

`list.files("R", ...)` lista os arquivos da pasta `R` que casam com o padrão "começa com
`funcoes_` e termina em `.R`"; `for (arquivo in ...)` repete o bloco para cada um; `source()`
lê e executa o arquivo, que só define funções (não calcula nada). Depois disso, o script que
chamou o `00_setup.R` pode usar qualquer função do projeto.

**Se não existisse:** cada script teria de listar as funções que precisa, e uma função nova
teria de ser acrescentada em oito lugares.

### `run.R`, `README.md` e os testes

Já no esqueleto existiam `run.R` (o script que executa os outros em ordem; ganhou corpo no
item CS-023 e volto a ele na Parte 4), `README.md` (a "capa" do repositório, que o GitHub
mostra na página inicial) e a pasta `tests/testthat/` com cinco testes do esqueleto (Parte 6).

O primeiro commit, `b66ae13`, tinha 44 arquivos. O registro diz o que ele **não** tinha:
nenhum arquivo de `renv/library/` nem de `dados/brutos/`. Ou seja, a regra "dado de paciente
não entra no Git" valeu desde a primeira foto.

### Resumo da Parte 2

> No primeiro dia, a pessoa instalou o R e o Quarto, criou o armário de pastas exatamente
> como o PDF desenhava (mais `config/` e `docs/`), congelou a lista de pacotes com o renv para
> que qualquer máquina reproduzisse o mesmo ambiente, e escreveu no `.gitignore` que dados
> de pacientes nunca entram no histórico. Deixou um script de "bom dia" (`00_setup.R`) que
> carrega todas as funções, para que cada etapa seguinte começasse com a caixa de ferramentas
> aberta.

---

## Parte 3. De onde vêm os dados, e como sabemos que são sempre os mesmos

Esta parte cobre os itens CS-003 e CS-004 (commit `5f09f23`), feitos logo depois da
fundação e antes de qualquer dado ser baixado. A ordem não é acaso: primeiro se decide
**como registrar** o que vai ser baixado; só depois se baixa.

### `config/fontes.yml`: os endereços, fora do código

**O que é.** Um arquivo de texto no formato **YAML** (extensão `.yml`). YAML é um jeito de
escrever configurações como "nome: valor", com recuos para agrupar. Um pedaço real do arquivo:

```yaml
sivep:
  bancos:
    - ano: 2022
      url: https://s3.sa-east-1.amazonaws.com/ckan.saude.gov.br/SRAG/2022/INFLUD22-23-03-2026.parquet
      versao: "23-03-2026"
```

Leia: "na seção `sivep`, na lista `bancos`, há um item cujo `ano` é 2022, cujo endereço na
internet (`url`) é este, e cuja `versao` é a de 23/03/2026".

**O que tem dentro.** O endereço de cada arquivo que o projeto baixa: os quatro bancos anuais
do SIVEP-Gripe, o dicionário oficial dos campos, as tabelas de população do IBGE (uma por
ano), a tabela do Censo por idade, o mapa dos municípios, a tabela de regiões de saúde, os
arquivos de leitos hospitalares do CNES, e as datas de início das campanhas de vacinação
contra gripe. Para cada um, a data da versão e uma descrição. Há também uma lista de versões
antigas do banco de 2025, usadas só para medir quanto os números mudam com o tempo (item
CS-048).

**Por que existe, e por que fora do código.** O comentário no topo do próprio arquivo diz:
"URLs ficam aqui, não no código: o portal já mudou de endereço uma vez". Se o Ministério
mudar o endereço de novo, corrige-se uma linha neste arquivo, sem tocar em nenhum script.

**Por que o formato YAML.** O repositório não registra a comparação com outros formatos. O que
posso dizer: YAML é legível por uma pessoa sem treino, aceita comentários explicativos (as
linhas que começam com `#`), e o R tem um pacote (`yaml`) que o lê direto. Isso é uma
inferência técnica provável.

**Quem usa depois.** A função `ler_fontes()` (em `R/funcoes_utilitarias.R`) lê este arquivo, e
toda função que baixa algo pergunta a ela onde buscar.

**Se não existisse:** cada endereço estaria escrito dentro de algum script, e uma mudança de
endereço exigiria caçar em oito arquivos.

*Analogia:* a agenda de contatos. O nome do fornecedor fica no cadastro, não escrito à mão em
cada pedido.

### `dados/MANIFESTO.md`: a impressão digital de cada arquivo baixado

Lembre o problema 4 da Parte 1: o banco de 2025 muda toda semana. E, descobriu-se ao
implementar (está no `ADR-0001`), até os bancos "congelados" de 2022 a 2024 foram republicados
em 23/03/2026. Como garantir que a análise de hoje e a de daqui a um ano usam o **mesmo
arquivo**?

A resposta é o **manifesto de proveniência**. "Proveniência" é a origem documentada de algo.
O manifesto é uma tabela, no arquivo `dados/MANIFESTO.md`, com uma linha por arquivo baixado:
caminho, endereço de origem, data e hora do download, tamanho em bytes, e o **SHA-256**.

**SHA-256** é uma impressão digital calculada sobre o conteúdo do arquivo: 64 letras e
números. Dois arquivos com conteúdo idêntico têm a mesma impressão; se um único byte mudar, a
impressão muda por completo. Não dá para "consertar" um arquivo para ter uma impressão
escolhida.

*Analogia:* o lacre numerado de um malote. Quem recebe confere o número do lacre com o que foi
anotado na saída. Se o número bate, ninguém abriu no caminho.

**Por que em Markdown (`.md`).** O comentário no código que o gera diz: "uma tabela Markdown
escrita e relida por estas funções: legível por gente no GitHub e verificável por código".
Ou seja, o mesmo arquivo serve para uma pessoa olhar (o GitHub mostra a tabela formatada) e
para o R conferir.

**Quem escreve e quem lê.** Três funções em `R/funcoes_utilitarias.R`:

- `registrar_fonte()`: acrescenta a linha de um arquivo recém-baixado. Se o arquivo já está
  registrado com a mesma impressão, não faz nada. Se está registrado com **outra** impressão,
  **para com erro**, a menos que a pessoa diga explicitamente "sim, quero substituir". O
  comentário explica: "rebaixar muda o conteúdo, e isso precisa ser uma decisão explícita, não
  um acidente".
- `verificar_manifesto()`: recalcula a impressão de cada arquivo no disco e compara com a
  tabela. Qualquer diferença para tudo. Também exige que **todo** arquivo em `dados/brutos/`
  esteja registrado: um arquivo que alguém colocou lá à mão não é aceito.
- `baixar_e_registrar()`: junta as duas. A intenção é: "se o arquivo já está no disco e
  confere, não baixe de novo; se não está, baixe e registre". Assim, a segunda execução do
  pipeline não baixa nada.

O trecho central de `baixar_e_registrar()`:

```r
if (file.exists(destino)) {
  m <- ler_manifesto(manifesto)
  if (caminho_relativo(destino) %in% m$arquivo) {
    verificar_manifesto(destino, manifesto = manifesto)
    message("Em cache e conferido: ", destino)
    return(invisible(destino))
  }
}
baixar_arquivo(url, destino)
registrar_fonte(destino, url = url, descricao = descricao, versao = versao, manifesto = manifesto)
```

Em palavras: se o arquivo existe **e** está na tabela, confere a impressão e avisa "em cache
e conferido" (cache = cópia local guardada para não buscar de novo); senão, baixa e registra.

Um detalhe do `baixar_arquivo()`: se a internet cair no meio, os bytes já baixados ficam num
arquivo `.parcial`, e a próxima tentativa pede ao servidor só o restante. Há até um cuidado
para o caso de o servidor ignorar o pedido e mandar tudo de novo (o que corromperia o arquivo
por colar o todo depois da parte).

**Se não existisse:** dois "mesmos" downloads poderiam ser arquivos diferentes, e ninguém
saberia. O relatório não poderia dizer "banco de 2025, versão de 14/09/2026" com segurança.

### `dados/externos/` versus `dados/brutos/`

Os dois guardam coisas baixadas e registradas no manifesto. A diferença é o que entra no Git:

- `dados/externos/` (entra no Git): o dicionário do SIVEP (PDF, 1 MB), o mapa dos municípios
  (5 MB), cinco arquivos de população do IBGE (25 KB cada). Pequenos, públicos, agregados.
- `dados/brutos/` (não entra): os quatro bancos do SIVEP (22 a 44 MB cada, com fichas
  individuais), a tabela de regiões de saúde (21 MB, cobre o Brasil inteiro) e os arquivos de
  leitos do CNES (25 MB cada). Grandes, e o primeiro grupo é dado de pacientes.

O comentário em `config/fontes.yml` sobre as regiões diz exatamente isso: "o arquivo cobre o
Brasil inteiro (21 MB), por isso fica em dados/brutos, fora do git".

### `docs/dicionario-sivep.md` e o dicionário oficial em PDF

O item CS-004 baixou o **dicionário de dados** oficial do SIVEP-Gripe (o documento do
Ministério que explica cada campo da ficha) e o registrou no manifesto. A partir dele foi
escrito `docs/dicionario-sivep.md`: a lista dos 37 campos que o projeto usa, dos 194 que cada
banco tem, com o significado e os valores possíveis de cada um. Está lá também a confirmação
de que os quatro bancos têm as mesmas 194 colunas com os mesmos nomes.

Foi conferindo o dicionário que se descobriu o problema 2 da Parte 1, e ele merece o exemplo
mais importante deste documento, porque é o tipo de erro que não avisa.

**O código do município tem 6 dígitos no SIVEP e 7 no IBGE.** O sétimo dígito do IBGE é um
"dígito verificador", como o do CPF. Se você tenta juntar a tabela de casos (com 6 dígitos) à
tabela de população (com 7), o computador procura "330455" numa lista que tem "3304557",
não acha nada, e devolve uma tabela **vazia, sem erro**. Ele não sabe que você esperava 92
municípios. A decisão (registrada no `ADR-0007`) foi: em todas as tabelas do projeto, a chave
de junção é `cod6`, os seis primeiros dígitos, guardados **como texto**. Por que texto, e não
número? Porque um código como `330010`, lido como número, vira `330010` sem problema, mas
`0330010` perderia o zero; e, mais importante, guardar como texto impede que alguém some ou
tire média de códigos por engano. Há uma função, `validar_codigos_ibge()`, que para o pipeline
se algum código não tiver seis dígitos como texto começando por 33 (o prefixo do RJ).

*Analogia:* CEP. "01001-000" e "1001000" são o "mesmo" CEP para uma pessoa, mas um sistema
que compara texto não acha um no lugar do outro. E ninguém quer somar dois CEPs.

### Resumo da Parte 3

> Antes de baixar um único dado, a pessoa criou dois mecanismos: uma agenda de endereços
> (`config/fontes.yml`), para que nenhum endereço ficasse escondido no código, e um livro de
> lacres (`dados/MANIFESTO.md`), em que cada arquivo baixado fica registrado com sua
> impressão digital. Com isso, qualquer execução futura pode provar que usou exatamente os
> mesmos arquivos. E, lendo o dicionário oficial, descobriu que o código de município precisa
> ter seis dígitos como texto, uma regra que passou a valer em toda tabela do projeto.

---

## Parte 4. A linha de montagem, etapa por etapa

Agora os scripts numerados. Antes de cada um, três regras que valem para todos:

1. **Todo script começa com `source("00_setup.R")`** e, portanto, com todas as funções
   carregadas e as pastas criadas.
2. **Cada script lê arquivos que o anterior gravou e grava arquivos para o seguinte.** Nenhum
   dado passa "pela memória" de um script para outro; tudo passa pelo disco. Por isso dá para
   rodar um script isolado, desde que os anteriores já tenham rodado.
3. **Quando algo não bate, o script para com uma mensagem, em vez de seguir com um número
   errado.** Em R isso se faz com `stop("mensagem")`. O projeto chama isso de *fail-closed*
   ("falha fechada"): na dúvida, para. A alternativa, corrigir em silêncio ou usar um valor
   padrão, é proibida (regra 7 do `CLAUDE.md`, invariante 7 da trilha).

*Analogia para a regra 3:* o disjuntor da casa. Quando há sobrecarga, ele desarma e você vai
olhar; ele não "dá um jeito" e deixa o fio esquentar.

**Sobre os formatos de arquivo entre etapas.** Três aparecem o tempo todo:

- **`.parquet`** para tabelas grandes. É um formato em que os dados ficam organizados por
  coluna, não por linha. Se você precisa de 37 colunas de 194, ele lê só as 37 sem abrir as
  outras. Também guarda o tipo de cada coluna (data é data, número é número), o que o CSV não
  faz. O `ADR-0001` registra a escolha e os tamanhos: o banco de 2022 tem 43,8 MB em PARQUET.
  *Analogia:* um fichário com uma gaveta por coluna, em vez de uma lista corrida em que você
  precisa ler cada linha inteira para achar um campo.
- **`.rds`** para objetos que não são tabelas simples, como o mapa (que tem geometria) e a
  lista de vizinhos. O `.rds` guarda o objeto do R exatamente como ele está na memória, e só o
  R lê. A trilha (§3.1) registra que o PDF já previa `.parquet` para tabelas e `.rds` para
  esses objetos. *Analogia:* um vidro de conserva: guarda a coisa inteira, do jeito que estava.
- **`.csv`** para as tabelas de resultado que uma pessoa vai querer abrir. É texto puro,
  abre no Excel e em qualquer editor. Guardar as tabelas de `resultados/tabelas/` em CSV para
  serem legíveis fora do R é uma inferência técnica provável (o repositório registra o motivo
  só para as tabelas de exportação, na etapa 07).

### Etapa 01. `01_etl_sivep.R`: baixar, limpar e classificar as fichas

**ETL** é uma sigla comum em dados: *Extract, Transform, Load*, extrair, transformar,
carregar. É a etapa que pega o dado bruto e o deixa utilizável.

**O que lê.** `config/fontes.yml` (os endereços) e `dados/MANIFESTO.md`.

**O que faz, na ordem.**

*Baixa.* `baixar_sivep()` baixa os quatro bancos anuais, um por ano, para `dados/brutos/`, e
registra cada um no manifesto. A segunda vez, não baixa.

*Filtra e tipa.* `preparar_sivep()` abre cada banco e fica só com as fichas de **residentes do
RJ**: as em que `CO_MUN_RES` começa com "33". Lê só as colunas usadas, e o filtro é feito antes
de trazer o dado para a memória (o pacote `arrow` faz isso no disco). Converte as colunas para
o tipo certo: datas como datas, códigos como números inteiros. Aqui há uma armadilha
registrada no `ADR-0001`: as datas vêm do Ministério marcadas como "meia-noite no horário de
Londres" (UTC). Lidas no horário de Brasília, viram 21h do dia **anterior**, e a semana
epidemiológica sairia errada em cerca de 14 % das fichas. A conversão certa é "leia como UTC",
e o projeto confirmou: assim a semana calculada bate com a do Ministério em 100 % das fichas
de 2022 a 2024.

*Calcula a semana epidemiológica.* A vigilância conta o tempo em semanas que vão de domingo a
sábado, e o "ano epidemiológico" pode ter 53 semanas. O projeto calcula a semana a partir da
data de início dos sintomas com a função `semana_epidemiologica()`, e não usa a coluna
`SEM_PRI` que vem no banco, porque descobriu que no banco de 2025 ela está errada em 226
fichas (marca como semana 1 de 2026 o que é semana 53 de 2025). O resultado desta fase é
gravado em `dados/intermediarios/sivep_rj.parquet`: uma linha por ficha de residente do RJ,
99.880 fichas nos quatro anos.

*Diagnostica sem corrigir.* `diagnosticar_sivep()` conta, por ano, as anomalias (datas vazias,
fichas sem classificação final etc.) e grava `resultados/tabelas/diagnostico_sivep.csv`. Conta;
não conserta.

*Classifica por vírus.* Este é o coração da etapa e o objeto do `ADR-0002`. A pergunta é: quando
uma ficha "é um caso de SARS-CoV-2"? A ficha tem uma classificação final (`CLASSI_FIN`: 5 =
covid, 1 = influenza, 2 = outro vírus respiratório) e vários campos de laboratório (o vírus foi
detectado no exame PCR? no teste de antígeno?). O PDF pedia "classificação final **e** campo
do vírus marcado". Testada nos dados, essa regra perdia 27 % dos casos de covid de 2022 e 5 %
dos de 2025, só porque o campo do vírus ficava em branco em muitas fichas encerradas por
critério laboratorial. Como o preenchimento melhorou com os anos, a regra literal fabricaria
uma queda artificial. Cinco regras foram escritas em código e comparadas (a tabela está em
`resultados/tabelas/comparacao_regras_caso.csv`); você escolheu a R2, "vigilância":
classificação final do vírus **e** (encerramento por critério laboratorial **ou** campo do vírus
marcado).

A intenção do código das regras é: "para cada regra, dizer, ficha a ficha, se ela é caso de
cada vírus". O trecho da regra escolhida, em `R/funcoes_sivep.R`:

```r
R2_vigilancia = list(
  descricao = "Classificação final do agente E (critério de encerramento laboratorial OU campo específico marcado)",
  fn = function(s) list(
    sarscov2  = s$cf_covid     & (s$criterio_lab | s$esp_sarscov2),
    influenza = s$cf_influenza & (s$criterio_lab | s$esp_influenza),
    vsr       = s$cf_outro_virus & s$esp_vsr))
```

`s` é um conjunto de "sinais" já calculados para cada ficha (verdadeiro ou falso): `cf_covid`
= a classificação final é covid; `criterio_lab` = o encerramento foi por laboratório;
`esp_sarscov2` = o campo específico do SARS-CoV-2 está marcado. O `&` é "e", o `|` é "ou". A
linha do VSR é diferente porque o VSR não tem código próprio na classificação final: cai em
"outro vírus respiratório", e só o campo específico diz que é VSR.

Cada ficha vai para **um único** vírus (o da classificação final); quando o exame detectou um
segundo vírus, isso é anotado numa coluna `codeteccao` e reportado, não contado duas vezes.
Uma trava no código para se alguma regra marcar a mesma ficha em dois vírus.

O resultado: `dados/processados/sivep_processado.parquet`, com 37.562 casos (24.087 de
SARS-CoV-2, 5.536 de influenza, 7.939 de VSR, pela tabela em
`docs/release-history/cs-008-cs-010-classificacao.md`). O script confere que a contagem por
vírus e ano é **idêntica** à linha da regra R2 na tabela do ADR; se divergir, para.

*Mede outras coisas de passagem.* Grava também: as fichas notificadas no RJ de quem mora fora
(para a comparação residência × notificação, CS-031); as fichas ainda não encerradas por ano
e por semana (CS-035); e a comparação entre versões do banco de 2025 (CS-048), que responde à
sua pergunta sobre quanto os números mudam depois do fim do ano.

**Se não existisse:** nada. É a primeira estação da linha.

### Etapa 02. `02_indicadores.R`: população, casos e taxas

**O que lê.** `sivep_processado.parquet` (da etapa 01) e as tabelas de população do IBGE, que
esta etapa baixa.

**População.** `obter_populacao()` baixa da **API SIDRA** do IBGE (uma "API" é um endereço da
internet que, em vez de uma página para ler, devolve dados para um programa) as tabelas de
população por município: Censo 2022, estimativas de 2024 e 2025. A resposta vem em **JSON**
(outro formato de texto para dados, parecido com YAML no propósito) e é guardada como veio em
`dados/externos/`, registrada no manifesto. Para 2023, que o IBGE não publicou, a decisão do
`ADR-0003` (sua, D-05) foi interpolar em linha reta entre o Censo (1º de agosto de 2022) e a
estimativa de 2024 (1º de julho de 2024), lendo o valor em 1º de julho de 2023. O ADR
registrou um fato que motivou uma segunda decisão: a estimativa de 2024 supera o Censo em
todos os 92 municípios, de 3,1 % a 8,4 %, porque o IBGE corrige a subenumeração do Censo. Por
isso o projeto calcula **duas** taxas: uma com a população do próprio ano (para o mapa de
cada ano) e outra com a estimativa de 2024 em todos os anos (para comparar anos sem esse
degrau). O resultado é `dados/processados/populacao_rj.parquet`: 92 municípios × 4 anos.

**Casos e taxa.** `calcular_casos()` conta as fichas por município, vírus e ano.
`completar_municipios()` faz algo que parece bobo e é uma regra do projeto (invariante 3, "zero
explícito"): garante que **toda** combinação município × vírus × ano apareça, com zero onde
não houve caso. Sem isso, um município sem caso simplesmente não estaria na tabela, e uma
junção com o mapa o deixaria em branco sem aviso. *Analogia:* chamada de presença. O aluno
que faltou é registrado como "faltou", não apagado da lista. `calcular_incidencia()` divide
casos por população e multiplica por 100 mil.

O script então confere o **contrato** da tabela: 92 × 3 × 4 = 1.104 linhas, nenhum valor
vazio, e a soma dos casos igual ao número de fichas classificadas. O trecho:

```r
if (nrow(anual) != esperado_anual) stop("Grade anual com ", nrow(anual), " linhas; esperado ", esperado_anual)
if (anyNA(anual[, c("casos", "incid_100k", "incid_100k_pop2024", "incid_pad_100k")])) stop("NA na grade anual")
if (sum(anual$casos) != nrow(casos) || sum(quadrimestral$casos) != nrow(casos)) {
  stop("A soma da grade difere do número de casos classificados", call. = FALSE)
}
```

Leia: "se o número de linhas não for o esperado, pare; se houver célula vazia (`NA`), pare; se
a soma dos casos na grade não for igual ao número de casos que entraram, pare".

**Suavização de Bayes empírico (EB).** Municípios pequenos têm taxas instáveis: um caso a mais
em Macuco (5 mil habitantes) muda a taxa em 20 por 100 mil; na capital, não muda nada. A
suavização puxa a taxa dos municípios pequenos em direção à média do estado, tanto mais quanto
menor a população, e quase não mexe nos grandes. Você decidiu (D-09) que a estatística
espacial roda sobre a taxa suavizada. A função `suavizar_bayes_empirico()` grava a coluna
`incid_eb_100k`, e a nota `docs/nota-metodologica-suavizacao.md` explica o método com os
números do projeto. *Analogia:* a nota de um aluno que fez só uma prova é menos confiável que a
de quem fez dez; o professor prudente "puxa" a nota do primeiro para a média da turma até ter
mais provas.

**Padronização por idade** (CS-033): responde "qual seria a taxa do município se ele tivesse a
estrutura etária do estado?", porque VSR adoece bebês e SARS-CoV-2 adoece idosos. Está em
`docs/nota-metodologica-padronizacao.md` e produz a coluna `incid_pad_100k`.

**Saídas.** `dados/processados/indicadores_municipais.parquet` (a tabela central do projeto:
1.104 linhas com casos, população, e quatro taxas) e várias tabelas em `resultados/tabelas/`.

**Se não existisse:** não haveria taxa, só contagem, e contagem não se compara entre
municípios de 5 mil e de 6 milhões de habitantes.

### Etapa 03. `03_cartografia.R`: o mapa

**O que lê.** O arquivo `dados/externos/RJ_Municipios_2022.zip` (que esta etapa baixa do IBGE)
e `populacao_rj.parquet`.

**Shapefile e sistema de coordenadas.** O IBGE distribui o desenho dos municípios num formato
chamado **shapefile**, um conjunto de arquivos dentro de um `.zip`, em que cada município é um
**polígono** (uma lista de pontos ligados que fecham a forma). Cada ponto tem latitude e
longitude num **sistema de referência de coordenadas**: aqui, o SIRGAS 2000, o sistema oficial
brasileiro, cujo código internacional é EPSG:4674. A função `ler_malha_municipal()` lê o zip
direto e devolve um objeto do pacote `sf` (a tabela com uma coluna de geometria), com o
código de sete dígitos, o `cod6` de seis, o nome e a área de cada município. Ela **para** se
não houver exatamente 92 municípios.

**Por que a malha oficial e não a do `geobr`.** O PDF pedia o pacote `geobr`, que entrega uma
versão simplificada do mapa (linhas com menos pontos, arquivo menor). O `ADR-0006` registra o
que se descobriu: a simplificação apaga trechos de fronteira, e 8 pares de municípios que se
tocam no mapa oficial deixam de se tocar no simplificado. Como a etapa 04 depende de quem toca
quem, isso mudaria a análise. Ficou a malha oficial, em resolução completa.

**A conferência da chave.** O script confere que os 92 códigos do mapa casam com os 92 da
população. É o teste que o problema dos 6 versus 7 dígitos exigia.

**Regiões de saúde** (CS-030). Baixa a tabela "município → região de saúde" (9 regiões do RJ,
divisão do Ministério da Saúde), e cria o mapa das regiões **dissolvendo** o mapa municipal:
juntando os polígonos dos municípios de cada região num só. Assim as fronteiras regionais são
exatamente a soma das municipais. Um detalhe registrado no código: os nomes das regiões vêm
com acentos corrompidos na fonte ("Baixada Litorã¢Nea"), então o projeto usa o código da
região como chave e escreve os nomes ele mesmo.

**Leitos hospitalares** (CS-034). Baixa os arquivos anuais do CNES (o cadastro nacional de
estabelecimentos de saúde) e conta leitos SUS e leitos de UTI por município em julho de cada
ano. Aqui a junção é por **nome** do município, porque os arquivos de 2022 a 2024 não trazem o
código; dois municípios tinham grafia diferente e ganharam um "apelido" no código.

**Saídas.** `dados/processados/municipios_rj.rds` (o mapa), `regioes_saude_rj.rds`,
`municipio_regiao.parquet`, `indicadores_regionais.parquet` (casos e taxas por região) e
`leitos_rj.parquet`.

**Se não existisse:** sem mapa não há vizinhança (etapa 04), nem estatística espacial (05),
nem desenho (06).

### Resumo das etapas 01 a 03

> A linha de montagem começa baixando as fichas do SIVEP e ficando só com quem mora no RJ.
> Cada ficha é classificada em um vírus por uma regra que você escolheu depois de ver cinco
> alternativas testadas nos dados. Vem então a população do IBGE, com o ano de 2023
> interpolado porque o IBGE não o publicou, e cada município ganha sua taxa por 100 mil, com
> zero escrito onde não houve caso. Por fim entra o mapa oficial do IBGE, escolhido em vez do
> simplificado porque a simplificação apagava fronteiras. Cada etapa grava seus arquivos no
> disco e confere os próprios números antes de passar o bastão.

### Etapa 04. `04_pesos_espaciais.R`: quem é vizinho de quem

**O que lê.** `municipios_rj.rds` (o mapa da etapa 03).

**Vizinhança Queen.** Para a estatística espacial, é preciso dizer quais municípios são
vizinhos. O critério usado, chamado **Queen** (rainha), é o do xadrez: dois municípios são
vizinhos se suas fronteiras se tocam em qualquer ponto, mesmo que só num canto (a rainha do
xadrez se move em qualquer direção, inclusive na diagonal). O critério alternativo, **Rook**
(torre), exigiria um trecho de fronteira em comum, não só um ponto. A função
`criar_vizinhos_queen()` calcula isso e **para** se algum município ficar sem vizinho ou se o
estado se dividir em dois blocos desconectados, porque nesses casos a estatística seguinte
fica mal definida.

**Os 456.** No RJ, com a malha oficial, há 456 ligações (cada par de vizinhos conta duas
vezes, uma em cada direção). O script confere esse número, e o comentário diz por quê:

```r
ligacoes <- contar_ligacoes(vizinhos)
if (ligacoes != 456) {
  stop("Vizinhança com ", ligacoes, " ligações; esperado 456 (ADR-0006)", call. = FALSE)
}
```

Com a malha simplificada seriam 440. Se alguém trocar o mapa sem querer, este número denuncia.

**Pesos.** `criar_pesos()` transforma a lista de vizinhos numa **matriz de pesos**: cada
município reparte o peso 1 igualmente entre seus vizinhos (o "estilo W"). Com isso, "a média
dos vizinhos" de um município é a média simples das taxas deles. Um detalhe que o comentário do
código destaca: o `cod6` de cada município vai gravado dentro do objeto de vizinhança, para que
os dados sejam alinhados **pela chave**, nunca pela posição na lista. Alinhar pela posição é o
erro silencioso clássico: basta uma tabela estar em ordem diferente para o município A receber
os vizinhos do B.

**Saídas.** `resultados/objetos/vizinhos_queen.rds`, `pesos_queen.rds` (formato `.rds` porque
são objetos do pacote `spdep`, não tabelas), uma tabela com o número de vizinhos de cada
município, um histograma (gráfico de barras da distribuição), e os pesos entre as 9 regiões,
conferidos contra os municipais: duas regiões são vizinhas se, e só se, algum município de uma
toca algum da outra.

**Se não existisse:** o Moran e o LISA não têm como saber o que é "perto".

### Etapa 05. `05_moran_lisa.R`: a estatística espacial

**O que lê.** `indicadores_municipais.parquet` (etapa 02), o mapa (03) e os pesos (04).

**A pergunta.** "Municípios com taxa alta tendem a ter vizinhos com taxa alta?" Se sim, há
**autocorrelação espacial positiva**: o valor de um lugar se parece com o dos lugares ao
redor. *Analogia:* "diga-me com quem andas". Se os preços dos imóveis de uma rua se parecem
com os das ruas vizinhas, há autocorrelação espacial nos preços.

**Moran global.** O **I de Moran** é um número único para o estado inteiro, por vírus e ano
(12 combinações), que mede essa semelhança entre vizinhos. Vai de valores negativos (vizinhos
opostos) a positivos (vizinhos parecidos), com zero significando "sem padrão". Para saber se
o valor obtido é maior do que o acaso produziria, usa-se **permutação**: embaralham-se as taxas
entre os municípios 9.999 vezes, calcula-se o I em cada embaralhada, e vê-se em que fração
delas o I saiu tão alto quanto o real. Essa fração é o **valor p**. *Analogia:* para saber se
um baralho está viciado, embaralhe-o milhares de vezes e veja com que frequência a mão boa
aparece por sorte.

**Semente fixa.** Embaralhar é aleatório, e resultado aleatório mudaria a cada execução. O
projeto fixa uma **semente** (o número `SEMENTE <- 20260925`, a data do primeiro dia), que faz
o "aleatório" do computador seguir sempre a mesma sequência. Assim o valor p de hoje é o
mesmo de amanhã. É a regra 5 dos invariantes.

**Por que 9.999 permutações e não as 999 habituais.** O `ADR-0004` e a seção "Decisões de
método" do relatório explicam: com 999 embaralhadas, o menor valor p possível é 1/1000, que é
maior do que o limiar mais exigente da correção descrita abaixo; a correção seria decidida pela
resolução da simulação, não pelos dados.

**LISA.** O Moran global diz "há padrão no estado". O **LISA** (*Local Indicator of Spatial
Association*) diz **onde**: calcula um I para cada município, comparando o município com seus
vizinhos, e o classifica em quatro tipos: **Alto-Alto** (taxa alta cercado de altas: um
agrupamento, ou *hotspot*), **Baixo-Baixo** (baixo entre baixos), **Alto-Baixo** e
**Baixo-Alto** (os discrepantes). Cada município ganha também um valor p por permutação.

**Correção para testes múltiplos (FDR).** São 92 testes por mapa. Com um limiar de 5 %, espera-se
que cerca de 4,6 municípios "deem significativo" por puro acaso mesmo sem nenhum padrão. A
correção de **Benjamini-Hochberg**, ou **FDR** (*false discovery rate*, taxa de descobertas
falsas), ajusta os valores p para levar isso em conta. O projeto mostra os dois níveis:
**confirmado** (significativo depois da correção) e **indicativo** (significativo só antes).
*Analogia:* se 92 pessoas jogam na loteria, alguém "ganha" só pelo número de tentativas. A
correção pergunta se o ganho é mais do que o esperado por tentar tanto.

**Instáveis.** Municípios com um único vizinho (há dois no RJ) ficam com a classe marcada como
instável, porque a "média dos vizinhos" deles é o valor de um só município.

**Sensibilidades.** O script roda tudo três vezes: a principal (taxa suavizada, vizinhança
Queen), e duas alternativas (taxa bruta; vizinhança Rook), para mostrar que a conclusão não
depende de uma escolha só. Faz também o Moran global entre as 9 regiões (só descritivo, com 9
unidades o teste tem pouco poder), a correlação entre taxa e leitos (CS-034), e um diagnóstico
dos municípios com zero caso (CS-041).

**Saídas.** `resultados/estatistica/moran_lisa.rds` (tudo, para o relatório e o painel) e
tabelas CSV: `moran_global.csv`, `lisa_municipios.csv` (92 × 12 linhas), `lisa_resumo.csv`,
`lisa_concordancia.csv`, `moran_regional.csv`, `spearman_leitos.csv`, `zeros_diagnostico.csv`.

**Se não existisse:** o projeto teria mapas de taxa, mas não a resposta à pergunta do PDF:
onde estão os agrupamentos, e eles são mais do que o acaso.

### Etapa 06. `06_visualizacoes.R`: desenhar

**O que lê.** O mapa, os indicadores, o LISA, as regiões, a série de casos por semana, os leitos.

**O que faz.** Desenha, com o pacote `ggplot2`, 45 mapas em `resultados/mapas/` e 19 gráficos
em `resultados/estatistica/`, todos em PNG (mapas a 300 pontos por polegada, a resolução de
impressão). Os mapas: incidência por vírus e ano (12), LISA por vírus e ano (12), dois painéis
3 × 4 (todos os vírus e anos numa figura), seis painéis por vírus (4 anos em 2 × 2), doze mapas
por região de saúde e o mapa de referência das regiões, todos com o contorno do estado. Os
gráficos: séries de casos por semana (estado e cada região), fichas não encerradas, taxa
bruta contra suavizada, bruta contra padronizada, leitos contra taxa, versões do banco, e o
guia de cores.

**As cores num lugar só.** Todas as cores do projeto estão definidas em `R/funcoes_mapas.R`, e
em nenhum outro arquivo. Um teste procura cor escrita à mão fora dali e falha se achar. Foi
isso que permitiu trocar a cor do SARS-CoV-2 para azul e a da influenza para amarelo (seus
pedidos, CS-054 e CS-058) mudando duas linhas. As cores foram conferidas com um validador de
daltonismo, e o resultado está no comentário do próprio arquivo.

**Se não existisse:** os números existiriam nas tabelas, mas ninguém os veria no mapa.

### Etapa 07. `07_exportacao.R`: entregar para pessoas

**O que lê.** As tabelas das etapas anteriores.

**O que faz.** Monta 14 tabelas com nomes de colunas em português legível ("taxa_bruta_100mil"
em vez de "incid_100k") e as grava em `resultados/tabelas/exportacao/` em CSV **para o Excel
brasileiro**: separador ponto e vírgula, vírgula decimal. Há um detalhe registrado no
comentário de `salvar_resultado()`: o arquivo começa com três bytes invisíveis (o "BOM") que
avisam ao Excel que o texto está em UTF-8; sem eles, "Niterói" abre como "NiterÃ³i". O script
relê cada CSV e confere o número de linhas e a presença de "Niterói" com acento.

Gera também, pelo pandoc (o conversor de documentos que vem com o Quarto), `tabelas_abnt.docx`,
as mesmas 14 tabelas em Word no padrão ABNT (CS-051), e `resultados/documentos/proposta-v2.docx`,
a proposta revisada em Word (CS-057). Em ambos o script confere que o número de tabelas no Word
é o esperado. Por fim escreve um `LEIA-ME.txt` com data, commit do código e versão dos bancos.

**Se não existisse:** as tabelas ficariam em formato interno; você teria de abrir o R para ler.

### `run.R`: o maestro

**O que é.** O script que executa as etapas 01 a 08 em ordem. É o único comando de que você
precisa: `source("run.R")` no RStudio, ou `Rscript run.R` no terminal.

**Como funciona.** A função `executar_etapas()` (em `R/funcoes_utilitarias.R`) recebe a lista
de etapas e, para cada uma: avisa qual vai rodar, marca a hora, executa, marca a hora de novo e
anota o tempo. Se uma etapa parar com erro, `run.R` para ali, grava o log e mostra a mensagem.
Cada etapa roda num **ambiente próprio**: uma etapa não enxerga as variáveis da outra, o que
impede que um valor esquecido de uma etapa contamine a seguinte. O trecho central:

```r
for (nome in names(etapas)) {
  message("==> ", nome)
  t0 <- Sys.time()
  erro <- tryCatch({ etapas[[nome]](); NULL }, error = function(e) e)
  seg <- as.numeric(Sys.time() - t0, units = "secs")
  log[nrow(log) + 1, ] <- list(nome, seg, if (is.null(erro)) "ok" else paste("ERRO:", conditionMessage(erro)))
  if (!is.null(erro)) { gravar_log(); stop("Pipeline parou em ", nome, ": ", conditionMessage(erro), call. = FALSE) }
}
```

`tryCatch` executa a etapa e, se der erro, captura-o em vez de derrubar tudo; assim dá para
gravar o log antes de parar. O log fica em `resultados/execucao.log`, com o tempo de cada
etapa. A execução completa leva cerca de 230 segundos.

Duas opções: `--limpar` apaga tudo o que é derivado (intermediários, processados, resultados)
antes de rodar, para provar que o pipeline refaz tudo do zero; `--sem-relatorio` pula o
Quarto numa máquina sem ele.

**Se não existisse:** você teria de abrir e rodar oito scripts na ordem certa, e um erro no
meio poderia passar despercebido.

### Resumo das etapas 04 a 07 e do `run.R`

> Com o mapa em mãos, a linha de montagem calcula quem é vizinho de quem (456 ligações, um
> número vigiado), e pergunta, por vírus e ano, se municípios de taxa alta se agrupam mais do
> que o acaso permitiria, embaralhando as taxas 9.999 vezes com uma semente fixa para que o
> resultado seja sempre o mesmo. O LISA aponta onde estão os agrupamentos e uma correção
> separa os confirmados dos apenas indicativos. Tudo vira 45 mapas e 19 gráficos, com as cores
> definidas num lugar só, e 14 tabelas prontas para o Excel e para o Word. O `run.R` rege a
> orquestra: chama cada etapa na ordem, cronometra e para na primeira nota errada.

---

## Parte 5. Os produtos para pessoas: o relatório, a apresentação e o painel

### `08_relatorio.qmd`: um relatório que se preenche sozinho

**O que é.** Um arquivo **Quarto** (extensão `.qmd`): texto comum, escrito em Markdown,
misturado com pedaços de código R. Ao "renderizar", o Quarto executa o código, coloca os
resultados no lugar e produz o `08_relatorio.html` (uma página de navegador, com todas as
figuras embutidas num arquivo só, por causa da opção `embed-resources: true` no cabeçalho) e
o `08_apresentacao.html` (slides, no formato revealjs, gerados do mesmo texto).

*Analogia:* mala direta. A carta tem o texto fixo e campos "<nome>", "<valor>"; na hora de
imprimir, os campos são preenchidos a partir da tabela. Aqui os campos são preenchidos a
partir de `resultados/`.

**A regra mais importante do relatório: nenhum número é digitado.** É o invariante 2. Todo
número do texto vem de um pedaço de código que lê um arquivo de `resultados/`. Um exemplo, do
cabeçalho do arquivo:

```r
malha <- readRDS(file.path("dados", "processados", "municipios_rj.rds"))
n_mun <- nrow(malha)
```

e, no meio do texto, algo como "os `r n_mun` municípios" vira "os 92 municípios" na hora de
renderizar. Se o número mudar nos dados, muda no texto. E há um teste
(`tests/testthat/test-relatorio.R`) que procura números escritos à mão no texto e falha se
encontrar; o comentário no topo do `.qmd` avisa isso. Foi esse teste que pegou, por exemplo,
o número do decreto das regiões de saúde digitado no texto, que passou a vir de uma variável.

**O que tem dentro.** Introdução, uma seção "Decisões de método" com os sete ADRs em
linguagem de artigo (CS-052), a seção sobre como a população de cada ano foi obtida com as
fórmulas e o exemplo de Niterói (CS-049), resultados, discussão, limitações e conclusão. As
referências bibliográficas vêm de `referencias.bib`, um arquivo no formato BibTeX (uma ficha
por referência; o Quarto monta a lista de referências e as citações no texto).

**`_quarto.yml`.** A configuração do projeto Quarto: diz que o único arquivo a renderizar é o
`08_relatorio.qmd`.

**Quem usa.** Você e a banca. O `run.R` o renderiza como etapa 08.

**Se não existisse:** os números estariam nas tabelas, mas o texto científico teria de ser
escrito à mão, e cada nova execução exigiria conferir número por número.

### `app.R`: o painel interativo

**O que é.** Um programa **Shiny** (pacote do R para páginas interativas) com um mapa
**leaflet** (biblioteca de mapas navegáveis, como os de sites de rotas). Você escolhe vírus,
ano e camada (taxa ou LISA), e clica num município para ver casos, população, taxas e classe.

**O que lê.** Só `dados/processados/` e `resultados/`. Se o pipeline não rodou, ele abre e
explica o que falta, em vez de quebrar. Para desenhar no navegador, simplifica o mapa (tira
pontos das linhas) só para exibição; a análise usou o mapa completo.

**Se não existisse:** o PDF pedia um painel; ele é o produto (b).

### Resumo da Parte 5

> Depois da linha de montagem vêm os produtos para pessoas. O relatório é um texto com
> "campos" que o Quarto preenche lendo os resultados, e um teste garante que ninguém digitou
> um número à mão. A apresentação sai do mesmo texto. O painel deixa qualquer pessoa navegar
> pelos mapas no navegador, lendo só o que o pipeline já produziu.

---

## Parte 6. Como o projeto se vigia: testes, base sintética, robô e auditoria

### O que é um teste automático

Um **teste** é um pedaço de código que executa uma função com uma entrada conhecida e confere
se a resposta é a esperada. Por exemplo: "dê à função de semana epidemiológica a data
28/12/2025 e confira que ela devolve semana 53 de 2025". Se a função devolver outra coisa, o
teste **falha**, e alguém vê. O pacote que organiza isso em R chama-se `testthat`, e por
convenção dele os testes ficam em `tests/testthat/`, um arquivo por tema
(`test-sivep-etl.R`, `test-moran-lisa.R`, `test-paleta.R`...).

*Analogia:* o gabarito de uma prova. Antes de entregar a prova nova, o professor a aplica em
si mesmo e confere com o gabarito. Cada vez que alguém muda uma função, os testes rodam de
novo e conferem se nada que antes dava certo passou a dar errado.

Hoje são 810 conferências ("expectativas") em 23 arquivos, e todas passam. O projeto exige que
esse número seja dito com número, nunca com "os testes passam" (invariante 8). O arquivo
`tests/testthat/helper-projeto.R` é carregado antes de todos os testes: acha a raiz do projeto
e carrega as funções de `R/`.

### `tests/testthat/fixtures/sivep_sintetico.csv`: o manequim

Os testes do SIVEP não podem usar fichas reais: seriam dados de pacientes dentro do
repositório público, e baixá-los levaria minutos. Então existe uma **base sintética**: 210
fichas **fabricadas** (a primeira coluna de cada linha diz literalmente "FABRICADO"), com o
formato exato do SIVEP e os 92 municípios reais, cobrindo 19 cenários (covid por antígeno,
influenza A por PCR, co-detecção, ficha não encerrada...). O script `tests/gerar_fixture.R` a
gera com semente fixa. O ponto fino, registrado no comentário do próprio script: **a resposta
esperada de cada cenário foi escrita à mão**, a partir do texto do ADR-0002, e não calculada
pelas funções que o teste vai conferir. Se fosse calculada, o teste só confirmaria que o
código concorda consigo mesmo.

*Analogia:* o manequim de teste de colisão. Tem o formato de uma pessoa, mas não é uma.

### `.github/workflows/testes.yml`: o inspetor automático

Dentro da pasta `.github/` há um arquivo YAML que instrui o GitHub a fazer o seguinte a cada
commit enviado: alugar um computador virtual limpo (Linux), instalar o R 4.6.1, instalar os
pacotes pelo `renv.lock`, e rodar todos os testes. Se algum falhar, o GitHub marca o commit com
um X vermelho; se passarem, um sinal verde (o "badge" no topo do README). Isso se chama
**integração contínua** (CI). Como esse computador não tem os dados reais, os testes que
precisam deles são pulados, e a contagem de pulados aparece no resumo.

*Analogia:* um inspetor de qualidade que refaz a prova em outra fábrica, com máquinas novas,
toda vez que a receita muda. Se só funciona na sua cozinha, o inspetor descobre.

**Se não existisse:** "funciona na minha máquina" seria a única garantia.

### `tests/auditoria_independente.R`: o segundo caminho

Este script refaz os números centrais do projeto **por outro caminho**: lê os arquivos brutos
com o R básico, sem usar nenhuma função de `R/` e sem o pacote `spdep`, e compara com o que o
pipeline produziu. O comentário do topo diz o motivo: "se este script e o pipeline concordam,
um erro teria de estar nos dois ao mesmo tempo". Foi rodado na auditoria final (CS-027) antes
da publicação.

*Analogia:* pedir a dois contadores que fechem o mesmo balanço, cada um com sua calculadora.

### Resumo da Parte 6

> O projeto não confia em si mesmo. Cada função tem um gabarito (810 conferências), os
> gabaritos do SIVEP usam um manequim fabricado em vez de pacientes, um inspetor no GitHub
> refaz as conferências numa máquina limpa a cada mudança, e um segundo contador refez as
> contas principais sem usar as funções do projeto.

---

## Parte 7. A memória do projeto: os documentos

A pasta `docs/` é onde o projeto conta a si mesmo o que fez e por quê. Como a construção foi
rápida e com muitas decisões, sem esses arquivos ninguém (nem quem construiu) saberia daqui a
seis meses por que o código faz o que faz. Todos são Markdown (`.md`), que o GitHub mostra
formatado e qualquer editor abre.

| Arquivo | O que é | Regra |
|---|---|---|
| `docs/trilha-desenvolvimento.md` | A leitura crítica do PDF, a arquitetura (o que cada etapa promete produzir, chamado "contrato"), os nove invariantes e as fases | vivo: reflete o estado atual |
| `docs/BACKLOG.md` | A lista de tudo o que foi feito e falta fazer. Cada tarefa é um item `CS-0NN` (CS de "Cartografia & Saúde"); cada decisão que só você ou o Patrick podem tomar é um `D-NN`. Item concluído vai para "Encerrados" com data e commit. Nada é apagado | vivo |
| `docs/decisoes/ADR-000N-*.md` | Os sete registros de decisão (Parte 1) | **append-only** |
| `docs/release-history/cs-0NN-*.md` | Um registro por item concluído: o que foi feito, os números que provam, as decisões, os erros do caminho | **append-only** |
| `docs/proposta-v2.md` | A sua proposta revisada, com as correções e as decisões incorporadas ao texto. É o que vira `proposta-v2.docx` | vivo |
| `docs/nota-metodologica-suavizacao.md`, `docs/nota-metodologica-padronizacao.md` | Explicações de método com os números do projeto | vivos |
| `docs/revisao-graficos.md` | Cada figura: a pergunta que responde, a forma escolhida e por quê (CS-047) | vivo |
| `docs/dicionario-sivep.md` | Os 37 campos do SIVEP usados (Parte 3) | vivo |
| `docs/historia-do-projeto.md` | Este documento | vivo |

**Append-only** ("só acréscimo") é a regra dos ADRs e dos registros de item: uma vez escritos e
gravados no Git, não se reescrevem; se algo estava errado, acrescenta-se uma seção "Errata" no
fim. Há até um mecanismo automático (um *hook*, um script que o assistente de programação é
obrigado a rodar antes de editar) que recusa a edição destrutiva desses arquivos; ele foi
criado depois que um registro foi reescrito por engano (CS-045), o que o projeto chama de
cicatriz. *Analogia:* caderno de laboratório escrito a caneta. Errou? Risca e escreve ao lado,
com data. Não arranca a página.

### Os arquivos na raiz que não são código

- **`README.md`**: a capa. Como instalar e rodar, o que sai, a estrutura, a licença. É o
  primeiro arquivo que o GitHub mostra.
- **`COMECE-AQUI.md`** e **`CartografiaESaude.Rproj`** (CS-059, 28/09): o guia de três passos e
  o arquivo de projeto do RStudio, criados depois da sua mensagem de que a pasta parecia
  poluída. O `.Rproj` faz o RStudio abrir já na pasta certa, o que liga o renv sozinho.
- **`LICENSE`** e **`LICENSE-CONTEUDO.md`**: as licenças, decididas por você (D-01): MIT para o
  código (qualquer um pode usar, citando), CC-BY 4.0 para relatório, mapas e tabelas (qualquer
  um pode usar, dando crédito). Os dois nomes, o seu e o do Patrick, estão no `LICENSE`.
- **`CITATION.cff`**: uma ficha em formato padronizado que diz como citar o trabalho; o GitHub a
  lê e mostra um botão "Cite this repository".
- **`CLAUDE.md`** e a pasta **`.claude/`**: as instruções para o assistente de programação que
  ajudou na construção, e os três *hooks* (scripts de guarda) que ele é obrigado a respeitar:
  um que o lembra das regras ao começar, um que recusa gravar código sem o registro do item,
  e o que protege os arquivos append-only. Não são necessários para rodar a análise; por isso
  ficaram fora do pacote de scripts que você recebeu.

### Resumo da Parte 7

> Cada decisão virou um ADR, cada tarefa virou um item numerado no BACKLOG com data e
> commit, e cada item concluído deixou um registro com os números que provam que funcionou.
> Esses registros são escritos a caneta: só se acrescenta. É por isso que este documento pôde
> ser escrito: a história estava toda anotada.

---

## Parte 8. Por que organizar assim: as regras que moldaram tudo

A pasta pode parecer "poluída" porque cada arquivo existe por causa de uma regra. Aqui estão
as nove regras (os **invariantes**, coisas que nunca se quebram, listadas em
`docs/trilha-desenvolvimento.md` §3.3), em palavras simples, cada uma com o arquivo que a faz
valer e, quando houve, o erro real que a originou:

| Regra | Em palavras simples | Quem faz valer | De onde veio |
|---|---|---|---|
| 1. Dado bruto nunca entra no Git nem é editado | Fichas de pacientes ficam só na máquina; o que se baixa não se toca | `.gitignore`; `verificar_manifesto()` | LGPD e reprodutibilidade |
| 2. Nenhum número do relatório é digitado | Todo número vem de um arquivo de resultado | `test-relatorio.R` | três rascunhos afirmaram o que o dado não dizia (CS-032, CS-034, CS-041) |
| 3. Zero explícito | Município sem caso aparece com 0, não some | `completar_municipios()` | junção que apaga o zero em silêncio |
| 4. Chave `cod6` como texto | Seis dígitos, sempre texto, em toda tabela | `validar_codigos_ibge()`; ADR-0007 | 6 × 7 dígitos: junção vazia sem erro |
| 5. Semente fixa, 9.999 permutações | O aleatório é sempre o mesmo | `SEMENTE` em `funcoes_utilitarias.R`; ADR-0004 | resultado que muda a cada execução não é resultado |
| 6. Vizinhança única | O estado é um bloco só, sem ilha isolada | `criar_vizinhos_queen()` para se não for | Moran mal definido |
| 7. Base sintética rotulada | Dado de teste é fabricado e diz que é | `sivep_sintetico.csv`, coluna "FABRICADO" | nunca se parecer com paciente real |
| 8. Verificação com número | "810/810 em 23 arquivos" vale; "passa" não vale | regra de todo registro | padrão do dono do projeto |
| 9. Auditoria por outro caminho | Um segundo cálculo, sem as funções do projeto | `tests/auditoria_independente.R` | CS-027 |

### Por que nesta ordem

A trilha (§5.1) desenha o **caminho crítico**: a sequência de itens em que cada um só pode
começar quando o anterior termina. Ele foi: fundação → download → limpeza → regra de caso
(ADR-0002) → classificação → taxas → vizinhança → Moran/LISA → relatório. Repare que o texto
científico é o **último**: a trilha registra que "o código é insumo do texto científico, não o
contrário", porque as seções vazias do PDF (resultados, discussão, conclusão) só podiam ser
escritas depois que os números existissem. E repare que a vizinhança (etapa 04) foi construída
antes da regra de caso, porque só depende do mapa; o histórico de commits mostra o CS-016
antes do CS-007.

### O que foi decidido por você e o que foi decidido pelo código

O `CLAUDE.md` do projeto diz: "quem decide método é a autora; o código aplica a decisão e, se
ela for provisória, diz isso". As decisões suas estão na tabela de decisões do BACKLOG (D-01 a
D-11): licenças, regra de caso, denominador de 2023, município e não bairro, quadrimestre só
descritivo, suavização no LISA, escopo da proposta v2. Uma continua marcada como provisória e
espera a sua palavra: a D-11, sobre publicar ou suprimir as contagens de 1 a 4 casos. Todas as
outras escolhas (formato de arquivo, número de permutações, cores, estrutura de pastas) são
técnicas, e cada uma tem o seu registro.

### Resumo final: a história em um parágrafo

> Em 25 de setembro de 2026, uma proposta em PDF foi lida contra as fontes oficiais e revelou
> cinco pontos que quebrariam o trabalho em silêncio. Cada um virou uma decisão escrita, sua.
> No mesmo dia, foi montado um armário de pastas igual ao do PDF, com a lista de pacotes
> congelada pelo renv, um livro de lacres para cada arquivo baixado e a regra de que dado de
> paciente nunca entra no histórico. Sobre essa base, uma linha de montagem de oito etapas
> baixa as fichas, classifica cada uma num vírus pela regra que você escolheu, calcula taxas
> com zero explícito e população interpolada onde o IBGE não publicou, monta o mapa oficial,
> acha os vizinhos, mede se as taxas se agrupam mais do que o acaso, desenha 45 mapas e exporta
> 14 tabelas. Um relatório se preenche sozinho com esses números, um teste impede que alguém
> digite um número à mão, 810 conferências e um inspetor no GitHub vigiam cada mudança, e cada
> passo ficou anotado a caneta em `docs/`. Nos três dias seguintes, os seus pedidos (cores,
> contorno, painéis, tabelas ABNT, versões do banco, população explicada) entraram pelo mesmo
> caminho: item numerado, código, teste, registro, commit.

---

## Apêndice. Mapa rápido: cada arquivo ou pasta em uma linha

| Arquivo ou pasta | O que é | Quem usa | Se sumisse |
|---|---|---|---|
| `00_setup.R` | carrega as funções e cria as pastas | todo script numerado | nenhum script acharia as funções |
| `01_etl_sivep.R` | baixa, filtra e classifica as fichas | etapa 02 | nada a analisar |
| `02_indicadores.R` | população, casos e taxas | etapas 03, 05, 06, 07 | só contagens, sem taxa |
| `03_cartografia.R` | mapa, regiões, leitos | etapas 04, 05, 06 | sem mapa nem vizinhança |
| `04_pesos_espaciais.R` | quem é vizinho de quem | etapa 05 | Moran sem "perto" |
| `05_moran_lisa.R` | Moran global e LISA | etapas 06, 07, relatório, painel | sem resposta à pergunta do PDF |
| `06_visualizacoes.R` | 45 mapas e 19 gráficos | relatório, você | números sem imagem |
| `07_exportacao.R` | tabelas para Excel e Word, proposta em Word | você | tabelas só em formato interno |
| `08_relatorio.qmd` | relatório e apresentação | você, a banca | texto escrito à mão |
| `run.R` | roda tudo em ordem, cronometra, para no erro | você | oito scripts à mão |
| `app.R` | painel interativo | você, vigilância | sem produto (b) do PDF |
| `R/funcoes_*.R` | as funções, por tema (11 arquivos) | scripts, testes, relatório, painel | tudo |
| `config/fontes.yml` | endereços das fontes | funções que baixam | endereços escondidos no código |
| `dados/MANIFESTO.md` | impressão digital de cada arquivo baixado | funções que leem brutos | sem prova de que os dados são os mesmos |
| `dados/externos/` | referência pequena e pública (no Git) | etapas 02, 03 | baixar de novo |
| `dados/brutos/` | o que foi baixado, intocado (fora do Git) | etapa 01, 03 | baixar de novo |
| `dados/intermediarios/`, `processados/` | meio e fim da limpeza (fora do Git) | etapas seguintes | `run.R` refaz |
| `resultados/` | tabelas, mapas, estatística, objetos, documentos | relatório, painel, você | `run.R` refaz |
| `tests/testthat/` | 810 conferências em 23 arquivos | você, o inspetor do GitHub | erros passariam |
| `tests/testthat/fixtures/` | o manequim fabricado | os testes | testes precisariam de dados reais |
| `tests/gerar_fixture.R` | gera o manequim | quem mudar um cenário | manequim sem origem |
| `tests/auditoria_independente.R` | recálculo por outro caminho | antes de entregar | uma conferência a menos |
| `.github/workflows/testes.yml` | o inspetor automático | o GitHub | só "funciona na minha máquina" |
| `renv.lock`, `renv/`, `.Rprofile` | pacotes congelados e o interruptor do renv | R ao abrir a pasta | versões diferentes em cada máquina |
| `.gitignore`, `.gitattributes` | o que o Git ignora e como trata bytes | o Git | pacientes no GitHub; lacres quebrados |
| `_quarto.yml`, `referencias.bib` | configuração e referências do relatório | Quarto | relatório sem bibliografia |
| `docs/` | trilha, BACKLOG, ADRs, registros, proposta v2, notas | quem quiser saber por quê | a memória |
| `README.md`, `COMECE-AQUI.md`, `CartografiaESaude.Rproj` | capa, guia de 3 passos, projeto do RStudio | você | começar sem mapa |
| `LICENSE`, `LICENSE-CONTEUDO.md`, `CITATION.cff` | licenças e como citar | quem reutilizar | uso sem regra |
| `CLAUDE.md`, `.claude/` | regras e guardas do assistente de programação | o assistente | irrelevante para rodar |
