# Dicionário de Dados
## Projeto: Evolução da Pandemia de COVID-19 no Brasil

---

## Tabela: fact_covid
| Coluna | Tipo | Descrição |
|---|---|---|
| fact_key | INTEGER | Chave primária da tabela fato |
| date_key | INTEGER | Chave estrangeira para dim_date |
| location_key | INTEGER | Chave estrangeira para dim_location |
| phase_key | INTEGER | Chave estrangeira para dim_pandemic_phase |
| new_cases | DOUBLE | Casos novos registrados no dia |
| new_deaths | DOUBLE | Mortes novas registradas no dia |
| total_cases | DOUBLE | Total acumulado de casos |
| total_deaths | DOUBLE | Total acumulado de mortes |
| new_vaccinations | DOUBLE | Doses aplicadas no dia |
| total_vaccinations | DOUBLE | Total acumulado de doses aplicadas |
| people_vaccinated | DOUBLE | Total de pessoas vacinadas com ao menos 1 dose |
| reproduction_rate | DOUBLE | Taxa de reprodução do vírus (Rt) |
| hosp_patients | DOUBLE | Pacientes hospitalizados no dia |

---

## Tabela: dim_date
| Coluna | Tipo | Descrição |
|---|---|---|
| date_key | INTEGER | Chave primária no formato YYYYMMDD |
| date | DATE | Data completa |
| year | INTEGER | Ano |
| month | INTEGER | Número do mês (1 a 12) |
| month_name | VARCHAR | Nome do mês em inglês |
| quarter | INTEGER | Trimestre (1 a 4) |
| week | INTEGER | Semana do ano |
| day | INTEGER | Dia do mês |
| day_of_week | VARCHAR | Nome do dia da semana |
| is_weekend | BOOLEAN | Indica se é final de semana |

---

## Tabela: dim_location
| Coluna | Tipo | Descrição |
|---|---|---|
| location_key | INTEGER | Chave primária substituta |
| iso_code | VARCHAR | Código ISO do país (ex: BRA) |
| location | VARCHAR | Nome do país |
| continent | VARCHAR | Continente |
| population | BIGINT | População do país |
| human_development_index | DOUBLE | Índice de Desenvolvimento Humano (IDH) |
| start_date | DATE | Início da vigência do registro (SCD2) |
| end_date | DATE | Fim da vigência do registro (NULL = atual) |
| is_current | BOOLEAN | Indica se o registro é o atual |

---

## Tabela: dim_pandemic_phase
| Coluna | Tipo | Descrição |
|---|---|---|
| phase_key | INTEGER | Chave primária |
| phase_name | VARCHAR | Nome da fase da pandemia |
| phase_order | INTEGER | Ordem cronológica da fase |
| description | VARCHAR | Descrição detalhada da fase |

---

## Tabela: agg_brasil_mensal
| Coluna | Tipo | Descrição |
|---|---|---|
| ano | INTEGER | Ano do registro |
| mes | INTEGER | Número do mês |
| nome_mes | VARCHAR | Nome do mês |
| fase | VARCHAR | Fase da pandemia |
| total_casos | DOUBLE | Total de casos novos no mês |
| total_mortes | DOUBLE | Total de mortes no mês |
| total_vacinacoes | DOUBLE | Total de doses aplicadas no mês |
| pessoas_vacinadas | DOUBLE | Total acumulado de pessoas vacinadas |
| taxa_mortalidade_pct | DOUBLE | Taxa de mortalidade em percentual |
