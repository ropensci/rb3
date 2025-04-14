
options(rb3.cachedir = tempdir())
library(bizdays)
devtools::load_all()

dates <- getdate("first bizday", 2021:2025, "Brazil/B3")
fetch_marketdata("b3-reference-rates", refdate = dates, curve_name = c("DIC", "DOC", "PRE"))

df_yc_brl <- yc_brl_get() |>
  filter(forward_date < "2035-01-01") |>
  collect()

df_yc_ipca <- yc_ipca_get() |>
  collect()

df_yc_usd <- yc_usd_get() |>
  filter(forward_date < "2035-01-01") |>
  collect()

# Save all data
save(
  df_yc_brl,
  df_yc_ipca,
  df_yc_usd,
  file = "vignettes/data_yc.RData"
)
