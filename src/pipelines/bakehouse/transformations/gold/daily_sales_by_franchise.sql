-- Gold: daily revenue grain (date x franchise). Feeds the daily revenue
-- time series and any date-filtered widget on the dashboard.
CREATE OR REFRESH MATERIALIZED VIEW ${medallion_catalog}.${gold_schema}.daily_sales_by_franchise
CLUSTER BY (transaction_date, franchise_id)
COMMENT "Revenue, orders, units and average ticket per day and franchise."
TBLPROPERTIES ('quality' = 'gold', 'medallion.layer' = 'gold')
AS SELECT
  transaction_date,
  transaction_year,
  transaction_month,
  transaction_day,
  transaction_year_month,
  transaction_day_of_week,
  franchise_id,
  franchise_name,
  franchise_city                                            AS city,
  franchise_country                                         AS country,
  COUNT(*)                                                  AS orders,
  COUNT(DISTINCT customer_id)                               AS unique_customers,
  SUM(quantity)                                             AS units_sold,
  CAST(SUM(total_price) AS DECIMAL(18, 2))                  AS revenue,
  CAST(SUM(total_price) / COUNT(*) AS DECIMAL(12, 2))       AS avg_ticket
FROM ${medallion_catalog}.${silver_schema}.transactions
GROUP BY ALL;
