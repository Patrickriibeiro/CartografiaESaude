# CS-027 — Auditoria final

- **Data:** 2026-09-25
- **Modelo · esforço:** Fable 5.1 · high (acordado com o dono)
- **Escopo:** reexecução em clone limpo do GitHub; recálculo independente dos números; cada
  número dos ADRs contra os CSVs; o relatório renderizado contra os CSVs; cobertura por ADR
  dos erros factuais do PDF; dados sensíveis no versionado; lista consolidada de limitações.
- **Princípio:** auditoria adversarial. Os números foram refeitos por **outro caminho** (R
  base sem as funções do projeto e sem o `spdep`; Python para os documentos), não
  re-executando o pipeline e olhando se ele concorda consigo mesmo.

## 1. Resultado em números

| Frente | Método | Resultado |
|---|---|---|
| Reexecução em clone limpo | `git clone` **do GitHub** (não da pasta local) em pasta vazia; `renv::restore`; `run.R` completo com relatório | 8 etapas em 100 s; **0 diferenças** em `resultados/` contra o commitado (só o `LEIA-ME.txt`, que carrega data e commit); `08_relatorio.html` **idêntico byte a byte** ao local |
| Recálculo independente (`tests/auditoria_independente.R`) | R base + `arrow` para ler os brutos; vizinhança reconstruída pelos **nomes** da tabela de vizinhos; Moran I e LISA pela fórmula; BH à mão; SHA-256 do manifesto | **118/118 conferências OK**: fichas por ano, casos R2 por agente × ano, população por ano, 24 incidências, 456 ligações, simetria, 12 valores de I, 12 × 92 valores de Ii, 12 × 92 quadrantes, 12 × 92 p corrigidos, 12 × 92 níveis, 10 hashes |
| Auditoria documental (`tests/auditoria/auditoria_docs.py`) | Números das tabelas do ADR-0002 (§3.1, §3.2), ADR-0004 (§4.1, §4.2), ADR-0003 e da nota de suavização contra os CSVs | **86/86 OK** depois de uma errata de arredondamento (ver achado 3) |
| Relatório renderizado (`tests/auditoria/auditoria_html.py`) | 14 frases-chave do HTML recalculadas dos CSVs em Python | **14/14 OK**. A garantia de que **todo** número do relatório vem de `resultados/` é estrutural: código embutido + teste de números digitados (CS-022) |
| Cobertura dos 5 erros do PDF por ADR | grep nos ADRs | 4 de 5 cobertos; o 5º (§2.2, campos e chave de 6 dígitos) **não tinha ADR** → ADR-0007 criado (achado 1) |
| Dados sensíveis no versionado | lista de arquivos `.csv/.rds/.parquet` no git; cabeçalhos; fixture | nenhum microdado; o único arquivo com colunas de ficha é a base sintética, 210/210 linhas rotuladas FABRICADO; menor agregado publicado: 349 células com 1 a 4 casos (achado 5) |
| Fichas de residentes do RJ fora do filtro por código | `SG_UF = RJ` sem `CO_MUN_RES` 33 | **0** em todos os anos: o filtro por código não perde ninguém |

## 2. Achados

| # | Achado | Gravidade | O que foi feito |
|---|---|---|---|
| 1 | O erro factual §2.2 do PDF (`CO_MUNIC_RES` de 7 dígitos, `PCR_FLU`) estava corrigido no código e no dicionário, mas **sem ADR**, contra a regra da trilha | Documental, média | **ADR-0007** escrito (retroativo), com a tabela PDF × real e a decisão da chave `cod6` |
| 2 | **O bootstrap do `renv` falha em caminho longo no Windows.** No clone em pasta temporária (157 caracteres), o `renv` baixou a si mesmo e falhou ao instalar (`unzip`: caminho > 260 caracteres). Passou despercebido no CS-024 porque o `renv` já estava na biblioteca do sistema. Em pasta curta (41 caracteres) o bootstrap funciona | Portabilidade, média | README: instrução de clonar em caminho curto no Windows, com o motivo |
| 3 | ADR-0004 tabela 4.1, influenza 2023 bruta: p mostrado como 0,001; calculado 0,0007 (arredondamento a 3 decimais). O relatório mostra "< 0,001" | Documental, baixa | Errata acrescentada ao fim do ADR-0004 (arquivo de acréscimo) |
| 4 | A limitação **residência × notificação** tem número medido (8.040 · 4.190 · 4.117 · 5.451 fichas por ano com município de notificação ≠ residência) e não aparece no relatório; o CS-031 continua aberto | Relatório, média | Entra na lista consolidada (§3) e no CS-044 |
| 5 | Agregados pequenos: 349 células município × agente × ano com 1 a 4 casos são publicadas. Não há risco de reidentificação adicional (o Ministério publica o microdado anonimizado por ficha), mas algumas vigilâncias suprimem contagens < 5 | Ética/publicação, baixa | Registrado para a autora decidir (CS-043) |
| 6 | Dois defeitos no **próprio script de auditoria** (contagem com `NA` inflando fichas; código lido como número ao indexar matriz) | Da auditoria, nenhuma no projeto | Corrigidos; ambos ensinam o mesmo: conferir o auditor antes de acreditar na divergência |

