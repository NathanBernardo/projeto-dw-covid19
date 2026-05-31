-- ============================================================
-- SCRIPT 05 - PERFORMANCE E OTIMIZAÇÃO (Bônus)
-- Cria tabela agregada mensal para acelerar as queries.
-- ============================================================

DROP TABLE IF EXISTS agg_monthly_brazil;

-- Tabela pré-calculada: métricas mensais do Brasil
-- Evita somar ~1700 linhas de fact_covid a cada query
CREATE TABLE agg_monthly_brazil AS
SELECT
    strftime(dd.date, '%Y-%m')          AS year_month,
    dd.year,
    dd.month,
    dd.month_name,
    dp.phase_name,
    dp.phase_order,

    SUM(f.new_cases)                    AS monthly_new_cases,
    MAX(f.total_cases)                  AS total_cases_eom,
    SUM(f.new_deaths)                   AS monthly_new_deaths,
    MAX(f.total_deaths)                 AS total_deaths_eom,
    SUM(f.new_vaccinations)             AS monthly_new_vaccinations,
    MAX(f.people_vaccinated)            AS people_vaccinated_eom,
    ROUND(
        MAX(f.people_vaccinated) / MAX(dl.population) * 100, 1
    )                                   AS pct_vaccinated_eom,
    ROUND(AVG(f.reproduction_rate), 2)  AS avg_reproduction_rate,
    ROUND(
        CASE WHEN SUM(f.new_cases) > 0
            THEN SUM(f.new_deaths) / SUM(f.new_cases) * 100
            ELSE 0
        END, 3
    )                                   AS case_fatality_rate_pct

FROM fact_covid f
JOIN dim_location       dl ON f.location_key = dl.location_key
JOIN dim_date           dd ON f.date_key     = dd.date_key
JOIN dim_pandemic_phase dp ON f.phase_key    = dp.phase_key
WHERE dl.iso_code = 'BRA'
GROUP BY year_month, dd.year, dd.month, dd.month_name, dp.phase_name, dp.phase_order
ORDER BY year_month;

CREATE INDEX IF NOT EXISTS idx_agg_ym ON agg_monthly_brazil(year_month);

SELECT 'agg_monthly_brazil criada' AS status, COUNT(*) AS meses FROM agg_monthly_brazil;


-- ── COMPARAÇÃO DE PERFORMANCE ─────────────────────────────

-- ANTES: query direta na fact_covid (percorre ~300k linhas)
EXPLAIN ANALYZE
SELECT strftime(dd.date, '%Y-%m') AS ano_mes, SUM(f.new_deaths) AS mortes
FROM fact_covid f
JOIN dim_location dl ON f.location_key = dl.location_key
JOIN dim_date     dd ON f.date_key     = dd.date_key
WHERE dl.iso_code = 'BRA'
GROUP BY ano_mes ORDER BY ano_mes;

-- DEPOIS: query na tabela agregada (~56 linhas)
EXPLAIN ANALYZE
SELECT year_month AS ano_mes, monthly_new_deaths AS mortes
FROM agg_monthly_brazil
ORDER BY year_month;
