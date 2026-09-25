"""Auditoria documental (CS-027): cada número citado nos ADRs e na nota metodológica
contra os CSVs gerados pelo pipeline. Imprime OK/DIVERGE por conferência."""
import csv, re, os, sys
sys.stdout.reconfigure(encoding="utf-8")
raiz = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..")  # raiz do projeto
os.chdir(raiz)
falhas = 0
def conf(nome, obtido, esperado):
    global falhas
    ok = obtido == esperado
    if not ok: falhas += 1
    print(f"{nome:70s} {'OK' if ok else f'DIVERGE: doc={obtido} csv={esperado}'}")
def csvl(p): return list(csv.DictReader(open(p, encoding="utf-8")))
def num(s): return int(s.replace(".", "").replace("\u202f", "").strip())
def dec(s): return float(s.replace(".", "").replace(",", ".").strip())

# ---- ADR-0002 §3.1: casos por regra × agente × ano ----
adr2 = open("docs/decisoes/ADR-0002-criterio-de-caso.md", encoding="utf-8").read()
cmp = {(x["regra"], x["agente"], x["ano"]): int(x["casos"]) for x in csvl("resultados/tabelas/comparacao_regras_caso.csv")}
regras = {"R1 estrita-PDF": "R1_estrita_pdf", "R2 vigilância": "R2_vigilancia", "R3 qualquer evidência": "R3_qualquer_evidencia_lab",
          "R4 classificação": "R4_classificacao", "R5 laboratorial": "R5_laboratorial"}
agente = None
for linha in adr2.split("\n"):
    m = re.match(r"\|\s*(SARS-CoV-2|Influenza|VSR|Fichas contadas em 2\+ agentes)?\s*\|\s*([^|]+)\|\s*([\d.]+)\s*\|\s*([\d.]+)\s*\|\s*([\d.]+)\s*\|\s*([\d.]+)\s*\|\s*([\d.]+)\s*\|", linha)
    if not m: continue
    if m.group(1): agente = {"SARS-CoV-2": "sarscov2", "Influenza": "influenza", "VSR": "vsr", "Fichas contadas em 2+ agentes": "fichas_em_2_ou_mais_agentes"}[m.group(1)]
    rotulo = m.group(2).strip()
    vals = [num(m.group(k)) for k in range(3, 8)]
    if rotulo == "R1 = R2 = R3 = R4":
        chaves = list(regras.values())[:4]
    elif rotulo == "R1 a R4":
        chaves = list(regras.values())[:4]
    else:
        chaves = [regras[rotulo]]
    for r in chaves:
        obt = [cmp[(r, agente, a)] for a in ["2022", "2023", "2024", "2025"]]
        conf(f"ADR-0002 §3.1 {agente} {r}", vals[:4] + [sum(obt)] if vals[4] == sum(vals[:4]) else vals, obt + [sum(obt)] if vals[4] == sum(vals[:4]) else obt)

# ---- ADR-0002 §3.2: decomposição COVID ----
dec_ = {(x["agente"], x["ano"]): x for x in csvl("resultados/tabelas/decomposicao_sem_campo_especifico.csv")}
for linha in adr2.split("\n"):
    m = re.match(r"\|\s*(202\d)\s*\|\s*([\d.]+)\s*\|\s*([\d.]+)\s*\|\s*\*\*([\d.]+) \(([\d,]+) %\)\*\*\s*\|\s*([\d.]+)\s*\|\s*([\d.]+)\s*\|\s*([\d.]+)\s*\|\s*([\d.]+)\s*\|\s*([\d.]+)\s*\|", linha)
    if not m: continue
    d = dec_[("sarscov2", m.group(1))]
    conf(f"ADR-0002 §3.2 COVID {m.group(1)}",
         [num(m.group(i)) for i in (2, 3, 4, 6, 7, 8, 9, 10)] + [round(dec(m.group(5)), 1)],
         [int(d[k]) for k in ("classificados", "com_campo_especifico", "sem_campo_especifico", "resultado_positivo_generico_ou_sorologia",
                              "so_criterio_laboratorial_declarado", "criterio_clinico_epidemiologico", "criterio_clinico_ou_imagem", "criterio_vazio")]
         + [round(100 * int(d["sem_campo_especifico"]) / int(d["classificados"]), 1)])

