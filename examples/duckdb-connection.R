library(duckdb)

reg <- rb3_registry$get_instance()
con <- dbConnect(duckdb::duckdb(), file.path(reg[["db_folder"]], "duckdb.db"))

con <- rb3_db_connection()

t <- template_retrieve("b3-reference-rates")
t <- template_retrieve("b3-cotahist-yearly")
ds <- template_dataset(t)
q <- yc_brl_get()

duckdb::duckdb_register_arrow(con, "b3-reference-rates", ds)
duckdb::duckdb_register_arrow(con, "b3-cotahist-yearly", ds)
duckdb::duckdb_register_arrow(con, "b3-yc-brl", q)
duckdb::dbExistsTable(con, "b3-reference-rates")
duckdb::dbExistsTable(con, "b3-yc-brl")

duckdb::dbSendQuery(con, "select * from 'b3-cotahist-yearly' where regtype = 1 and instrument_market = 10 and symbol = 'PETR4' order by refdate") |> duckdb::dbFetch()

DBI::dbGetQuery(con, "SELECT * FROM 'b3-reference-rates' where refdate = '2025-03-10' and curve_name = 'PRE'")
DBI::dbGetQuery(con, "SELECT * FROM 'b3-yc-brl' where refdate = '2025-03-10'")
DBI::dbGetQuery(con, "SELECT * FROM 'b3-reference-rates' where refdate = '2025-03-10'")

duckdb::dbDisconnect(con)

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

