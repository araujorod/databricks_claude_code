-- Bronze: raw ingestion of samples.bakehouse.media_customer_reviews.
-- The destination catalog and schema come from the pipeline 'configuration'
-- block, which the bundle wires to ${var.catalog} and the schema resources.
CREATE OR REFRESH STREAMING TABLE ${medallion_catalog}.${bronze_schema}.reviews
COMMENT "Raw free-text customer reviews per franchise."
TBLPROPERTIES ('quality' = 'bronze', 'medallion.layer' = 'bronze')
AS SELECT
  *,
  current_timestamp()                     AS _ingested_at,
  'samples.bakehouse.media_customer_reviews'           AS _source_table,
  _metadata.file_path                     AS _source_file
FROM STREAM(samples.bakehouse.media_customer_reviews);
