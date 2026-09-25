# CS-003 + CS-004 — Manifesto de proveniência e dicionário oficial

- **Data:** 2026-09-25
- **Modelo · esforço:** Opus · medium (acordado com o dono)
- **Itens:** CS-003, CS-004; correção de defeito do CS-002 (`00_setup.R`)

## Verificação com número

| Critério de aceite | Resultado |
|---|---|
| Suíte completa | **58/58 expectativas em 17 testes, 2 arquivos**, 0 falhas, 0,43 s |
| Testes do manifesto | 12 testes em `test-proveniencia.R`, sem rede |
| Arquivo alterado em 1 byte é detectado | sim: `"1,2,3"` → `"1,2,4"` gera "SHA-256 divergente" |
| Bruto sem registro é recusado | sim: `verificar_manifesto()` para com "sem registro no manifesto" |
| Registro duplicado | 2 chamadas geram 1 linha |
| Download real do dicionário | 1.052.922 bytes; SHA-256 `6b92d438cf1cab28cd3719a7bcc48df3c269cf271f7c8181e334db2e849a0e35` |
| Hash conferido fora do R | `sha256sum` dá o mesmo valor, idêntico ao do download manual da análise |
| Cache | 1ª chamada 0,35 s; 2ª chamada 0,01 s, sem novo download |
| Campos documentados | **34** em `docs/dicionario-sivep.md`, todos com tipo e domínio; 4 marcados [CONFERIR] |
| Testes novos pegam o defeito do `00_setup.R` | sim: com a versão antiga, 2 erros; com a corrigida, 0 |

## Decisões tomadas na implementação

1. **Um só arquivo de manifesto, em Markdown, escrito e relido pelo código.** Como o
   BACKLOG pedia. A alternativa era um CSV como fonte e um Markdown gerado a partir
   dele, mas dois arquivos podem divergir. O custo aceito é que a tabela não aceita `|`
   nem quebra de linha em nenhum campo; a função recusa e há teste para isso.
2. **Hash novo no mesmo arquivo exige `substituir = TRUE`.** O banco de 2025 muda toda
   semana; rebaixá-lo tem de ser decisão explícita, nunca efeito colateral.
3. **Cache adulterado para o pipeline em vez de ser sobrescrito.** Se o arquivo em disco
   não bate com o manifesto, alguém alterou um dos dois, e isso precisa ser investigado.
4. **O PDF do dicionário é versionado no git** (`dados/externos/`, 1 MB). É público,
   pequeno e é a fonte de verdade dos nomes de campo; se o link do S3 mudar, o projeto
   não perde a referência.
5. **URLs em `config/fontes.yml`**, não no código (trilha §6).

## Achados do dicionário oficial

- O dicionário é de **25/05/2023**, embora publicado como "2019 a 2025". Campos criados
  depois podem estar nos bancos sem constar nele.
- Existe um campo oficial de co-detecção, `CO-DETEC` (campo 79). O hífen não é válido
  em nome de coluna; o nome real no CSV fica para conferir no CS-006.
- O dicionário grafa `PCR_ SARS2`, com espaço.
- `PCR_SARS2` e `PCR_VSR` só ficam habilitados quando "positivo para outros vírus" é Sim.
- Desde **31/10/2022**, critério clínico e clínico-imagem não encerram SRAG por covid-19.
  Entrada direta do ADR-0002.

Tudo isso foi incorporado ao CS-006 (aceite ampliado), ao CS-007 (evidência) e à trilha
§2.2 e §2.6.

## Erros do caminho

1. **Defeito herdado do CS-002.** O `00_setup.R` foi commitado em `b66ae13` com
   `"^funcoes_.*\.R$"`. `\.` não é um escape válido em texto do R, então o arquivo nunca
   carregou. O heredoc do shell usado para criar o arquivo removeu uma das duas barras.
   O teste de estrutura não pegou porque só conferia se o arquivo existia. Correção:
   restaurar `\\.` e criar dois testes, um que faz o parse de todo `.R` do projeto e
   outro que executa o `00_setup.R` num projeto temporário. Os dois falham na versão
   antiga. Regra daqui em diante: arquivo de código se escreve com a ferramenta de
   escrita, não com heredoc.
2. **Teste que passaria com o código quebrado.** A primeira versão do teste do
   `00_setup.R` procurava as funções com `exists()`, que também olha no ambiente global,
   onde o helper de testes já as tinha carregado. Correção: o setup passou a carregar as
   funções com `source(local = TRUE)` e o teste procura com `inherits = FALSE`.
3. Um comando de shell longo com várias aspas foi recusado inteiro pelo bash
   ("unexpected EOF"); nenhum arquivo foi escrito. Refeito com a ferramenta de escrita.
