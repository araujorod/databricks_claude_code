-- Bronze: raw ingestion of samples.bakehouse.sales_customers.
-- The destination catalog and schema come from the pipeline 'configuration'
-- block, which the bundle wires to ${var.catalog} and the schema resources.
CREATE OR REFRESH STREAMING TABLE ${medallion_catalog}.${bronze_schema}.customers
COMMENT "Raw customer master data."
TBLPROPERTIES ('quality' = 'bronze', 'medallion.layer' = 'bronze')
AS SELECT
  *,
  current_timestamp()                     AS _ingested_at,
  'samples.bakehouse.sales_customers'           AS _source_table,
  _metadata.file_path                     AS _source_file
FROM STREAM(samples.bakehouse.sales_customers);
