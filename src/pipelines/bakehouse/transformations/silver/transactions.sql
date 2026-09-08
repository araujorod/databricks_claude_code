-- Silver: the conformed sales fact, enriched with franchise and customer.
-- Stream-static join: the transaction stream drives the table, the two
-- dimensions are read as static snapshots.
-- cardNumber is deliberately NOT carried past bronze.
CREATE OR REFRESH STREAMING TABLE ${medallion_catalog}.${silver_schema}.transactions (
  CONSTRAINT valid_transaction_id EXPECT (transaction_id IS NOT NULL)   ON VIOLATION DROP ROW,
  CONSTRAINT positive_quantity    EXPECT (quantity > 0)                 ON VIOLATION DROP ROW,
  CONSTRAINT non_negative_revenue EXPECT (total_price >= 0)             ON VIOLATION DROP ROW,
  CONSTRAINT valid_timestamp      EXPECT (transaction_ts IS NOT NULL)   ON VIOLATION DROP ROW,
  CONSTRAINT resolved_franchise   EXPECT (franchise_name IS NOT NULL),
  CONSTRAINT resolved_customer    EXPECT (customer_name IS NOT NULL),
  CONSTRAINT known_payment_method EXPECT (payment_method IN ('visa', 'mastercard', 'amex')),
  CONSTRAINT price_reconciles     EXPECT (total_price = unit_price * quantity)
)
COMMENT "Cleaned sales transactions enriched with franchise and customer attributes."
TBLPROPERTIES ('quality' = 'silver', 'medallion.layer' = 'silver')
AS SELECT
  CAST(t.transactionID AS BIGINT)          AS transaction_id,
  CAST(t.customerID    AS BIGINT)          AS customer_id,
  CAST(t.franchiseID   AS BIGINT)          AS franchise_id,

  -- Derived date columns
  CAST(t.dateTime AS TIMESTAMP)            AS transaction_ts,
  CAST(t.dateTime AS DATE)                 AS transaction_date,
  year(t.dateTime)                         AS transaction_year,
  month(t.dateTime)                        AS transaction_month,
  day(t.dateTime)                          AS transaction_day,
  date_format(t.dateTime, 'yyyy-MM')       AS transaction_year_month,
  date_format(t.dateTime, 'EEEE')          AS transaction_day_of_week,

  trim(t.product)                          AS product,
  CAST(t.quantity   AS BIGINT)             AS quantity,
  CAST(t.unitPrice  AS DECIMAL(10, 2))     AS unit_price,
  CAST(t.totalPrice AS DECIMAL(12, 2))     AS total_price,
  lower(trim(t.paymentMethod))             AS payment_method,

  -- Franchise attributes
  f.franchise_name                         AS franchise_name,
  f.city                                   AS franchise_city,
  f.country                                AS franchise_country,
  f.franchise_size                         AS franchise_size,
  f.latitude                               AS franchise_latitude,
  f.longitude                              AS franchise_longitude,

  -- Customer attributes
  c.customer_name                          AS customer_name,
  c.country                                AS customer_country,
  c.continent                              AS customer_continent,

  t._ingested_at                           AS _ingested_at
FROM STREAM(${medallion_catalog}.${bronze_schema}.transactions) t
LEFT JOIN ${medallion_catalog}.${silver_schema}.franchises f
  ON CAST(t.franchiseID AS BIGINT) = f.franchise_id
LEFT JOIN ${medallion_catalog}.${silver_schema}.customers c
  ON CAST(t.customerID AS BIGINT) = c.customer_id;
