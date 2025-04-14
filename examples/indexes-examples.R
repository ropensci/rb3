library(rb3)
library(tidyverse)
library(bizdays)

# loading the current portfolio data for all indexes
fetch_marketdata("b3-indexes-current-portfolio", index = indexes_get())

index_name <- "IBOV"

# find out available dates
indexes_current_portfolio_get() |>
  filter(index == index_name) |>
  distinct(refdate) |>
  collect()

# get last date
last_date <- indexes_current_portfolio_get() |>
  filter(index == index_name) |>
  summarise(last_date = max(refdate)) |>
  collect() |>
  pull(last_date)

# top 10 weights
indexes_current_portfolio_get() |>
  filter(index == index_name, refdate == last_date) |>
  select(symbol, sector, weight, theoretical_quantity) |>
  collect() |>
  slice_max(order_by = weight, n = 10)

# create current portfolio sector weights
current_portfolio <- indexes_current_portfolio_get() |>
  filter(index == index_name, refdate == last_date) |>
  collect() |>
  group_by(sector) |>
  summarise(weight = sum(weight, na.rm = TRUE)) |>
  arrange(sector)

current_portfolio |>
  ggplot(aes(x = reorder(sector, weight), y = weight)) +
  geom_bar(stat = "identity") +
  coord_flip() +
  labs(x = NULL, y = "%") +
  scale_y_continuous(labels = scales::percent)

# fetch theoretical portfolio data
fetch_marketdata("b3-indexes-theoretical-portfolio", index = indexes_get())

## b3-indexes-theoretical-portfolio does not have a sector column

# get last date
last_date <- indexes_theoretical_portfolio_get() |>
  filter(index == index_name) |>
  summarise(last_date = max(refdate)) |>
  collect() |>
  pull(last_date)

# top 10 weights
indexes_theoretical_portfolio_get() |>
  filter(index == index_name, refdate == last_date) |>
  select(symbol, weight, theoretical_quantity) |>
  collect() |>
  slice_max(order_by = weight, n = 10)

# index composition

# fetch_marketdata("b3-indexes-composition") does not work!
# usar download_marketdata() e read_marketdata()
meta <- download_marketdata("b3-indexes-composition")
read_marketdata(meta)

# get last date
last_date <- indexes_composition_get() |>
  summarise(update_date = max(update_date)) |>
  collect() |>
  pull(update_date)

# the composition of the indexes
index <- c("IBOV", "SMLL", "IDIV")
x <- lapply(index, function(index) {
  indexes_composition_get() |>
    filter(update_date == last_date, str_detect(indexes, index)) |>
    select(symbol) |>
    collect() |>
    pull(symbol)
})
stats::setNames(x, index)

# find out the indexes that contain a given symbol
# e.g. ABEV3
symbols <- "ABEV3"
indexes_composition_get() |>
  filter(update_date == last_date, symbol %in% symbols) |>
  select(indexes) |>
  collect() |>
  pull(indexes) |> str_split(",") |> unlist()

# find out all indexes
indexes_composition_get() |>
  filter(update_date == last_date) |>
  select(indexes) |>
  collect() |>
  pull(indexes) |>
  str_split(",") |>
  unlist() |>
  unique() |>
  sort()

indexes_assets_by_indexes <- function(indexes) {
  last_date <- template_dataset("b3-indexes-composition") |>
    summarise(update_date = max(update_date)) |>
    collect() |>
    pull(update_date)

  x <- lapply(indexes, function(index) {
    template_dataset("b3-indexes-composition") |>
      filter(update_date == last_date, str_detect(indexes, index)) |>
      select(symbol) |>
      collect() |>
      pull(symbol)
  })
  stats::setNames(x, index)
}

indexes_indexes_by_assets <- function(symbols) {
  last_date <- template_dataset("b3-indexes-composition") |>
    summarise(update_date = max(update_date)) |>
    collect() |>
    pull(update_date)

  template_dataset("b3-indexes-composition") |>
    filter(update_date == last_date, symbol %in% symbols) |>
    select(indexes) |>
    collect() |>
    pull(indexes) |>
    str_split(",") |>
    unlist()
}

# indexes historical data

fetch_marketdata("b3-indexes-historical-data", throttle = TRUE, index = indexes_get(), year = 2000:2025)

indexes_data <- indexes_historical_data_get() |>
  filter(symbol %in% c("IBOV", "IDIV", "IBXL", "IBXX", "IBRA"), refdate >= "2010-01-01") |>
  collect()

indexes_data |>
  ggplot(aes(x = refdate, y = value, color = symbol)) +
  geom_line() +
  scale_y_continuous(labels = scales::number_format()) +
  theme(axis.text.x = element_text(angle = 90))
