## ----eval=TRUE-----------------------------------------------------------------------------------------------------------------------------
options(rb3.cachedir = tempdir())
devtools::load_all(".")
library(tidyverse)
library(bizdays)

# Download yield curve data for specific dates
fetch_marketdata("b3-reference-rates",
  refdate = preceding("2024-01-31", "Brazil/B3"),
  curve_name = "PRE"
)
# Download yearly COTAHIST files
fetch_marketdata("b3-cotahist-yearly", year = 2023)

# Download futures data
fetch_marketdata("b3-futures-settlement-prices", refdate = preceding("2024-01-31", "Brazil/B3"))

ch <- cotahist_get("yearly")
# Filter for stocks
eq <- ch |>
  filter(year(refdate) == 2023) |>
  cotahist_filter_equity() |>
  collect()

# Get top 10 most traded stocks
symbols <- eq |>
  group_by(symbol) |>
  summarise(volume = sum(volume)) |>
  arrange(desc(volume)) |>
  head(10) |>
  collect() |>
  pull(symbol)

# Get Brazilian nominal yield curve (PRE)
yc_data <- yc_brl_get() |>
  filter(refdate == "2024-01-31") |>
  collect()

# Get futures settlement prices
futures_data <- futures_get() |>
  filter(commodity == "DI1") |>
  collect()

# save datasets: ch, eq, symbols, yc_data, futures_data to file README.RData
save(
  eq,
  yc_data,
  futures_data,
  file = "README.RData"
)