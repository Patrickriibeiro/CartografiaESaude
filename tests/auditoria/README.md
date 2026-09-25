# Scripts de auditoria documental (CS-027)

Conferem, em Python 3 (sem dependências), os números citados nos ADRs, na nota
metodológica e no relatório renderizado contra os CSVs de `resultados/`. Não fazem
parte do pipeline nem da CI; rodam da raiz do projeto, depois de `run.R`:

    python tests/auditoria/auditoria_docs.py
    python tests/auditoria/auditoria_html.py

A auditoria numérica independente (R base, sem spdep) é `tests/auditoria_independente.R`.
