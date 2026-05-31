# 🦠 Data Warehouse COVID-19 — Brasil (2020–2024)

> Projeto acadêmico desenvolvido na disciplina **Banco e Armazém de Dados em Ciências de Dados** — FATEC Jundiaí (Deputado Ary Fossen)

## 🔗 [Ver painel de resultados analíticos →](https://SEU-USUARIO.github.io/projeto-dw-covid19)

---

## 👥 Integrantes

| Nome |
|------|
| Mariana Costa de Mello |
| Michelle de Sales Silva |
| Nathan Bernardo Novais de Melo |
| Stephan Lucca Melo dos Santos |

---

##  Sobre o Projeto

Este projeto implementa um **Data Warehouse completo** para análise da pandemia de COVID-19 no Brasil, utilizando dados públicos da [Our World in Data (OWID)](https://github.com/owid/covid-19-data/tree/master/public/data).

O pipeline cobre todas as etapas de um projeto real de engenharia de dados:

```
CSV bruto (429k linhas)
    → Staging (VIEW)
    → OLTP normalizado
    → Modelo Estrela (DW)
    → ETL
    → Consultas analíticas
    → Visualizações Python
```

---

## 🗂️ Estrutura do Repositório

```
projeto-dw-covid19/
├── index.html                       ← página de resultados (GitHub Pages)
├── data/
│   └── owid-covid-data.csv          ← baixar separadamente (ver instruções)
├── scripts/
│   ├── 00_staging.sql               ← lê o CSV e cria VIEW stg_covid
│   ├── 01_oltp.sql                  ← normalização em tabelas OLTP
│   ├── 02_dw_model.sql              ← DDL do modelo estrela
│   ├── 03_etl_load.sql              ← ETL: popula dimensões e fato
│   ├── 04_analytics.sql             ← 5 consultas analíticas
│   └── 05_performance.sql           ← tabela agregada + EXPLAIN ANALYZE
├── visualizacoes/
│   ├── gerar_graficos.py            ← gera 4 gráficos (PNG + HTML)
│   ├── grafico_1_evolucao_brasil.png
│   ├── grafico_2_top10_mortes.png
│   ├── grafico_3_heatmap_mortalidade.png
│   └── grafico_4_dashboard_brasil.png
├── docs/
│   └── dicionario_dados.md
└── relatorio_final_dw_covid19.docx
```

> ⚠️ O arquivo `owid-covid-data.csv` (~94MB) e o banco `covid_dw.duckdb` **não estão no repositório**. Baixe o CSV conforme instruções abaixo.

---

##  Modelo Estrela

```
              dim_date
           (date_key: YYYYMMDD)
                  │
  dim_location ───┼─── fact_covid ───── dim_pandemic_phase
  (SCD Type 2)    │    (fato central)      (phase_key)
             [location_key]
```

### Tabelas

| Tabela | Tipo | Registros |
|--------|------|-----------|
| `dim_date` | Dimensão de Data | 1.827 linhas (2020–2024) |
| `dim_location` | Dimensão de Localização (SCD Type 2) | 237 países/regiões |
| `dim_pandemic_phase` | Dimensão de Fase da Pandemia | 6 fases |
| `fact_covid` | Tabela Fato (granularidade: país × dia) | 395.311 linhas |

### Fases da Pandemia

| # | Fase | Período |
|---|------|---------|
| 1 | Pré-Pandemia | Antes de fev/2020 |
| 2 | Primeira Onda | Mar/2020 – Dez/2020 |
| 3 | Segunda Onda | Jan/2021 – Jul/2021 |
| 4 | Vacinação em Massa | Ago/2021 – Dez/2021 |
| 5 | Ômicron | Jan/2022 – Jun/2022 |
| 6 | Fase Endêmica | Jul/2022 em diante |

---

## ⚙️ Como Executar

### Pré-requisitos

| Ferramenta | Versão recomendada |
|---|---|
| [DuckDB CLI](https://duckdb.org/docs/installation/) | v1.x |
| Python | 3.10+ |
| pandas, matplotlib, plotly, seaborn, duckdb (Python) | qualquer versão recente |

### 1. Baixar o dataset

```
https://github.com/owid/covid-19-data/blob/master/public/data/owid-covid-data.csv
Salvar em: data/owid-covid-data.csv
```

### 2. Abrir o DuckDB

```powershell
cd C:\caminho\para\projeto-dw-covid19
duckdb covid_dw.duckdb
```

### 3. Executar os scripts em ordem

```sql
.read scripts/00_staging.sql
.read scripts/01_oltp.sql
.read scripts/02_dw_model.sql
.read scripts/03_etl_load.sql
.read scripts/04_analytics.sql
.read scripts/05_performance.sql
```

> ⚠️ Se rodar o script 03 mais de uma vez:
> ```sql
> DROP SEQUENCE IF EXISTS seq_location_key;
> ```

### 4. Gerar os gráficos

```bash
pip install duckdb plotly pandas seaborn matplotlib
python visualizacoes/gerar_graficos.py
```

---

##  Principais Resultados — Brasil

| Indicador | Valor |
|-----------|-------|
| Total de casos acumulados | ~37,5 milhões |
| Total de mortes acumuladas | 702.116 |
| Pico diário de casos | 1.283.024 (30/01/2022 — Ômicron) |
| Cobertura vacinal final | 88,1% |
| Período coberto | 05/01/2020 a 04/08/2024 (1.673 dias) |

---

##  Performance

| Abordagem | Tabela | Linhas | Tempo |
|-----------|--------|--------|-------|
| Sem otimização | `fact_covid` + JOINs | ~395.000 | 0,0338s |
| Com otimização | `agg_monthly_brazil` | ~57 | 0,0011s |

~31× mais rápido em tempo · redução de ~5.300× nas linhas percorridas

---

##  Informações Acadêmicas

- **Instituição:** FATEC Jundiaí — Deputado Ary Fossen
- **Curso:** Tecnologia em Ciência de Dados
- **Disciplina:** Banco e Armazém de Dados em Ciências de Dados
- **Ano:** 2026
