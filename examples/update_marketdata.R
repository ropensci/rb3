
library(rb3)
library(bizdays)

fetch_marketdata("b3-indexes-composition")
fetch_marketdata("b3-indexes-current-portfolio", index = indexes_get(), throttle = TRUE)
fetch_marketdata("b3-indexes-theoretical-portfolio", index = indexes_get(), throttle = TRUE)
fetch_marketdata("b3-indexes-historical-data", index = indexes_get(), year = 2000:2025, throttle = TRUE)
fetch_marketdata("b3-cotahist-yearly", year = 2000:2025)
fetch_marketdata("b3-futures-settlement-prices", refdate = bizseq("2000-01-01", Sys.Date(), "Brazil/B3"))
fetch_marketdata("b3-reference-rates",
  refdate = bizseq("2018-01-01", Sys.Date(), "Brazil/B3"),
  curve_name = c("DIC", "DOC", "PRE")
)
