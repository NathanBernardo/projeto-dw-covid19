-- ============================================================
-- SCRIPT 00 - STAGING
-- Objetivo: Ler o CSV bruto e criar uma view de staging.
-- Neste passo NÃO transformamos nada — só "enxergamos" os dados.
-- ============================================================

-- INSTRUÇÃO: Altere o caminho abaixo para onde está seu CSV!
-- Windows: 'C:/Users/SeuNome/Downloads/owid-covid-data.csv'
-- Mac/Linux: '/home/seunome/Downloads/owid-covid-data.csv'

DROP VIEW IF EXISTS stg_covid;

CREATE VIEW stg_covid AS
SELECT *
FROM read_csv_auto(
    'C:/Users/Nathan/Downloads/projeto-dw-covid19/data/owid-covid-data.csv',  -- << ALTERE AQUI
    header = true,
    nullstr = ''                    -- campos vazios viram NULL
);

-- Verificação: mostra quantas linhas foram lidas
SELECT 
    COUNT(*)                    AS total_linhas,
    COUNT(DISTINCT location)    AS total_paises,
    MIN(date)                   AS data_mais_antiga,
    MAX(date)                   AS data_mais_recente
FROM stg_covid;

-- Confere colunas principais
SELECT iso_code, continent, location, date, new_cases, new_deaths, new_vaccinations
FROM stg_covid
LIMIT 3;
