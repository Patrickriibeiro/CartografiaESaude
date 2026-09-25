# CS-025 — Integração contínua no GitHub Actions

- **Data:** 2026-09-25
- **Modelo · esforço:** Opus · medium (acordado com o dono)

## Verificação com número

| Critério de aceite | Resultado |
|---|---|
| Workflow verde no 1º PR | **NÃO VERIFICADO**: o repositório ainda não está no GitHub (depende do CS-026). A primeira execução real é o aceite pendente deste item |
| Tempo < 10 min | não medido, pelo mesmo motivo |
| Workflow válido | `.github/workflows/testes.yml` lido sem erro pelo `yaml`; 1 job, 5 passos, R 4.6.1 |
| Suíte portável para Linux | URLs `file://` passaram a ser montadas por `url_arquivo()`, certa nos dois sistemas; suíte local continua 491/491 |

## O que o workflow faz

Em cada push para `main`, em cada pull request e sob demanda: Ubuntu 24.04, R 4.6.1,
bibliotecas de sistema do `sf` (GDAL, GEOS, PROJ, udunits), `renv::restore()` com pacotes
**binários** do Posit Package Manager (sem compilar) e cache entre execuções, e a suíte com
`stop_on_failure = TRUE`. O resumo imprime expectativas, testes, **pulados** e arquivos.

## Decisões

- **Sem dados reais na CI.** Os testes de integração se pulam sozinhos (`skip_if_not`), e o
  número de pulados aparece no resumo (6 esperados). Baixar 114 MB do Ministério a cada push
  testaria a internet, não o código.
- **`TZ=America/Sao_Paulo`** no ambiente: o teste do fuso horário só prova algo se a
  máquina não estiver em UTC, que é o padrão dos runners.
- Versão do Ubuntu fixada (`ubuntu-24.04`, não `latest`), para o endereço dos binários
  (`noble`) não quebrar numa troca silenciosa de versão.

## Riscos conhecidos para a primeira execução

- Algum teste pode depender do Windows sem que eu tenha visto (a suíte só rodou no Windows).
  O `url_arquivo()` corrigiu o caso encontrado na revisão.
- O pacote `arrow` em Linux às vezes exige bibliotecas extras; os binários do Posit Package
  Manager costumam trazê-las embutidas.

## Erros do caminho

Na revisão, as URLs `file:///` + caminho dariam `file:////tmp/...` no Linux. Corrigido antes
de qualquer execução.

## Adendo (2026-09-25): 1ª tentativa de execução

Depois do envio ao repositório privado, a execução 36170698073 terminou em 3 s **sem rodar
nenhum passo**. Anotação do GitHub: *"The job was not started because recent account payments
have failed or your spending limit needs to be increased."* Não é defeito do workflow nem dos
testes; é a cobrança do GitHub Actions na conta `Patrickriibeiro`, que só o dono ajusta. O
aceite continua pendente.
