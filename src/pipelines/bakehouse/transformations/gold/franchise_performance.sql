-- Gold: one row per franchise, including geography for the map widget.
-- Built from the franchise dimension with a LEFT JOIN so a franchise with no
-- sales still appears (with zeros) instead of silently vanishing.
CREATE OR REFRESH MATERIALIZED VIEW ${medallion_catalog}.${gold_schema}.franchise_performance
COMMENT "Per-franchise revenue, orders, average ticket and geography."
TBLPROPERTIES ('quality' = 'gold', 'medallion.layer' = 'gold')
AS
WITH sales AS (
  SELECT
    franchise_id,
    COUNT(*)                    AS orders,
    COUNT(DISTINCT customer_id) AS unique_customers,
    SUM(quantity)               AS units_sold,
    SUM(total_price)            AS revenue,
    MIN(transaction_date)       AS first_sale_date,
    MAX(transaction_date)       AS last_sale_date
  FROM ${medallion_catalog}.${silver_schema}.transactions
  GROUP BY franchise_id
)
SELECT
  f.franchise_id,
  f.franchise_name,
  f.city,
  f.district,
  f.country,
  f.franchise_size,
  f.latitude,
  f.longitude,
  COALESCE(s.orders, 0)                                             AS orders,
  COALESCE(s.unique_customers, 0)                                   AS unique_customers,
  COALESCE(s.units_sold, 0)                                         AS units_sold,
  CAST(COALESCE(s.revenue, 0) AS DECIMAL(18, 2))                    AS revenue,
  CAST(COALESCE(s.revenue, 0) / NULLIF(s.orders, 0) AS DECIMAL(12, 2)) AS avg_ticket,
  s.first_sale_date,
  s.last_sale_date,
  COALESCE(s.orders, 0) > 0                                         AS is_active,
  RANK() OVER (ORDER BY COALESCE(s.revenue, 0) DESC)                AS revenue_rank
FROM ${medallion_catalog}.${silver_schema}.franchises f
LEFT JOIN sales s ON f.franchise_id = s.franchise_id;
