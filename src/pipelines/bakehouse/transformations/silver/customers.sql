-- Silver: conformed customer dimension.
-- Same country standardisation as the franchise dimension, so 'US' and 'USA'
-- never split a country total in the gold layer.
CREATE OR REFRESH STREAMING TABLE ${medallion_catalog}.${silver_schema}.customers (
  CONSTRAINT valid_customer_id EXPECT (customer_id IS NOT NULL)  ON VIOLATION DROP ROW,
  CONSTRAINT valid_country     EXPECT (country IS NOT NULL)      ON VIOLATION DROP ROW,
  CONSTRAINT valid_email       EXPECT (email_address LIKE '%@%'),
  CONSTRAINT has_name          EXPECT (customer_name IS NOT NULL AND length(customer_name) > 1)
)
COMMENT "Cleaned customer master data with standardised country names."
TBLPROPERTIES ('quality' = 'silver', 'medallion.layer' = 'silver')
AS SELECT
  CAST(customerID AS BIGINT)                              AS customer_id,
  initcap(trim(first_name))                               AS first_name,
  initcap(trim(last_name))                                AS last_name,
  concat_ws(' ', initcap(trim(first_name)), initcap(trim(last_name))) AS customer_name,
  lower(trim(email_address))                              AS email_address,
  trim(phone_number)                                      AS phone_number,
  trim(city)                                              AS city,
  trim(state)                                             AS state,
  CASE
    WHEN upper(trim(country)) IN ('US', 'USA', 'UNITED STATES') THEN 'USA'
    ELSE initcap(trim(country))
  END                                                     AS country,
  initcap(trim(continent))                                AS continent,
  CAST(postal_zip_code AS STRING)                         AS postal_zip_code,
  lower(trim(gender))                                     AS gender,
  _ingested_at                                            AS _ingested_at
FROM STREAM(${medallion_catalog}.${bronze_schema}.customers);
