-- Gold: review sentiment per franchise, joined to the franchise dimension so
-- the dashboard can slice sentiment by city and country like every other mart.
-- net_sentiment_score is (positive - negative) / reviews, in [-1, 1].
CREATE OR REFRESH MATERIALIZED VIEW ${medallion_catalog}.${gold_schema}.sentiment_by_franchise
COMMENT "Review counts and sentiment breakdown per franchise."
TBLPROPERTIES ('quality' = 'gold', 'medallion.layer' = 'gold')
AS
WITH scored AS (
  SELECT
    franchise_id,
    COUNT(*)                                                    AS reviews,
    SUM(CASE WHEN sentiment = 'positive' THEN 1 ELSE 0 END)     AS positive_reviews,
    SUM(CASE WHEN sentiment = 'negative' THEN 1 ELSE 0 END)     AS negative_reviews,
    SUM(CASE WHEN sentiment = 'neutral'  THEN 1 ELSE 0 END)     AS neutral_reviews,
    SUM(CASE WHEN sentiment = 'mixed'    THEN 1 ELSE 0 END)     AS mixed_reviews,
    CAST(AVG(review_length) AS DECIMAL(10, 1))                  AS avg_review_length,
    MIN(review_date)                                            AS first_review_date,
    MAX(review_date)                                            AS last_review_date
  FROM ${medallion_catalog}.${silver_schema}.reviews_sentiment
  GROUP BY franchise_id
)
SELECT
  f.franchise_id,
  f.franchise_name,
  f.city,
  f.country,
  f.latitude,
  f.longitude,
  s.reviews,
  s.positive_reviews,
  s.negative_reviews,
  s.neutral_reviews,
  s.mixed_reviews,
  CAST(100.0 * s.positive_reviews / s.reviews AS DECIMAL(5, 1))  AS positive_pct,
  CAST(100.0 * s.negative_reviews / s.reviews AS DECIMAL(5, 1))  AS negative_pct,
  CAST((s.positive_reviews - s.negative_reviews) / CAST(s.reviews AS DOUBLE) AS DECIMAL(5, 3)) AS net_sentiment_score,
  s.avg_review_length,
  s.first_review_date,
  s.last_review_date
FROM scored s
JOIN ${medallion_catalog}.${silver_schema}.franchises f
  ON s.franchise_id = f.franchise_id;
