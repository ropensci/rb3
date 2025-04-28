library(rb3)
library(duckplyr)

template_db_folder(t)

duckplyr::read_parquet_duckdb(list.files(template_db_folder(t), full.names = TRUE), prudence = "stingy") |> nrow()

DBI::dbGetQuery(
  con,
  "select * from 'b3-cotahist-daily' limit 10"
)

q <- sprintf("create or replace view 'b3-cotahist-daily' as SELECT * FROM read_parquet('%s/*.parquet') where regtype = 1", template_db_folder(t))

dbExecute(con, q)

dbGetQuery(
  con,
  "select * from meta limit 10"
)

dbGetQuery(
  con,
  "select * from meta where template = 'b3-cotahist-daily'"
)

