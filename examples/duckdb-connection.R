library(rb3)
library(duckdb)

# con <- create duckdb_connection()
con <- duckdb::duckdb(
  dbdir = "rb3.db",
  read_only = FALSE,
  auto_commit = TRUE
)

duckdb::duckdb_register_arrow(con, "b3_cotahist_yearly", cotahist_get("yearly"))
duckdb::duckdb_register_arrow(con, "b3_yc_brl", yc_brl_get())
duckdb::duckdb_register_arrow(con, "b3_futures", futures_get())
duckdb::duckdb_register_arrow(con, "b3_indexes", indexes_historical_data_get())
duckdb::duckdb_register_arrow(con, "b3_indexes_composition", indexes_composition_get())
duckdb::duckdb_register_arrow(con, "b3_indexes_current_portfolio", indexes_current_portfolio_get())
duckdb::duckdb_register_arrow(con, "b3_indexes_theoretical_portfolio", indexes_theoretical_portfolio_get())

duckdb::dbSendQuery(con, "select refdate, symbol, close from 'b3_cotahist_yearly' where symbol = 'PETR4' and refdate = '2025-04-14' order by refdate") |>
  duckdb::dbFetch()

DBI::dbGetQuery(con, "SELECT * FROM b3_yc_brl where refdate = '2025-03-10' and curve_name = 'PRE'")

DBI::dbGetQuery(con, "SELECT * FROM b3_indexes where symbol = 'IBOV'")

DBI::dbGetQuery(con, "SELECT * FROM b3_indexes_current_portfolio where index = 'IBOV' limit 10") |> dplyr::as_tibble()

DBI::dbGetQuery(con, "SELECT * FROM b3_indexes_theoretical_portfolio limit 10")
DBI::dbGetQuery(con, "SELECT symbol FROM b3_indexes_current_portfolio where index = 'IBOV' and refdate = '2025-04-14'")

df <- DBI::dbGetQuery(con, "
SELECT
  c.symbol,
  c.close,
FROM b3_cotahist_yearly c
WHERE c.refdate = '2025-04-14'
  and c.symbol in (SELECT symbol FROM b3_indexes_current_portfolio where index = 'IBOV' and refdate = '2025-04-14')
")

write.table(df, file = "/mnt/c/Users/wilso/Downloads/stocks.csv", sep = ";", dec = ",", row.names = FALSE, col.names = TRUE)

df <- DBI::dbGetQuery(con, "
SELECT
  c.refdate,
  c.symbol,
  c.close,
  p.theoretical_quantity,
  c.close * p.theoretical_quantity / p.reductor as theoretical_value
FROM b3_cotahist_yearly c
inner join b3_indexes_current_portfolio p
  on c.symbol = p.symbol and c.refdate = p.refdate and p.index = 'IBOV'
WHERE c.refdate = '2025-04-14'
") |> dplyr::as_tibble()

df$theoretical_value |> sum()

DBI::dbGetQuery(con, "SELECT * FROM b3_indexes where symbol = 'IBOV' and refdate = '2025-04-14'") |>
  dplyr::as_tibble()

t <- template_retrieve("b3-indexes-current-portfolio")
rb3:::meta_load(t$id, index = "IBOV", extra_arg = "2025-04-14")

duckdb::dbDisconnect(con)
