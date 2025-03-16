library(duckdb)

reg <- rb3_registry$get_instance()
con <- dbConnect(duckdb::duckdb(), file.path(reg[["db_folder"]], "duckdb.db"))

con <- rb3_db_connection()

t <- template_retrieve("b3-cotahist-daily")

library(duckplyr)

template_db_folder(t)

duckplyr::read_parquet_duckdb(list.files(template_db_folder(t), full.names = TRUE), prudence = "stingy") |> nrow()

DBI::dbGetQuery(
  con,
  "select * from 'b3-cotahist-daily' limit 10"
)

q <- sprintf("create or replace view 'b3-cotahist-daily' as SELECT * FROM read_parquet('%s/*.parquet') where regtype = 1", template_db_folder(t))

dbExecute(con, q)

duckplyr::db_exec("INSTALL json")
duckplyr::db_exec("LOAD json")
duckplyr::read_json_duckdb(sprintf("%s/*.json", reg$meta_folder)) |> filter(template == "b3-reference-rates")

dbGetQuery(
  con,
  sprintf("select * from read_json('%s/*.json') limit 10", reg[["meta_folder"]])
)

dbGetQuery(
  con,
  sprintf("select * from read_json('%s/*.json') where template = 'b3-cotahist-daily'", reg[["meta_folder"]])
)

