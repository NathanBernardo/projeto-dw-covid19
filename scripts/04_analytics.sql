-- ============================================================
-- SCRIPT 04 - CONSULTAS ANALÍTICAS
-- Responde as 5 perguntas definidas no Checkpoint 1 do grupo.
-- Todas focadas no Brasil (iso_code = 'BRA').
-- ============================================================


-- ============================================================
-- CONSULTA 1 — ANÁLISE TEMPORAL
-- Pergunta: Como evoluíram os casos e mortes no Brasil ao longo
-- do tempo? É possível identificar as ondas da pandemia?
-- ============================================================
SELECT
    dd.year                                     AS ano,
    dd.month_name                               AS mes,
    strftime(dd.date, '%Y-%m')                  AS ano_mes,
    dp.phase_name                               AS fase_pandemia,
    SUM(f.new_cases)                            AS novos_casos,
    SUM(f.new_deaths)                           AS novas_mortes,
    MAX(f.total_cases)                          AS casos_acumulados,
    MAX(f.total_deaths)                         AS mortes_acumuladas,
    -- Taxa de mortalidade mensal (mortes / casos * 100)
    ROUND(
        CASE WHEN SUM(f.new_cases) > 0
            THEN SUM(f.new_deaths) / SUM(f.new_cases) * 100
            ELSE 0
        END, 2
    )                                           AS taxa_mortalidade_pct
FROM fact_covid f
JOIN dim_location      dl ON f.location_key = dl.location_key
JOIN dim_date          dd ON f.date_key     = dd.date_key
JOIN dim_pandemic_phase dp ON f.phase_key   = dp.phase_key
WHERE dl.iso_code = 'BRA'
GROUP BY dd.year, dd.month_name, ano_mes, dp.phase_name
ORDER BY ano_mes;


-- ============================================================
-- CONSULTA 2 — RANKING / TOP N
-- Pergunta: Quais foram os 10 meses com maior número de mortes
-- registradas no Brasil durante toda a pandemia?
-- ============================================================
SELECT
    strftime(dd.date, '%Y-%m')  AS ano_mes,
    dd.month_name                AS mes,
    dd.year                      AS ano,
    dp.phase_name                AS fase,
    SUM(f.new_deaths)            AS total_mortes_mes,
    SUM(f.new_cases)             AS total_casos_mes,
    -- Ranking por mortes
    RANK() OVER (ORDER BY SUM(f.new_deaths) DESC) AS ranking
FROM fact_covid f
JOIN dim_location       dl ON f.location_key = dl.location_key
JOIN dim_date           dd ON f.date_key     = dd.date_key
JOIN dim_pandemic_phase dp ON f.phase_key    = dp.phase_key
WHERE dl.iso_code = 'BRA'
GROUP BY ano_mes, dd.month_name, dd.year, dp.phase_name
ORDER BY total_mortes_mes DESC
LIMIT 10;


-- ============================================================
-- CONSULTA 3 — AGREGAÇÃO MULTIDIMENSIONAL
-- Pergunta: Como se compara a evolução da vacinação com a queda
-- de casos e mortes no Brasil, mês a mês?
-- ============================================================
SELECT
    strftime(dd.date, '%Y-%m')             AS ano_mes,
    dd.month_name                           AS mes,
    dd.year                                 AS ano,
    -- Vacinação
    SUM(f.new_vaccinations)                 AS doses_aplicadas_mes,
    MAX(f.people_vaccinated)                AS pessoas_vacinadas_acum,
    -- Cálculo do % vacinado (pessoas vacinadas / população * 100)
    ROUND(
        MAX(f.people_vaccinated) / MAX(dl.population) * 100, 1
    )                                       AS pct_populacao_vacinada,
    -- Casos e mortes
    SUM(f.new_cases)                        AS novos_casos,
    SUM(f.new_deaths)                       AS novas_mortes,
    -- Fase da pandemia naquele mês
    MAX(dp.phase_name)                      AS fase
FROM fact_covid f
JOIN dim_location       dl ON f.location_key = dl.location_key
JOIN dim_date           dd ON f.date_key     = dd.date_key
JOIN dim_pandemic_phase dp ON f.phase_key    = dp.phase_key
WHERE dl.iso_code = 'BRA'
  AND dd.year >= 2021  -- vacinação começou em 2021
GROUP BY ano_mes, dd.month_name, dd.year
ORDER BY ano_mes;


-- ============================================================
-- CONSULTA 4 — ANÁLISE DE COHORT
-- Pergunta: Como se comportou a taxa de mortalidade (mortes/casos)
-- no Brasil antes, durante e após a vacinação em massa?
-- ============================================================
SELECT
    dp.phase_order                          AS ordem,
    dp.phase_name                           AS fase,
    dp.description                          AS descricao,
    SUM(f.new_cases)                        AS total_casos_fase,
    SUM(f.new_deaths)                       AS total_mortes_fase,
    -- Taxa de mortalidade da fase inteira
    ROUND(
        CASE WHEN SUM(f.new_cases) > 0
            THEN SUM(f.new_deaths) / SUM(f.new_cases) * 100
            ELSE 0
        END, 3
    )                                       AS taxa_mortalidade_pct,
    -- Média de vacinados ao longo da fase
    ROUND(
        AVG(
            CASE WHEN f.people_vaccinated > 0
                THEN f.people_vaccinated / dl.population * 100
                ELSE 0
            END
        ), 1
    )                                       AS media_pct_vacinados
FROM fact_covid f
JOIN dim_location       dl ON f.location_key = dl.location_key
JOIN dim_pandemic_phase dp ON f.phase_key    = dp.phase_key
WHERE dl.iso_code = 'BRA'
GROUP BY dp.phase_order, dp.phase_name, dp.description
ORDER BY dp.phase_order;


-- ============================================================
-- CONSULTA 5 — KPI (Indicador-Chave)
-- Pergunta: Qual foi o pico máximo de casos diários, o total
-- acumulado de mortes e a cobertura vacinal final do Brasil?
-- ============================================================
SELECT
    -- Pico de casos em um único dia
    MAX(f.new_cases)                        AS pico_casos_dia,
    -- Data do pico
    (SELECT dd2.date
     FROM fact_covid f2
     JOIN dim_location dl2 ON f2.location_key = dl2.location_key
     JOIN dim_date     dd2 ON f2.date_key     = dd2.date_key
     WHERE dl2.iso_code = 'BRA'
     ORDER BY f2.new_cases DESC
     LIMIT 1)                               AS data_pico_casos,

    -- Total acumulado de mortes (último valor disponível)
    MAX(f.total_deaths)                     AS total_mortes_acumulado,

    -- Cobertura vacinal final (% da população com ao menos 1 dose)
    ROUND(
        MAX(f.people_vaccinated) / MAX(dl.population) * 100, 1
    )                                       AS cobertura_vacinal_pct,

    -- Período coberto pelos dados
    MIN(dd.date)                            AS primeiro_registro,
    MAX(dd.date)                            AS ultimo_registro,

    -- Duração total em dias
    DATEDIFF('day', MIN(dd.date), MAX(dd.date)) AS duracao_dias

FROM fact_covid f
JOIN dim_location dl ON f.location_key = dl.location_key
JOIN dim_date     dd ON f.date_key     = dd.date_key
WHERE dl.iso_code = 'BRA';
