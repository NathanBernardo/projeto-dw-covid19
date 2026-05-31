"""
GERADOR DE VISUALIZAÇÕES — DW COVID-19 (Brasil)
Versão sem kaleido: salva HTML (plotly) + PNG (matplotlib)
"""

import duckdb
import pandas as pd
import plotly.express as px
import plotly.graph_objects as go
from plotly.subplots import make_subplots
import matplotlib.pyplot as plt
import matplotlib.patches as mpatches
import seaborn as sns
import os

DB_PATH = "covid_dw.duckdb"
OUT_DIR = "visualizacoes"
os.makedirs(OUT_DIR, exist_ok=True)

con = duckdb.connect(DB_PATH)
print("✅ Conectado ao DuckDB!\n")

CORES_FASE = {
    "Pré-Pandemia":       "#AAAAAA",
    "Primeira Onda":      "#F4A261",
    "Segunda Onda":       "#E63946",
    "Vacinação em Massa": "#2A9D8F",
    "Ômicron":            "#457B9D",
    "Fase Endêmica":      "#6D3C4B",
}

# ══════════════════════════════════════════════════════════════
# GRÁFICO 1 — Evolução mensal de casos e mortes no Brasil
# ══════════════════════════════════════════════════════════════
print("📊 Gráfico 1: Evolução temporal — casos e mortes no Brasil...")

df1 = con.execute("""
    SELECT year_month, monthly_new_cases, monthly_new_deaths,
           pct_vaccinated_eom, phase_name
    FROM agg_monthly_brazil
    ORDER BY year_month
""").df()

fig, ax1 = plt.subplots(figsize=(14, 6))
ax2 = ax1.twinx()

ax1.fill_between(df1["year_month"], df1["monthly_new_cases"],
                 alpha=0.3, color="#F4A261", label="Novos Casos")
ax1.plot(df1["year_month"], df1["monthly_new_cases"], color="#F4A261", linewidth=1.5)
ax1.plot(df1["year_month"], df1["monthly_new_deaths"], color="#E63946",
         linewidth=2, label="Novas Mortes")
ax2.plot(df1["year_month"], df1["pct_vaccinated_eom"], color="#2A9D8F",
         linewidth=2, linestyle="--", label="% Vacinados")

ax1.set_title("Evolução da COVID-19 no Brasil (2020–2024)\nCasos, mortes mensais e cobertura vacinal",
              fontsize=13, fontweight="bold")
ax1.set_xlabel("Mês/Ano")
ax1.set_ylabel("Novos Casos / Mortes")
ax2.set_ylabel("% Vacinados")
ax2.set_ylim(0, 100)

lines1, labels1 = ax1.get_legend_handles_labels()
lines2, labels2 = ax2.get_legend_handles_labels()
ax1.legend(lines1 + lines2, labels1 + labels2, loc="upper left")

plt.xticks(rotation=45, ha="right")
plt.tight_layout()
plt.savefig(f"{OUT_DIR}/grafico_1_evolucao_brasil.png", dpi=150, bbox_inches="tight")
plt.close()

# HTML interativo
fig1 = make_subplots(specs=[[{"secondary_y": True}]])
fig1.add_trace(go.Scatter(x=df1["year_month"], y=df1["monthly_new_cases"],
    name="Novos Casos", fill="tozeroy",
    line=dict(color="#F4A261", width=2), fillcolor="rgba(244,162,97,0.2)"), secondary_y=False)
fig1.add_trace(go.Scatter(x=df1["year_month"], y=df1["monthly_new_deaths"],
    name="Novas Mortes", line=dict(color="#E63946", width=2.5)), secondary_y=False)
fig1.add_trace(go.Scatter(x=df1["year_month"], y=df1["pct_vaccinated_eom"],
    name="% Vacinados", line=dict(color="#2A9D8F", width=2, dash="dot")), secondary_y=True)
fig1.update_layout(title="Evolução da COVID-19 no Brasil (2020–2024)", height=500)
fig1.write_html(f"{OUT_DIR}/grafico_1_evolucao_brasil.html")
print("   ✅ Salvo!\n")

# ══════════════════════════════════════════════════════════════
# GRÁFICO 2 — Top 10 meses com mais mortes
# ══════════════════════════════════════════════════════════════
print("📊 Gráfico 2: Top 10 meses com mais mortes...")

