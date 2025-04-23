
library(rb3)
library(bizdays)

# This is an initial example of how to get the data from B3 using the
# `fetch_marketdata` function. The function will download the data from B3
# and store it in the rb3 data structure.

fetch_marketdata("b3-cotahist-yearly", year = 2000:2025)
fetch_marketdata("b3-futures-settlement-prices", refdate = bizseq("2000-01-01", Sys.Date(), "Brazil/B3"))
fetch_marketdata("b3-reference-rates",
  refdate = bizseq("2018-01-01", Sys.Date(), "Brazil/B3"),
  curve_name = c("DIC", "DOC", "PRE")
)
fetch_marketdata("b3-indexes-composition")
fetch_marketdata("b3-indexes-current-portfolio", index = indexes_get(), throttle = TRUE)
fetch_marketdata("b3-indexes-theoretical-portfolio", index = indexes_get(), throttle = TRUE)
fetch_marketdata("b3-indexes-historical-data", index = indexes_get(), year = 2000:2025, throttle = TRUE)

# Once you need to update the data, you can set the `do_cache` argument to TRUE
# to force the update of the data. This will download the data again and
# overwrite the existing data in the cache.

fetch_marketdata('b3-cotahist-yearly', year = 2025, do_cache = TRUE)
fetch_marketdata("b3-indexes-historical-data", index = indexes_get(), year = 2025, throttle = TRUE, do_cache = TRUE)
