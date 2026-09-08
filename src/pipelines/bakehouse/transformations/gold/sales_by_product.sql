-- Gold: product mix, broken down by payment method.
-- Keeping payment_method in the grain lets the dashboard serve both
-- "revenue by product" and the payment-method mix from one table without
-- distorting either total (both are simple SUMs over this grain).
CREATE OR REFRESH MATERIALIZED VIEW ${medallion_catalog}.${gold_schema}.sales_by_product
CLUSTER BY (product, payment_method)
COMMENT "Revenue, orders and units per product and payment method."
TBLPROPERTIES ('quality' = 'gold', 'medallion.layer' = 'gold')
AS SELECT
  product,
  payment_method,
  COUNT(*)                                                  AS orders,
  COUNT(DISTINCT customer_id)                               AS unique_customers,
  COUNT(DISTINCT franchise_id)                              AS franchises_selling,
  SUM(quantity)                                             AS units_sold,
  CAST(SUM(total_price) AS DECIMAL(18, 2))                  AS revenue,
  CAST(AVG(unit_price)  AS DECIMAL(12, 2))                  AS avg_unit_price,
  CAST(SUM(total_price) / COUNT(*) AS DECIMAL(12, 2))       AS avg_ticket
FROM ${medallion_catalog}.${silver_schema}.transactions
GROUP BY ALL;
