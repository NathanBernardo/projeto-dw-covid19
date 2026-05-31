-- ============================================================
-- SCRIPT 03 - ETL LOAD (Carga dos Dados)
-- Objetivo: Popular as tabelas do DW.
-- Idempotente: pode rodar várias vezes sem duplicar dados.
-- ============================================================


-- ============================================================
-- PASSO 1: CARREGAR dim_date
-- ============================================================
DELETE FROM dim_date;

INSERT INTO dim_date
SELECT
    CAST(strftime(d, '%Y%m%d') AS INTEGER)   AS date_key,
    d                                         AS date,
    YEAR(d)                                   AS year,
    MONTH(d)                                  AS month,
    CASE MONTH(d)
        WHEN 1  THEN 'Janeiro'   WHEN 2  THEN 'Fevereiro'
        WHEN 3  THEN 'Março'     WHEN 4  THEN 'Abril'
        WHEN 5  THEN 'Maio'      WHEN 6  THEN 'Junho'
        WHEN 7  THEN 'Julho'     WHEN 8  THEN 'Agosto'
        WHEN 9  THEN 'Setembro'  WHEN 10 THEN 'Outubro'
        WHEN 11 THEN 'Novembro'  WHEN 12 THEN 'Dezembro'
    END                                       AS month_name,
    QUARTER(d)                                AS quarter,
    WEEKOFYEAR(d)                             AS week,
    DAY(d)                                    AS day,
    CASE DAYOFWEEK(d)
        WHEN 0 THEN 'Domingo'
        WHEN 1 THEN 'Segunda'
        WHEN 2 THEN 'Terça'
        WHEN 3 THEN 'Quarta'
        WHEN 4 THEN 'Quinta'
        WHEN 5 THEN 'Sexta'
        WHEN 6 THEN 'Sábado'
        ELSE 'Desconhecido'
    END                                       AS day_of_week,
    DAYOFWEEK(d) IN (0, 6)                    AS is_weekend
FROM (
    SELECT CAST(range AS DATE) AS d
    FROM range(DATE '2020-01-01', DATE '2025-01-01', INTERVAL '1 day')
) dates;

SELECT 'dim_date' AS tabela, COUNT(*) AS registros_carregados FROM dim_date;


-- ============================================================
-- PASSO 2: CARREGAR dim_pandemic_phase
-- ============================================================
DELETE FROM dim_pandemic_phase;

INSERT INTO dim_pandemic_phase VALUES
    (1, 'Pré-Pandemia',          1, 'Antes do primeiro caso no Brasil (antes de fev/2020)'),
    (2, 'Primeira Onda',         2, 'Início da pandemia no Brasil (mar/2020 – dez/2020)'),
    (3, 'Segunda Onda',          3, 'Pico com variante Gama — a mais letal (jan/2021 – jul/2021)'),
    (4, 'Vacinação em Massa',    4, 'Expansão da vacinação e queda de mortes (ago/2021 – dez/2021)'),
    (5, 'Ômicron',               5, 'Alta de casos com menor mortalidade (jan/2022 – jun/2022)'),
    (6, 'Fase Endêmica',         6, 'COVID como doença endêmica, controle estabelecido (jul/2022 em diante)');

SELECT 'dim_pandemic_phase' AS tabela, COUNT(*) AS registros_carregados FROM dim_pandemic_phase;


-- ============================================================
-- PASSO 3: CARREGAR dim_location COM SCD TYPE 2
-- ============================================================
DELETE FROM dim_location;

CREATE SEQUENCE IF NOT EXISTS seq_location_key START 1;

INSERT INTO dim_location
SELECT
    nextval('seq_location_key')  AS location_key,
    iso_code,
    location,
    continent,
    CAST(population AS BIGINT)   AS population,
    human_development_index,
    DATE '2020-01-01'            AS start_date,
    NULL                         AS end_date,
    TRUE                         AS is_current
FROM oltp_location
ORDER BY iso_code;

SELECT 'dim_location' AS tabela, COUNT(*) AS registros_carregados FROM dim_location;


-- ============================================================
-- PASSO 4: CARREGAR fact_covid
-- ============================================================
DELETE FROM fact_covid;

INSERT INTO fact_covid
SELECT
    ROW_NUMBER() OVER (ORDER BY s.data, s.iso_code)   AS fact_key,
    CAST(strftime(s.data, '%Y%m%d') AS INTEGER)        AS date_key,
    dl.location_key,
    CASE
        WHEN s.data < DATE '2020-02-26' THEN 1
        WHEN s.data <= DATE '2020-12-31' THEN 2
        WHEN s.data <= DATE '2021-07-31' THEN 3
        WHEN s.data <= DATE '2021-12-31' THEN 4
        WHEN s.data <= DATE '2022-06-30' THEN 5
        ELSE 6
    END                                                AS phase_key,
    s.new_cases,
    s.total_cases,
    s.new_deaths,
    s.total_deaths,
    s.new_vaccinations,
    s.total_vaccinations,
    s.people_vaccinated,
    s.hosp_patients,
    s.reproduction_rate
FROM oltp_daily_stats s
JOIN dim_location dl
    ON s.iso_code = dl.iso_code
    AND dl.is_current = TRUE
JOIN dim_date dd
    ON CAST(strftime(s.data, '%Y%m%d') AS INTEGER) = dd.date_key;

SELECT 'fact_covid' AS tabela, COUNT(*) AS registros_carregados FROM fact_covid;


-- ============================================================
-- VALIDAÇÕES FINAIS
-- ============================================================
SELECT 'Fatos sem data válida' AS validacao, COUNT(*) AS problemas
FROM fact_covid f
LEFT JOIN dim_date d ON f.date_key = d.date_key
WHERE d.date_key IS NULL;

SELECT 'Fatos sem país válido' AS validacao, COUNT(*) AS problemas
FROM fact_covid f
LEFT JOIN dim_location dl ON f.location_key = dl.location_key
WHERE dl.location_key IS NULL;

SELECT
    dp.phase_name,
    COUNT(*)              AS dias_registrados,
    SUM(f.new_cases)      AS total_casos,
    SUM(f.new_deaths)     AS total_mortes
FROM fact_covid f
JOIN dim_location     dl ON f.location_key = dl.location_key
JOIN dim_pandemic_phase dp ON f.phase_key   = dp.phase_key
WHERE dl.iso_code = 'BRA'
GROUP BY dp.phase_name, dp.phase_order
ORDER BY dp.phase_order;
