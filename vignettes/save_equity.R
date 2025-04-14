# Script to generate sample equity data for the vignette using actual data
# Run this script to create the data needed for vignettes/Fetching-historical-equity-data.Rmd

options(rb3.cachedir = tempdir())
devtools::load_all()
library(dplyr)
library(lubridate)
library(ggplot2)

# Download a sample of COTAHIST data if needed
fetch_marketdata("b3-cotahist-yearly", year = 2023)

# Access the dataset
ch <- cotahist_get("yearly")

# Extract equity data
eq <- ch |>
  filter(year(refdate) == 2023) |>
  cotahist_filter_equity()

# Get top 10 stocks by volume
symbols_eq <- eq |>
  group_by(symbol) |>
  summarise(volume = sum(volume)) |>
  arrange(desc(volume)) |>
  head(10) |>
  pull(symbol, as_vector = TRUE)

# Calculate monthly volumes for top stocks
eq_monthly <- eq |>
  filter(symbol %in% symbols_eq) |>
  mutate(month = floor_date(refdate, "month")) |>
  group_by(month, symbol) |>
  summarise(volume = sum(volume)) |>
  collect()

# Extract ETF data
etfs <- ch |> 
  filter(year(refdate) == 2023) |> 
  cotahist_filter_etf()

# Calculate total ETF volume
total_volume <- etfs |>
  summarise(volume = sum(volume)) |>
  pull(volume, as_vector = TRUE)

# Calculate volume share for top ETFs
etf_shares <- etfs |>
  group_by(symbol) |>
  summarise(volume = sum(volume)) |>
  collect() |>
  mutate(volume_ratio = volume / total_volume) |>
  slice_max(volume_ratio, n = 10) |>
  mutate(volume_ratio_acc = cumsum(volume_ratio))

# Extract data for a specific stock (ITUB)
stock_data <- eq |>
  filter(symbol == "ITUB4") |>
  arrange(refdate) |>
  select(refdate, symbol, close, distribution_id) |>
  collect()

# Extract BDR data
bdrs <- ch |> cotahist_filter_bdr()

# Extract data for a specific BDR (AAPL34 or another available BDR)
# Get the first BDR with sufficient data
bdr_symbol <- bdrs |>
  group_by(symbol) |>
  summarise(count = n()) |>
  # get the most traded BDR
  arrange(desc(count)) |>
  # filter to get BDRs with more than 100 trades
  # and take the first one
  filter(count > 100) |>
  head(1) |>
  pull(symbol, as_vector = TRUE)

# Extract BDR data for the selected symbol
bdr_data <- bdrs |>
  filter(symbol == bdr_symbol) |>
  arrange(refdate) |>
  select(refdate, symbol, trade_quantity, distribution_id) |>
  collect()

# Save all sample data to an RData file for use in the vignette
save(
  eq_monthly,
  etf_shares,
  stock_data,
  bdr_data,
  file = "vignettes/data_equity.RData"
)

cat("Sample data saved to vignettes/equity_data.RData\n")