-- Silver: customer reviews scored with the built-in ai_analyze_sentiment
-- AI function, which returns 'positive', 'negative', 'mixed' or 'neutral'.
CREATE OR REFRESH STREAMING TABLE ${medallion_catalog}.${silver_schema}.reviews_sentiment (
  CONSTRAINT valid_review_id  EXPECT (review_id IS NOT NULL)                            ON VIOLATION DROP ROW,
  CONSTRAINT has_review_text  EXPECT (review_text IS NOT NULL AND length(review_text) > 0) ON VIOLATION DROP ROW,
  CONSTRAINT valid_franchise  EXPECT (franchise_id IS NOT NULL)                         ON VIOLATION DROP ROW,
  CONSTRAINT known_sentiment  EXPECT (sentiment IN ('positive', 'negative', 'neutral', 'mixed'))
)
COMMENT "Customer reviews with a sentiment label produced by ai_analyze_sentiment."
TBLPROPERTIES ('quality' = 'silver', 'medallion.layer' = 'silver')
AS SELECT
  CAST(r.new_id      AS BIGINT)        AS review_id,
  CAST(r.franchiseID AS BIGINT)        AS franchise_id,
  CAST(r.review_date AS TIMESTAMP)     AS review_ts,
  CAST(r.review_date AS DATE)          AS review_date,
  year(r.review_date)                  AS review_year,
  month(r.review_date)                 AS review_month,
  day(r.review_date)                   AS review_day,
  r.review                             AS review_text,
  length(r.review)                     AS review_length,
  ai_analyze_sentiment(r.review)       AS sentiment,
  r._ingested_at                       AS _ingested_at
FROM STREAM(${medallion_catalog}.${bronze_schema}.reviews) r;
