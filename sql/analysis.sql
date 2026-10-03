-- Automotive Market & Competitor Analysis
-- Engine: SQLite. Data: KBA portal export supplied by the user.
-- Each source row represents one model family, segment and calendar month.
-- Counts are registrations, not sales. Only 2025 records were imported.

DROP VIEW IF EXISTS selected_models;
CREATE VIEW selected_models AS
SELECT * FROM registrations
WHERE year = 2025 AND segment = 'KOMPAKTKLASSE'
  AND ((brand = 'AUDI' AND model = 'A3')
    OR (brand = 'BMW' AND model = '1ER')
    OR (brand = 'MERCEDES' AND model = 'A-KLASSE'));

-- Q1: How do full-year registration volumes compare?
-- Peer share refers only to the three selected model families.
-- name: model_totals
SELECT brand, model, SUM(registrations) AS annual_registrations,
       ROUND(100.0 * SUM(registrations) /
         (SELECT SUM(registrations) FROM selected_models), 2) AS peer_group_share_pct
FROM selected_models
GROUP BY brand, model
ORDER BY annual_registrations DESC;

-- Q2: How did each model's registrations change across months?
-- name: monthly_trends
SELECT month_number, month_start, month_name, brand, model,
       SUM(registrations) AS registrations
FROM selected_models
GROUP BY month_number, month_start, month_name, brand, model
ORDER BY month_number, brand;

-- Q3: What share of the full compact segment did each selected model have?
-- All brands/models in KOMPAKTKLASSE form the denominator, including residual categories.
-- name: segment_shares
WITH segment_total AS (
  SELECT SUM(registrations) AS total
  FROM registrations WHERE segment = 'KOMPAKTKLASSE'
)
SELECT s.brand, s.model, SUM(s.registrations) AS annual_registrations,
       t.total AS compact_segment_registrations,
       ROUND(100.0 * SUM(s.registrations) / t.total, 2) AS segment_share_pct
FROM selected_models s CROSS JOIN segment_total t
GROUP BY s.brand, s.model, t.total
ORDER BY annual_registrations DESC;

-- Q4: Was the second half stronger than the first half?
-- Equal six-month periods; this is not year-over-year growth.
-- name: half_year_comparison
WITH periods AS (
  SELECT brand, model,
    SUM(CASE WHEN month_number <= 6 THEN registrations ELSE 0 END) AS h1,
    SUM(CASE WHEN month_number >= 7 THEN registrations ELSE 0 END) AS h2
  FROM selected_models GROUP BY brand, model
)
SELECT brand, model, h1 AS h1_registrations, h2 AS h2_registrations,
       h2 - h1 AS change_in_registrations,
       ROUND(100.0 * (h2 - h1) / NULLIF(h1, 0), 2) AS h2_vs_h1_change_pct
FROM periods ORDER BY brand;

-- Q5: Which month had the highest registrations for each model?
-- The join retains ties rather than arbitrarily picking one month.
-- name: peak_months
WITH monthly AS (
  SELECT brand, model, month_number, month_name, SUM(registrations) AS total
  FROM selected_models GROUP BY brand, model, month_number, month_name
), peaks AS (
  SELECT brand, model, MAX(total) AS peak_total
  FROM monthly GROUP BY brand, model
)
SELECT m.brand, m.model, m.month_number, m.month_name, m.total AS registrations
FROM monthly m JOIN peaks p
  ON m.brand = p.brand AND m.model = p.model AND m.total = p.peak_total
ORDER BY m.brand, m.month_number;

-- Q6: How does Audi's monthly segment share compare with its peers?
-- name: monthly_segment_shares
WITH totals AS (
  SELECT month_number, SUM(registrations) AS segment_total
  FROM registrations WHERE segment = 'KOMPAKTKLASSE'
  GROUP BY month_number
)
SELECT s.month_number, s.month_start, s.brand, s.model,
       SUM(s.registrations) AS registrations, t.segment_total,
       ROUND(100.0 * SUM(s.registrations) / t.segment_total, 2) AS segment_share_pct
FROM selected_models s JOIN totals t ON s.month_number = t.month_number
GROUP BY s.month_number, s.month_start, s.brand, s.model, t.segment_total
ORDER BY s.month_number, s.brand;
