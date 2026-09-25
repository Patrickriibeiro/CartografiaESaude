"""Números do relatório renderizado (HTML) contra os CSVs, por um caminho que não é
o do Quarto: extrai o texto do HTML e confere frases-chave com valores recalculados
dos CSVs em Python."""
import re, html, csv, os, sys
sys.stdout.reconfigure(encoding="utf-8")
os.chdir(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", ".."))  # raiz do projeto
s = open("08_relatorio.html", encoding="utf-8").read()
t = html.unescape(re.sub(r"<[^>]+>", " ", re.sub(r"<script.*?</script>|<style.*?</style>", "", s, flags=re.S)))
t = re.sub(r"\s+", " ", t)
def csvl(p): return list(csv.DictReader(open(p, encoding="utf-8")))
def fi(x): return f"{int(round(x)):,}".replace(",", ".")
def fd(x, d=1): return f"{x:.{d}f}".replace(".", ",")
falhas = 0
def conf(nome, trecho):
    global falhas
    ok = trecho in t
    if not ok: falhas += 1
    print(f"{nome:60s} {'OK' if ok else 'NÃO ENCONTRADO: ' + trecho}")

diag = csvl("resultados/tabelas/diagnostico_sivep.csv")
cpa = csvl("resultados/tabelas/casos_por_agente.csv")
est = csvl("resultados/tabelas/incidencia_estado.csv")
dec = csvl("resultados/tabelas/decomposicao_sem_campo_especifico.csv")
glob = csvl("resultados/estatistica/moran_global.csv")
res = csvl("resultados/estatistica/lisa_resumo.csv")
suav = csvl("resultados/tabelas/suavizacao_bayes_empirico.csv")

fichas = sum(int(x["fichas_rj"]) for x in diag)
conf("total de fichas", f"registrou {fi(fichas)} fichas")
tot = sum(int(x["casos"]) for x in cpa)
por = {a: sum(int(x["casos"]) for x in cpa if x["agente"] == a) for a in ("sarscov2", "influenza", "vsr")}
conf("total de casos", f"{fi(tot)} foram casos confirmados de SARS-CoV-2 ({fi(por['sarscov2'])}), influenza ({fi(por['influenza'])}) e vírus sincicial respiratório, VSR ({fi(por['vsr'])})")
def tx(ag, a, col="incid_100k_pop2024"): return float([x for x in est if x["agente"] == ag and x["ano"] == str(a)][0][col])
conf("queda do SARS-CoV-2", f"caiu de {fd(tx('sarscov2',2022))} para {fd(tx('sarscov2',2025))} casos por 100 mil")
conf("subida da influenza", f"influenza subiu de {fd(tx('influenza',2022))} para {fd(tx('influenza',2025))}")
conf("subida do VSR", f"VSR de {fd(tx('vsr',2022))} para {fd(tx('vsr',2025))}")
g = [x for x in glob if x["variavel"] == "incid_eb_100k" and x["vizinhanca"] == "queen"]
sig = [float(x["I"]) for x in g if float(x["p_perm"]) < 0.05]
conf("Moran global: n significativos", f"significativa em {len(sig)} de {len(g)} mapas")
conf("Moran global: faixa de I", f"I de Moran entre {fd(min(sig),2)} e {fd(max(sig),2)}")
d22 = [x for x in dec if x["agente"] == "sarscov2" and x["ano"] == "2022"][0]
d25 = [x for x in dec if x["agente"] == "sarscov2" and x["ano"] == "2025"][0]
conf("perda da regra literal", f"perderia {fd(100*int(d22['sem_campo_especifico'])/int(d22['classificados']))} % dos casos de COVID de 2022 e só {fd(100*int(d25['sem_campo_especifico'])/int(d25['classificados']))} % dos de 2025")
c22 = tx("sarscov2", 2022, "casos")
conf("941 casos só critério declarado", f"são {fi(int(d22['so_criterio_laboratorial_declarado']))} casos de COVID em 2022 ({fd(100*int(d22['so_criterio_laboratorial_declarado'])/c22)} % do ano)")
conf("esperado por acaso", f"cerca de {fd(92*0.05)} municípios significativos por mapa")
conf("faixa de significativos sem correção", f"ficam entre {min(int(x['sig_sem_correcao']) for x in res)} e {max(int(x['sig_sem_correcao']) for x in res)}")
t22 = int(diag[0]["com_resultado_de_teste"]) / int(diag[0]["fichas_rj"]); t25 = int(diag[-1]["com_resultado_de_teste"]) / int(diag[-1]["fichas_rj"])
conf("cobertura de testagem", f"passou de {fd(100*t22)} % para {fd(100*t25)} %")
z = [x for x in suav if x["agente"] == "vsr" and x["ano"] == "2022"][0]
conf("zeros do VSR 2022", f"Em VSR 2022, {z['municipios_sem_caso']} municípios não tiveram nenhum caso")
nao_int = sum(int(x["nao_internado"]) for x in diag) / fichas
conf("não internados", f"{fd(100*nao_int)} % das fichas dizem que o paciente não foi internado")
print(f"\nAUDITORIA DO HTML: {falhas} divergência(s)")
sys.exit(1 if falhas else 0)
