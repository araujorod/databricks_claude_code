-- Bronze: raw ingestion of samples.bakehouse.sales_franchises.
-- The destination catalog and schema come from the pipeline 'configuration'
-- block, which the bundle wires to ${var.catalog} and the schema resources.
CREATE OR REFRESH STREAMING TABLE ${medallion_catalog}.${bronze_schema}.franchises
COMMENT "Raw franchise master data, one row per franchise location."
TBLPROPERTIES ('quality' = 'bronze', 'medallion.layer' = 'bronze')
AS SELECT
  *,
  current_timestamp()                     AS _ingested_at,
  'samples.bakehouse.sales_franchises'           AS _source_table,
  _metadata.file_path                     AS _source_file
FROM STREAM(samples.bakehouse.sales_franchises);
