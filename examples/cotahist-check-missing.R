library(rb3)
library(tidyverse)
library(bizdays)

# function to check for missing points ----

get_missing_points <- function(df) {
  date_range <- df |>
    summarise(min = min(refdate), max = max(refdate))
  chck_dts <- tibble(refdate = bizseq(date_range$min, date_range$max, "Brazil/B3"))

  na_ <- df |>
    full_join(chck_dts, by = "refdate") |>
    arrange(refdate) |>
    pull(close) |>
    is.na() |>
    which()

  df$refdate[na_]
}

# check for missing points ----
## etfs ----
etfs <- cotahist_get("yearly") |>
  cotahist_filter_etf() |>
  select(symbol, refdate, close) |>
  arrange(symbol, refdate) |>
  collect()

missing_points <- split(etfs, etfs$symbol) |> lapply(get_missing_points)

## create a dataframe with the count of missing points
tibble(
  symbol = names(missing_points),
  missing_points = map_int(missing_points, length)
) |>
  arrange(desc(missing_points)) |>
  View()

## equities ----

equities <- cotahist_get("yearly") |>
  cotahist_filter_equity() |>
  select(symbol, refdate, close) |>
  arrange(symbol, refdate) |>
  collect()

missing_points <- split(equities, equities$symbol) |> lapply(get_missing_points)

## create a dataframe with the count of missing points
tibble(
  symbol = names(missing_points),
  missing_points = map_int(missing_points, length)
) |>
  arrange(desc(missing_points)) |>
  View()

## bdrs ----

bdrs <- cotahist_get("yearly") |>
  cotahist_filter_bdr() |>
  select(symbol, refdate, close) |>
  arrange(symbol, refdate) |>
  collect()
missing_points <- split(bdrs, bdrs$symbol) |> lapply(get_missing_points)

## create a dataframe with the count of missing points
tibble(
  symbol = names(missing_points),
  missing_points = map_int(missing_points, length)
) |>
  arrange(desc(missing_points)) |>
  View()
