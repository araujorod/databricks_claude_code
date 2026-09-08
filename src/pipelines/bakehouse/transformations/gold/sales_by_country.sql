-- Gold: country roll-up. Country is the standardised value from silver, so
-- the United States is a single row rather than 'US' plus 'USA'.
CREATE OR REFRESH MATERIALIZED VIEW ${medallion_catalog}.${gold_schema}.sales_by_country
COMMENT "Revenue, orders, average ticket and franchise count per country."
TBLPROPERTIES ('quality' = 'gold', 'medallion.layer' = 'gold')
AS SELECT
  franchise_country                                         AS country,
  COUNT(DISTINCT franchise_id)                              AS franchises,
  COUNT(DISTINCT customer_id)                               AS unique_customers,
  COUNT(*)                                                  AS orders,
  SUM(quantity)                                             AS units_sold,
  CAST(SUM(total_price) AS DECIMAL(18, 2))                  AS revenue,
  CAST(SUM(total_price) / COUNT(*) AS DECIMAL(12, 2))       AS avg_ticket,
  CAST(SUM(total_price) / COUNT(DISTINCT franchise_id) AS DECIMAL(18, 2)) AS revenue_per_franchise
FROM ${medallion_catalog}.${silver_schema}.transactions
GROUP BY ALL;
