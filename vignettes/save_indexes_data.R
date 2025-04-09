# Script to save data for the "Analyzing B3 Index Data with rb3" vignette
library(rb3)
library(dplyr)
library(ggplot2)
library(tidyr)
library(lubridate)
library(stringr)

# fetch_marketdata("b3-indexes-historical-data",
#   throttle = TRUE,
#   index = c("IBOV", "SMLL", "IDIV"),
#   year = 2018:2023
# )

# fetch_marketdata("b3-indexes-composition")

index_history <- indexes_historical_data_get() |>
  filter(
    symbol %in% c("IBOV", "SMLL", "IDIV"),
    refdate >= "2018-01-01"
  ) |>
  collect()

latest_date <- indexes_composition_get() |>
  summarise(update_date = max(update_date)) |>
  collect() |>
  dplyr::pull(update_date)

composition <- indexes_composition_get() |>
  filter(update_date == latest_date) |>
  collect()

selected_indices <- c("IBOV", "SMLL", "IDIV")

# Find stocks in each index
stocks_by_index <- lapply(selected_indices, function(idx) {
  composition |>
    filter(update_date == latest_date, str_detect(indexes, idx)) |>
    dplyr::pull(symbol)
})
names(stocks_by_index) <- selected_indices

# Get the theoretical portfolio data
theoretical <- indexes_theoretical_portfolio_get() |>
  collect()

# Get the latest date for each index
latest_dates <- theoretical |>
  group_by(index) |>
  summarise(latest = max(refdate))

current <- indexes_current_portfolio_get() |>
  collect()

# Get the latest date for each index
current_latest <- current |>
  group_by(index) |>
  summarise(latest = max(refdate))

indexes <- indexes_get()

# Save all data
save(
  index_history,
  composition,
  theoretical,
  current,
  indexes,
  stocks_by_index,
  latest_date,
  latest_dates,
  current_latest,
  file = "vignettes/indexes_data.rda"
)