# ---- ADR-0004 §4.1: Moran global ----
adr4 = open("docs/decisoes/ADR-0004-moran-lisa.md", encoding="utf-8").read()
glob = {(x["agente"], x["ano"], x["variavel"], x["vizinhanca"]): (float(x["I"]), float(x["p_perm"])) for x in csvl("resultados/estatistica/moran_global.csv")}
agente = None
for linha in adr4.split("\n"):
    m = re.match(r"\|\s*(SARS-CoV-2|Influenza|VSR)?\s*\|\s*(202\d)\s*\|(.*)\|\s*$", linha)
    if not m or "(" not in m.group(3): continue
    if m.group(1): agente = {"SARS-CoV-2": "sarscov2", "Influenza": "influenza", "VSR": "vsr"}[m.group(1)]
    celulas = [c.strip().replace("**", "") for c in m.group(3).split("|")]
    for celula, chave in zip(celulas, [("incid_eb_100k", "queen"), ("incid_100k", "queen"), ("incid_eb_100k", "rook")]):
        mm = re.match(r"(−?-?[\d,]+) \(([\d,]+)\)", celula)
        I_doc = dec(mm.group(1).replace("−", "-")); p_doc = dec(mm.group(2))
        I_csv, p_csv = glob[(agente, m.group(2), chave[0], chave[1])]
        # o ADR imprime p com 3 decimais (0,0007 -> 0,001), exceto o menor valor possível (0,0001)
        conf(f"ADR-0004 §4.1 {agente} {m.group(2)} {chave[1]} {chave[0]}", (round(I_doc, 3), p_doc), (round(I_csv, 3), round(p_csv, 4) if p_csv < 0.0005 else round(p_csv, 3)))

# ---- ADR-0004 §4.2: LISA resumo ----
res = {(x["agente"], x["ano"]): x for x in csvl("resultados/estatistica/lisa_resumo.csv")}
agente = None
for linha in adr4.split("\n"):
    m = re.match(r"\|\s*(SARS-CoV-2|Influenza|VSR)?\s*\|\s*(202\d)\s*\|\s*(\d+)\s*\|\s*\**(\d+)\**\s*\|\s*\**(\d+)\**\s*\|\s*(\d+)\s*\|\s*(\d+)\s*\|\s*(\d+)\s*\|", linha)
    if not m: continue
    if m.group(1): agente = {"SARS-CoV-2": "sarscov2", "Influenza": "influenza", "VSR": "vsr"}[m.group(1)]
    r = res[(agente, m.group(2))]
    conf(f"ADR-0004 §4.2 {agente} {m.group(2)}", [int(m.group(i)) for i in range(3, 9)],
         [int(r[k]) for k in ("sig_sem_correcao", "sig_fdr", "HH_confirmado", "LL_confirmado", "HH_indicativo", "LL_indicativo")])

# ---- nota metodológica da suavização ----
nota = open("docs/nota-metodologica-suavizacao.md", encoding="utf-8").read()
suav = {(x["agente"], x["ano"]): x for x in csvl("resultados/tabelas/suavizacao_bayes_empirico.csv")}
agente = None
for linha in nota.split("\n"):
    m = re.match(r"\|\s*(SARS-CoV-2|Influenza|VSR)?\s*\|\s*(202\d)\s*\|\s*(\d+)\s*\|\s*([\d,]+)\s*\|\s*([\d,]+)\s*\|\s*\**([\d,]+)\**\s*\|\s*(\d+) %\s*\|", linha)
    if not m: continue
    if m.group(1): agente = {"SARS-CoV-2": "sarscov2", "Influenza": "influenza", "VSR": "vsr"}[m.group(1)]
    s = suav[(agente, m.group(2))]
    conf(f"nota EB {agente} {m.group(2)}", (int(m.group(3)), dec(m.group(4)), dec(m.group(5)), dec(m.group(6)), int(m.group(7))),
         (int(s["municipios_sem_caso"]), round(float(s["bruta_max_100k"]), 1), round(float(s["eb_max_100k"]), 1), round(float(s["spearman_bruta_eb"]), 2), round(float(s["mudanca_mediana_pct"]))))

# ---- ADR-0003: razão estimativa/Censo ----
adr3 = open("docs/decisoes/ADR-0003-denominador-populacional.md", encoding="utf-8").read()
popd = csvl("resultados/tabelas/diagnostico_populacao.csv")
raz = sorted(float(x["razao_2024_censo"]) for x in popd)
med = raz[len(raz) // 2] if len(raz) % 2 else (raz[len(raz) // 2 - 1] + raz[len(raz) // 2]) / 2
m = re.search(r"no mínimo ([\d,]+) % \(Cambuci\), na\s+mediana ([\d,]+) %, no máximo ([\d,]+) % \(Rio de Janeiro\); no estado, ([\d,]+) %", adr3)
p22 = sum(int(x["pop_2022"]) for x in popd); p24 = sum(int(x["pop_2024"]) for x in popd)
conf("ADR-0003 razão 2024/Censo (min, mediana, max, estado)", tuple(dec(m.group(i)) for i in range(1, 5)),
     (round(100 * (raz[0] - 1), 1), round(100 * (med - 1), 1), round(100 * (raz[-1] - 1), 1), round(100 * (p24 / p22 - 1), 1)))
conf("ADR-0003 município de menor razão", "Cambuci", min(popd, key=lambda x: float(x["razao_2024_censo"]))["nome"].split(" - ")[0])
conf("ADR-0003 município de maior razão", "Rio de Janeiro", max(popd, key=lambda x: float(x["razao_2024_censo"]))["nome"].split(" - ")[0])

print(f"\nAUDITORIA DOCUMENTAL: {falhas} divergência(s)")
sys.exit(1 if falhas else 0)
