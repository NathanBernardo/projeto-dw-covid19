-- ============================================================
-- SCRIPT 01 - OLTP (Tabelas Normalizadas)
-- Objetivo: Organizar os dados brutos em tabelas limpas,
--           removendo duplicatas e tratando NULLs.
-- Foco: dados do Brasil + dados globais para contexto.
-- ============================================================

-- ------------------------------------------------------------
-- TABELA: oltp_location
-- Informações únicas de cada país/região
-- ------------------------------------------------------------
DROP TABLE IF EXISTS oltp_location;

CREATE TABLE oltp_location AS
SELECT DISTINCT
    iso_code,
    continent,
    location,
    MAX(TRY_CAST(population              AS DOUBLE)) AS population,
    MAX(TRY_CAST(human_development_index AS DOUBLE)) AS human_development_index
FROM stg_covid
WHERE continent IS NOT NULL
  AND iso_code NOT LIKE 'OWID_%'
GROUP BY iso_code, continent, location;

SELECT 'oltp_location' AS tabela, COUNT(*) AS registros FROM oltp_location;


-- ------------------------------------------------------------
-- TABELA: oltp_daily_stats
-- Uma linha por país + data com as métricas do dia
-- ------------------------------------------------------------
DROP TABLE IF EXISTS oltp_daily_stats;

CREATE TABLE oltp_daily_stats AS
SELECT
    iso_code,
    location,
    TRY_CAST(date AS DATE)                              AS data,

    -- Casos
    COALESCE(TRY_CAST(new_cases    AS DOUBLE), 0)       AS new_cases,
    COALESCE(TRY_CAST(total_cases  AS DOUBLE), 0)       AS total_cases,

    -- Mortes
    COALESCE(TRY_CAST(new_deaths   AS DOUBLE), 0)       AS new_deaths,
    COALESCE(TRY_CAST(total_deaths AS DOUBLE), 0)       AS total_deaths,

    -- Vacinação
    COALESCE(TRY_CAST(new_vaccinations          AS DOUBLE), 0) AS new_vaccinations,
    COALESCE(TRY_CAST(total_vaccinations        AS DOUBLE), 0) AS total_vaccinations,
    COALESCE(TRY_CAST(people_vaccinated         AS DOUBLE), 0) AS people_vaccinated,
    TRY_CAST(people_vaccinated_per_hundred      AS DOUBLE)     AS people_vaccinated_pct,
    TRY_CAST(people_fully_vaccinated_per_hundred AS DOUBLE)    AS people_fully_vaccinated_pct,

    -- Hospitalização
    COALESCE(TRY_CAST(hosp_patients AS DOUBLE), 0)      AS hosp_patients,

    -- Indicadores
    TRY_CAST(reproduction_rate AS DOUBLE)               AS reproduction_rate

FROM stg_covid
WHERE continent IS NOT NULL
  AND iso_code NOT LIKE 'OWID_%'
  AND date IS NOT NULL;

SELECT 'oltp_daily_stats' AS tabela, COUNT(*) AS registros FROM oltp_daily_stats;

-- Confere Brasil
SELECT data, new_cases, new_deaths, people_vaccinated_pct
FROM oltp_daily_stats
WHERE iso_code = 'BRA'
ORDER BY data DESC
LIMIT 5;
