# CS-011 + CS-014 (+ CS-015) — População e malha municipal

- **Data:** 2026-09-25
- **Modelo · esforço:** Opus · medium (escolha do dono; o BACKLOG sugeria Fable · medium para o CS-011)
- **Itens:** CS-011, CS-014; CS-015 fechado junto, com aviso · ADR-0003 (proposto) · ADR-0006 (aceito)

## Verificação com número

| Critério de aceite | Resultado |
|---|---|
| Suíte completa | **125/125 expectativas em 39 testes, 4 arquivos**, 0 falhas, 0 pulados |
| População 92 × 4 sem NA | 368 linhas, 0 NA, inteiros positivos |
| Soma 2022 = Censo do estado | 16.055.174 = 16.055.174 |
| 2023 interpolado nas datas reais | peso 0,4771 (334/700 dias); RJ 2023 = 16.610.812 |
| Malha: 92 feições, EPSG 4674, válidas | 92, 4674, 92/92 válidas sem correção |
| Área (CS-015) | 43.750,4 km², idêntica ao campo oficial `AREA_KM2` |
| Junção por `cod6` | 92/92 com a população; os 92 códigos do SIVEP 2022–2025 estão na malha; com `cod7`, 0 casariam |
| Fontes no manifesto | 4 JSON do SIDRA + zip da malha, cada um com SHA-256 |
| Clone limpo preserva os bytes | 6/6 arquivos de `dados/externos/` conferem com o manifesto num `git clone` novo, depois de marcar a pasta como binária no `.gitattributes` (sem isso o git converteria CRLF → LF nos JSON) |

## Achados

1. **Degrau Censo × estimativa (ADR-0003).** Estimativa 2024 / Censo 2022 fica entre
   1,031 (Cambuci) e 1,084 (Rio de Janeiro), mediana 1,057, nos 92 municípios. A
   estimativa pré-Censo de 2021 também fica acima do Censo no estado (1,088). A decisão
   sobre como tratar isso voltou para a D-05, com 4 opções escritas.
2. **A malha simplificada do `geobr` perde 8 pares de vizinhos (ADR-0006).** 440 contra
   456 ligações Queen na malha oficial. Nenhum erro aparece: só o Moran e o LISA mudam.
3. **O `geobr` 2.1.0 baixa sem verificar o certificado SSL** (`ssl_verifypeer = 0`).

## Decisões de implementação

- Respostas do SIDRA guardadas **como vieram** (JSON) e registradas no manifesto; o parse
  é local. O pacote `sidrar` não foi usado: ele devolve o dado em memória, sem arquivo
  para conferir por hash.
- A interpolação usa as **datas de referência reais** (Censo em 01/08/2022, estimativas
  em 1º de julho), não o meio do caminho entre os anos.
- A estimativa de 2021 entra só no diagnóstico. A função recusa usá-la como denominador.
- `dados/processados/` passou para o `.gitignore`: é regenerável, e o `sivep_*` do
  CS-008 terá fichas individuais. `dados/externos/` continua versionado (5,4 MB,
  público, fonte oficial).
- A população foi para `dados/processados/`, não `dados/externos/` como o BACKLOG dizia:
  a tabela é derivada (tem 2023 interpolado), e `externos` guarda só o que veio de fora.

## Erros do caminho

1. **Verificação que eu quase pulei.** O plano era aceitar a malha do `geobr` porque ela
   passava nos critérios do CS-014 (92 feições, válidas, EPSG certo). Comparar a
   vizinhança com a malha oficial, que não estava no critério, foi o que mostrou os 8
   pares perdidos. Lição: critério de aceite prova o que pede, não o que a etapa
   seguinte precisa.
2. O CS-015 foi fechado sem ter sido pedido. Registrado aqui e no resumo ao dono.