## 3. Lista consolidada de limitações (para o §5.3 do relatório e a proposta v2 §3.10)

Numeradas para citação. ✔ = já está no relatório; ✘ = falta (vira CS-044).

1. ✔ **SRAG notificada, não infecção**: 1,0 % das fichas dizem "não internado"; 2,2 % sem a informação.
2. ✔ **Cobertura de testagem** sobe de 87,5 % (2022) para 91,7 % (2025) e pode inflar a tendência de casos confirmados.
3. ✔ **Denominador**: contagem do Censo 2022 3,1–8,4 % abaixo das estimativas ajustadas; dois denominadores, uma escolha (ADR-0003).
4. ✔ **Efeito de borda**: vizinhos em SP, MG e ES ignorados; Paraty, Itatiaia e Búzios com um vizinho (instáveis).
5. ✔ **Pequenos números e MAUP**: VSR 2022 com 44 municípios sem caso; suavização atenua, não elimina.
6. ✔ **Estudo ecológico**: nada vale para indivíduos.
7. ✘ **Residência × notificação**: 8.040 (2022), 4.190, 4.117 e 5.451 (2025) fichas notificadas fora do município de residência; a taxa por residência é a certa para incidência, mas o fluxo assistencial não foi analisado (CS-031).
8. ✘ (parcial: está no §4.2, não no §5.3) **941 casos de COVID em 2022 (5,6 %) com critério laboratorial declarado sem resultado exportado**: a regra R2 confia na declaração da vigilância.
9. ✘ (está no §4.3) **"Agrupamentos de zeros"**: zero caso em município pequeno pode ser ausência de notificação; por isso a bruta não é a principal (CS-041 investiga).
10. ✘ **Banco de 2025 é vivo**: o recorte é a versão 14-09-2026; uma nova versão muda os números de 2025 (está no §4.1, não como limitação).
11. ✘ **Dicionário oficial de maio de 2023** para bancos até 2025: nenhuma coluna nova apareceu, mas o domínio de valores não foi reconferido campo a campo.
12. ✘ **`SEM_PRI` do Ministério errado na semana 53/2025** (226 fichas): o projeto recalcula a semana da data; qualquer comparação com tabelas oficiais por semana precisa levar isso em conta.
13. ✘ **Suavização global, não local**: puxa para a média do estado, não dos vizinhos (nota metodológica).
14. ✘ **Painel desenha a malha simplificada** (100 m); a análise usou a completa. Só afeta o desenho.
15. ✘ **Sem escala de região de saúde nem padronização por idade** nesta entrega (CS-030, CS-033 abertos): a comparação entre municípios de estrutura etária diferente é bruta.
16. ✘ **Contagens pequenas publicadas** (achado 5).

## 4. Cobertura dos erros factuais do PDF (trilha §2.1–2.5)

| Erro no PDF | ADR |
|---|---|
| §2.1 `microdatasus` não baixa o SIVEP | ADR-0001 |
| §2.2 `CO_MUNIC_RES` de 7 dígitos, `PCR_FLU` | **ADR-0007** (criado nesta auditoria) |
| §2.3 sem estimativa populacional de 2023 | ADR-0003 |
| §2.4 banco de 2025 vivo | ADR-0001 (D-07) |
| §2.5 "por bairro" | ADR-0005 (item 3) |

## 5. O que esta auditoria NÃO cobre

- **Integração contínua**: bloqueada pela cobrança da conta (CS-025). A suíte só rodou no Windows.
- **Máquina realmente nova**: o clone reusou o cache de pacotes do `renv` e o R já instalado.
  O achado 2 mostra que a primeira instalação numa máquina nova tem um risco real no Windows.
- **Painel rodando no navegador**: verificado só por `testServer` e exportação do widget (CS-021).
- **Correção científica das escolhas** (regra R2, EB global, FDR por mapa): são decisões da
  autora, registradas em ADR; a auditoria confere que o que foi decidido é o que foi feito.

## 6. Erros do caminho

1. `b[cond, ]` com `cond` contendo `NA` cria linhas de `NA` e inflou a contagem de fichas em
   128, 66, 78 e 109 por ano. Antes de acusar o pipeline, conferi o auditor: `which()` resolve.
2. `read.csv` leu `cod6` como número; a matriz de vizinhança é indexada por texto. Corrigido
   com `as.character`.
3. A auditoria documental acusou o arredondamento do achado 3; era divergência de
   apresentação, não de valor. Resolvido com errata e um comparador que respeita 3 decimais.