df2 = con.execute("""
    SELECT year_month, month_name, year, phase_name,
           monthly_new_deaths, monthly_new_cases
    FROM agg_monthly_brazil
    ORDER BY monthly_new_deaths DESC
    LIMIT 10
""").df()
df2 = df2.sort_values("monthly_new_deaths", ascending=True)
df2["cor"] = df2["phase_name"].map(CORES_FASE).fillna("#CCCCCC")
df2["label"] = df2["month_name"] + "/" + df2["year"].astype(str)

fig, ax = plt.subplots(figsize=(12, 6))
bars = ax.barh(df2["label"], df2["monthly_new_deaths"], color=df2["cor"])
for bar, val in zip(bars, df2["monthly_new_deaths"]):
    ax.text(bar.get_width() + 500, bar.get_y() + bar.get_height()/2,
            f"{val:,.0f}", va="center", fontsize=10)

patches = [mpatches.Patch(color=cor, label=fase)
           for fase, cor in CORES_FASE.items() if fase in df2["phase_name"].values]
ax.legend(handles=patches, title="Fase", loc="lower right")
ax.set_title("Top 10 Meses com Mais Mortes por COVID-19 no Brasil",
             fontsize=13, fontweight="bold")
ax.set_xlabel("Total de Mortes no Mês")
plt.tight_layout()
plt.savefig(f"{OUT_DIR}/grafico_2_top10_mortes.png", dpi=150, bbox_inches="tight")
plt.close()

fig2 = go.Figure(go.Bar(x=df2["monthly_new_deaths"], y=df2["label"],
    orientation="h", marker_color=df2["cor"],
    text=df2["monthly_new_deaths"].apply(lambda x: f"{x:,.0f}"), textposition="outside"))
fig2.update_layout(title="Top 10 Meses com Mais Mortes — Brasil", height=500)
fig2.write_html(f"{OUT_DIR}/grafico_2_top10_mortes.html")
print("   ✅ Salvo!\n")

# ══════════════════════════════════════════════════════════════
# GRÁFICO 3 — Mapa de calor: taxa de mortalidade
# ══════════════════════════════════════════════════════════════
print("📊 Gráfico 3: Mapa de calor — taxa de mortalidade...")

df3 = con.execute("""
    SELECT year, month_name, month, case_fatality_rate_pct, phase_name
    FROM agg_monthly_brazil
    WHERE monthly_new_cases > 100
    ORDER BY year, month
""").df()

pivot = df3.pivot_table(values="case_fatality_rate_pct", index="year",
                        columns="month", aggfunc="mean")
meses = {1:"Jan",2:"Fev",3:"Mar",4:"Abr",5:"Mai",6:"Jun",
         7:"Jul",8:"Ago",9:"Set",10:"Out",11:"Nov",12:"Dez"}
pivot.columns = [meses.get(c, c) for c in pivot.columns]

fig3, ax = plt.subplots(figsize=(13, 5))
sns.heatmap(pivot, annot=True, fmt=".1f", cmap="RdYlGn_r",
            linewidths=0.5, linecolor="white",
            cbar_kws={"label": "Taxa de Mortalidade (%)"},
            ax=ax, vmin=0, vmax=5)
ax.set_title("Taxa de Mortalidade COVID-19 no Brasil por Mês/Ano (%)\n"
             "(mortes / casos confirmados × 100)",
             fontsize=13, fontweight="bold", pad=12)
ax.set_xlabel("Mês")
ax.set_ylabel("Ano")
plt.tight_layout()
plt.savefig(f"{OUT_DIR}/grafico_3_heatmap_mortalidade.png", dpi=150, bbox_inches="tight")
plt.close()
print("   ✅ Salvo!\n")

# ══════════════════════════════════════════════════════════════
# GRÁFICO 4 — Dashboard: casos e mortes por fase
# ══════════════════════════════════════════════════════════════
print("📊 Gráfico 4: Dashboard completo...")

df4a = con.execute("""
    SELECT phase_name, phase_order,
           SUM(monthly_new_cases)  AS total_casos,
           SUM(monthly_new_deaths) AS total_mortes
    FROM agg_monthly_brazil
    GROUP BY phase_name, phase_order
    ORDER BY phase_order
""").df()

