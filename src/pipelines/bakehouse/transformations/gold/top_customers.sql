-- Gold: customer value ranking. Kept at full customer grain (not pre-limited)
-- so the dashboard can pick its own Top N without a pipeline change.
CREATE OR REFRESH MATERIALIZED VIEW ${medallion_catalog}.${gold_schema}.top_customers
COMMENT "Per-customer revenue, orders, average ticket and favourite product."
TBLPROPERTIES ('quality' = 'gold', 'medallion.layer' = 'gold')
AS
WITH per_customer AS (
  SELECT
    customer_id,
    customer_name,
    customer_country,
    customer_continent,
    COUNT(*)                     AS orders,
    SUM(quantity)                AS units_bought,
    SUM(total_price)             AS revenue,
    COUNT(DISTINCT franchise_id) AS franchises_visited,
    MIN(transaction_date)        AS first_purchase_date,
    MAX(transaction_date)        AS last_purchase_date
  FROM ${medallion_catalog}.${silver_schema}.transactions
  GROUP BY ALL
),
favourite_product AS (
  SELECT customer_id, product AS favourite_product
  FROM (
    SELECT
      customer_id,
      product,
      ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY SUM(total_price) DESC, product) AS rn
    FROM ${medallion_catalog}.${silver_schema}.transactions
    GROUP BY customer_id, product
  )
  WHERE rn = 1
)
SELECT
  p.customer_id,
  p.customer_name,
  p.customer_country                                        AS country,
  p.customer_continent                                      AS continent,
  p.orders,
  p.units_bought,
  CAST(p.revenue AS DECIMAL(18, 2))                         AS revenue,
  CAST(p.revenue / p.orders AS DECIMAL(12, 2))              AS avg_ticket,
  p.franchises_visited,
  p.first_purchase_date,
  p.last_purchase_date,
  fp.favourite_product,
  RANK() OVER (ORDER BY p.revenue DESC)                     AS revenue_rank
FROM per_customer p
LEFT JOIN favourite_product fp ON p.customer_id = fp.customer_id;
