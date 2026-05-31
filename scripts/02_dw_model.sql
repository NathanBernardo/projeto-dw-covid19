-- ============================================================
-- SCRIPT 02 - MODELO DO DATA WAREHOUSE
-- Objetivo: Criar a estrutura das tabelas dimensão e fato.
--           Tabelas ficam VAZIAS aqui — o script 03 popula.
--
-- MODELO ESTRELA (conforme Checkpoint 1):
--
--   dim_date ──────────────────────────────────┐
--   dim_location (SCD Type 2) ─────────────────┤──► fact_covid
--   dim_pandemic_phase ────────────────────────┘
-- ============================================================


-- ============================================================
-- DIMENSÃO 1: dim_date
-- Cada dia com atributos úteis para filtros e agrupamentos
-- ============================================================
DROP TABLE IF EXISTS dim_date;

CREATE TABLE dim_date (
    date_key     INTEGER PRIMARY KEY,  -- formato YYYYMMDD
    date         DATE        NOT NULL,
    year         INTEGER     NOT NULL,
    month        INTEGER     NOT NULL,
    month_name   VARCHAR     NOT NULL,
    quarter      INTEGER     NOT NULL,
    week         INTEGER     NOT NULL,
    day          INTEGER     NOT NULL,
    day_of_week  VARCHAR     NOT NULL, -- 'Segunda', 'Terça'...
    is_weekend   BOOLEAN     NOT NULL
);


-- ============================================================
-- DIMENSÃO 2: dim_location  — SCD TYPE 2
-- Dados do país. SCD2 registra histórico de mudanças.
-- Campos: exatamente como definido no Checkpoint 1.
-- ============================================================
DROP TABLE IF EXISTS dim_location;

CREATE TABLE dim_location (
    location_key             INTEGER PRIMARY KEY,  -- chave substituta
    iso_code                 VARCHAR  NOT NULL,     -- chave natural (BRA, USA...)
    location                 VARCHAR  NOT NULL,
    continent                VARCHAR,
    population               BIGINT,
    human_development_index  FLOAT,
    -- Campos SCD Type 2
    start_date               DATE     NOT NULL,
    end_date                 DATE,                  -- NULL = registro atual
    is_current               BOOLEAN  NOT NULL DEFAULT TRUE
);


-- ============================================================
-- DIMENSÃO 3: dim_pandemic_phase
-- Classifica o momento da pandemia em fases.
-- Usada para analisar o comportamento antes/durante/após vacinação.
-- ============================================================
DROP TABLE IF EXISTS dim_pandemic_phase;

CREATE TABLE dim_pandemic_phase (
    phase_key    INTEGER PRIMARY KEY,
    phase_name   VARCHAR  NOT NULL,
    phase_order  INTEGER  NOT NULL,  -- ordem cronológica das fases
    description  VARCHAR
);


-- ============================================================
-- TABELA FATO: fact_covid
-- Granularidade: 1 linha por país + dia
-- Métricas: casos, mortes, vacinação, hospitalização, Rt
-- ============================================================
DROP TABLE IF EXISTS fact_covid;

CREATE TABLE fact_covid (
    fact_key             BIGINT  PRIMARY KEY,

    -- Chaves estrangeiras → dimensões
    date_key             INTEGER NOT NULL REFERENCES dim_date(date_key),
    location_key         INTEGER NOT NULL REFERENCES dim_location(location_key),
    phase_key            INTEGER          REFERENCES dim_pandemic_phase(phase_key),

    -- Casos
    new_cases            FLOAT,
    total_cases          FLOAT,

    -- Mortes
    new_deaths           FLOAT,
    total_deaths         FLOAT,

    -- Vacinação
    new_vaccinations     FLOAT,
    total_vaccinations   FLOAT,
    people_vaccinated    FLOAT,

    -- Hospitalização
    hosp_patients        FLOAT,

    -- Indicadores
    reproduction_rate    FLOAT
);


-- Confirma criação
SELECT table_name
FROM duckdb_tables()
WHERE table_name IN ('dim_date','dim_location','dim_pandemic_phase','fact_covid');