df4c = con.execute("""
    SELECT year_month, avg_reproduction_rate AS rt
    FROM agg_monthly_brazil
    WHERE avg_reproduction_rate IS NOT NULL
    ORDER BY year_month
""").df()

kpis = con.execute("""
    SELECT MAX(total_cases_eom), MAX(total_deaths_eom),
           MAX(pct_vaccinated_eom), MAX(monthly_new_cases)
    FROM agg_monthly_brazil
""").fetchone()

fig, axes = plt.subplots(2, 2, figsize=(16, 10))
fig.suptitle("Dashboard COVID-19 — Brasil (2020–2024)", fontsize=16, fontweight="bold")

# Subplot 1: casos por fase
cores_lista = [CORES_FASE.get(f, "#CCCCCC") for f in df4a["phase_name"]]
axes[0,0].bar(df4a["phase_name"], df4a["total_casos"], color=cores_lista, alpha=0.8, label="Casos")
axes[0,0].bar(df4a["phase_name"], df4a["total_mortes"], color=cores_lista, alpha=1,
              edgecolor="black", linewidth=0.8, label="Mortes")
axes[0,0].set_title("Casos e Mortes por Fase")
axes[0,0].set_ylabel("Total")
axes[0,0].tick_params(axis='x', rotation=25)
axes[0,0].legend()

# Subplot 2: Rt mensal
if len(df4c) > 0:
    axes[0,1].plot(df4c["year_month"], df4c["rt"], color="#E63946", linewidth=2)
    axes[0,1].axhline(y=1.0, color="gray", linestyle="--", label="Rt=1")
    axes[0,1].set_title("Taxa de Reprodução (Rt) — Brasil")
    axes[0,1].set_ylabel("Rt")
    axes[0,1].tick_params(axis='x', rotation=45)
    axes[0,1].legend()

# Subplot 3: KPIs
axes[1,0].axis("off")
kpi_labels = ["Total de Casos", "Total de Mortes", "Cobertura Vacinal", "Pico Mensal de Casos"]
kpi_values = [f"{kpis[0]:,.0f}", f"{kpis[1]:,.0f}", f"{kpis[2]:.1f}%", f"{kpis[3]:,.0f}"]
table = axes[1,0].table(cellText=[[l, v] for l, v in zip(kpi_labels, kpi_values)],
                         colLabels=["Indicador", "Valor"],
                         cellLoc="center", loc="center")
table.auto_set_font_size(False)
table.set_fontsize(11)
table.scale(1.2, 2)
axes[1,0].set_title("KPIs Finais da Pandemia no Brasil")

# Subplot 4: mortes por fase (barras horizontais)
df4a_sorted = df4a.sort_values("total_mortes")
cores_sorted = [CORES_FASE.get(f, "#CCCCCC") for f in df4a_sorted["phase_name"]]
axes[1,1].barh(df4a_sorted["phase_name"], df4a_sorted["total_mortes"], color=cores_sorted)
axes[1,1].set_title("Total de Mortes por Fase")
axes[1,1].set_xlabel("Mortes")

plt.tight_layout()
plt.savefig(f"{OUT_DIR}/grafico_4_dashboard_brasil.png", dpi=150, bbox_inches="tight")
plt.close()

fig4 = make_subplots(rows=2, cols=2,
    subplot_titles=("Casos e Mortes por Fase", "Taxa de Reprodução (Rt)",
                    "KPIs Finais", "Mortes por Fase"))
fig4.add_trace(go.Bar(x=df4a["phase_name"], y=df4a["total_casos"],
    name="Casos", marker_color=cores_lista), row=1, col=1)
fig4.add_trace(go.Bar(x=df4a["phase_name"], y=df4a["total_mortes"],
    name="Mortes", marker_color=cores_lista), row=1, col=1)
if len(df4c) > 0:
    fig4.add_trace(go.Scatter(x=df4c["year_month"], y=df4c["rt"],
        line=dict(color="#E63946", width=2), name="Rt"), row=1, col=2)
fig4.update_layout(title="Dashboard COVID-19 — Brasil (2020–2024)", height=800)
fig4.write_html(f"{OUT_DIR}/grafico_4_dashboard_brasil.html")
print("   ✅ Salvo!\n")

con.close()
print("🎉 Todos os gráficos gerados com sucesso!")
print(f"   Arquivos salvos em: ./{OUT_DIR}/")
