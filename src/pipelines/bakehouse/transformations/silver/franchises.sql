-- Silver: conformed franchise dimension.
-- Country is standardised here: the franchise source spells the United States
-- as 'US' while the customer source spells it 'USA'. Both land as 'USA' so the
-- two dimensions join and aggregate consistently downstream.
CREATE OR REFRESH STREAMING TABLE ${medallion_catalog}.${silver_schema}.franchises (
  CONSTRAINT valid_franchise_id  EXPECT (franchise_id IS NOT NULL)        ON VIOLATION DROP ROW,
  CONSTRAINT valid_country       EXPECT (country IS NOT NULL)             ON VIOLATION DROP ROW,
  CONSTRAINT valid_latitude      EXPECT (latitude  BETWEEN -90  AND 90),
  CONSTRAINT valid_longitude     EXPECT (longitude BETWEEN -180 AND 180),
  CONSTRAINT known_size          EXPECT (franchise_size IN ('S', 'M', 'L', 'XL', 'XXL'))
)
COMMENT "Cleaned franchise master data with standardised country names."
TBLPROPERTIES ('quality' = 'silver', 'medallion.layer' = 'silver')
AS SELECT
  CAST(franchiseID AS BIGINT)                        AS franchise_id,
  trim(name)                                         AS franchise_name,
  trim(city)                                         AS city,
  trim(district)                                     AS district,
  trim(zipcode)                                      AS zipcode,
  CASE
    WHEN upper(trim(country)) IN ('US', 'USA', 'UNITED STATES') THEN 'USA'
    ELSE initcap(trim(country))
  END                                                AS country,
  upper(trim(size))                                  AS franchise_size,
  CAST(latitude  AS DOUBLE)                          AS latitude,
  CAST(longitude AS DOUBLE)                          AS longitude,
  CAST(supplierID AS BIGINT)                         AS supplier_id,
  _ingested_at                                       AS _ingested_at
FROM STREAM(${medallion_catalog}.${bronze_schema}.franchises);
