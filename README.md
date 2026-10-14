# goit-rdb-fp

Фінальний проєкт курсу Relational Databases for DS.

- **Дані:** `data/infectious_cases.csv` (10 521 рядок, 245 сутностей, 1920–2023), імпорт через `COPY` у `pandemic.infectious_cases`.
- **Файли:** `fp.ipynb` (notebook з output), `fp.sql` (усі SQL-запити), `screenshots/task1–5.png`.

## Виконання

1. Схема `pandemic`, `SET search_path TO pandemic`, імпорт CSV у `infectious_cases`.
2. Нормалізація до 3НФ: `entities` (унікальні `entity` + `code`, 245 рядків) і `infectious_cases_norm` (показники з `entity_id` FK, 10 521 рядок).
3. AVG / MIN / MAX / SUM для `number_rabies` по кожній сутності, сортування за середнім за спаданням, 10 рядків.
4. `MAKE_DATE(year, 1, 1)`, `CURRENT_DATE` і різниця в роках через `AGE`.
5. Функції `years_since(year)` і `avg_cases_per_period(cases, divider)`, використані з дільниками 12, 4, 2.

## Запуск

Відкрити `fp.ipynb` у Google Colab і виконати Runtime → Restart and run all. PostgreSQL 16 запускається через `pgserver`.
