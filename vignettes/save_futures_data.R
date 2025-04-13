
library(bizdays)
library(rb3)

dates <- getdate("first mon", seq(as.Date("2021-01-01"), as.Date("2022-12-24"), by = 7), "actual") |>
  following("Brazil/B3")
fetch_marketdata("b3-futures-settlement-prices", refdate = dates)

df <- futures_get() |>
  collect()

# Save all data
save(
  df,
  file = "vignettes/futures.RData"
)
