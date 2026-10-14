-- 1. Завантаження даних

CREATE SCHEMA IF NOT EXISTS pandemic;
SET search_path TO pandemic;

DROP TABLE IF EXISTS infectious_cases_norm CASCADE;
DROP TABLE IF EXISTS entities CASCADE;
DROP TABLE IF EXISTS infectious_cases CASCADE;

CREATE TABLE infectious_cases (
    entity TEXT,
    code TEXT,
    year TEXT,
    number_yaws TEXT,
    polio_cases TEXT,
    cases_guinea_worm TEXT,
    number_rabies TEXT,
    number_malaria TEXT,
    number_hiv TEXT,
    number_tuberculosis TEXT,
    number_smallpox TEXT,
    number_cholera_cases TEXT
);

-- \copy infectious_cases FROM 'data/infectious_cases.csv' WITH (FORMAT csv, HEADER true)

SELECT COUNT(*) AS n_rows,
       COUNT(DISTINCT entity) AS n_entities,
       MIN(year::INTEGER) AS min_year,
       MAX(year::INTEGER) AS max_year,
       COUNT(*) FILTER (WHERE number_rabies IS NULL) AS rabies_missing
FROM infectious_cases;

SELECT *
FROM infectious_cases
LIMIT 5;

-- 2. Нормалізація

CREATE TABLE entities (
    entity_id SERIAL PRIMARY KEY,
    entity TEXT NOT NULL,
    code TEXT,
    UNIQUE NULLS NOT DISTINCT (entity, code)
);

INSERT INTO entities (entity, code)
SELECT DISTINCT entity, NULLIF(code, '')
FROM infectious_cases
ORDER BY entity;

CREATE TABLE infectious_cases_norm (
    case_id SERIAL PRIMARY KEY,
    entity_id INTEGER NOT NULL REFERENCES entities(entity_id),
    year SMALLINT NOT NULL,
    number_yaws NUMERIC,
    polio_cases NUMERIC,
    cases_guinea_worm NUMERIC,
    number_rabies NUMERIC,
    number_malaria NUMERIC,
    number_hiv NUMERIC,
    number_tuberculosis NUMERIC,
    number_smallpox NUMERIC,
    number_cholera_cases NUMERIC,
    UNIQUE (entity_id, year)
);

INSERT INTO infectious_cases_norm (
    entity_id, year, number_yaws, polio_cases, cases_guinea_worm, number_rabies,
    number_malaria, number_hiv, number_tuberculosis, number_smallpox, number_cholera_cases
)
SELECT
    e.entity_id,
    ic.year::SMALLINT,
    NULLIF(ic.number_yaws, '')::NUMERIC,
    NULLIF(ic.polio_cases, '')::NUMERIC,
    NULLIF(ic.cases_guinea_worm, '')::NUMERIC,
    NULLIF(ic.number_rabies, '')::NUMERIC,
    NULLIF(ic.number_malaria, '')::NUMERIC,
    NULLIF(ic.number_hiv, '')::NUMERIC,
    NULLIF(ic.number_tuberculosis, '')::NUMERIC,
    NULLIF(ic.number_smallpox, '')::NUMERIC,
    NULLIF(ic.number_cholera_cases, '')::NUMERIC
FROM infectious_cases AS ic
JOIN entities AS e
  ON e.entity = ic.entity
 AND e.code IS NOT DISTINCT FROM NULLIF(ic.code, '');

SELECT 'infectious_cases' AS table_name, COUNT(*) AS n_rows FROM infectious_cases
UNION ALL SELECT 'entities', COUNT(*) FROM entities
UNION ALL SELECT 'infectious_cases_norm', COUNT(*) FROM infectious_cases_norm;

SELECT e.entity_id, e.entity, e.code, n.year, n.number_rabies, n.number_malaria
FROM infectious_cases_norm AS n
JOIN entities AS e ON e.entity_id = n.entity_id
ORDER BY e.entity, n.year
LIMIT 5;

-- 3. Аналіз Number_rabies

SELECT
    e.entity_id,
    e.entity,
    e.code,
    ROUND(AVG(n.number_rabies), 2) AS avg_rabies,
    ROUND(MIN(n.number_rabies), 2) AS min_rabies,
    ROUND(MAX(n.number_rabies), 2) AS max_rabies,
    ROUND(SUM(n.number_rabies), 2) AS sum_rabies
FROM infectious_cases_norm AS n
JOIN entities AS e ON e.entity_id = n.entity_id
WHERE n.number_rabies IS NOT NULL
GROUP BY e.entity_id, e.entity, e.code
ORDER BY AVG(n.number_rabies) DESC
LIMIT 10;

-- 4. Різниця в роках

SELECT
    year,
    MAKE_DATE(year, 1, 1) AS year_start_date,
    CURRENT_DATE AS today,
    EXTRACT(YEAR FROM AGE(CURRENT_DATE, MAKE_DATE(year, 1, 1)))::INTEGER AS years_diff
FROM infectious_cases_norm
ORDER BY entity_id, year
LIMIT 10;

-- 5. Власні функції

CREATE OR REPLACE FUNCTION years_since(p_year INTEGER)
RETURNS INTEGER
LANGUAGE SQL
STABLE
AS $$
    SELECT EXTRACT(YEAR FROM AGE(CURRENT_DATE, MAKE_DATE(p_year, 1, 1)))::INTEGER;
$$;

CREATE OR REPLACE FUNCTION avg_cases_per_period(p_cases NUMERIC, p_divider INTEGER)
RETURNS NUMERIC
LANGUAGE SQL
IMMUTABLE
AS $$
    SELECT p_cases / NULLIF(p_divider, 0);
$$;

SELECT
    year,
    MAKE_DATE(year, 1, 1) AS year_start_date,
    years_since(year) AS years_diff
FROM infectious_cases_norm
ORDER BY entity_id, year
LIMIT 10;

SELECT
    e.entity,
    n.year,
    n.number_rabies,
    ROUND(avg_cases_per_period(n.number_rabies, 12), 4) AS avg_per_month,
    ROUND(avg_cases_per_period(n.number_rabies, 4), 4) AS avg_per_quarter,
    ROUND(avg_cases_per_period(n.number_rabies, 2), 4) AS avg_per_half_year
FROM infectious_cases_norm AS n
JOIN entities AS e ON e.entity_id = n.entity_id
WHERE n.number_rabies IS NOT NULL
ORDER BY n.number_rabies DESC
LIMIT 10;

