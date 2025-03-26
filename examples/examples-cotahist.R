
library(rb3)
library(tidyverse)

fetch_marketdata("b3-cotahist-yearly", year = 2018:2024)

# BDRs ----

bdrs <- cotahist_get() |>
  cotahist_filter_bdr()

bdrs |>
  group_by(symbol) |>
  count(sort = TRUE) |>
  head(15) |>
  collect()

bdrs |>
  filter(symbol == "AAPL34") |>
  arrange(refdate) |>
  collect() |> 
  ggplot(aes(x = refdate, y = trade_quantity, colour = factor(distribution_id))) +
  geom_line()

bdrs |>
  filter(symbol == "DISB34") |>
  arrange(refdate) |>
  collect() |>
  ggplot(aes(x = refdate, y = distribution_id)) +
  geom_line()

## check for missing points ----

date_range <- bdrs |>
  summarise(min = min(refdate), max = max(refdate)) |>
  collect()

chck_dts <- bizseq(date_range$min, date_range$max, "Brazil/B3")

chck_dts <- tibble(refdate = chck_dts)

bdrs |>
  filter(symbol == "AAPL34") |>
  full_join(chck_dts) |>
  arrange(refdate) |>
  pull(close, as_vector = TRUE) |>
  anyNA()

# Equities ----

equities <- cotahist_get() |>
  cotahist_filter_equity()

equities |>
  group_by(symbol) |>
  count(sort = TRUE) |>
  head(15) |>
  collect()

symbol_ <- "ABEV3"

equities |>
  filter(symbol == symbol_) |>
  arrange(refdate) |>
  collect() |>
  ggplot(aes(x = refdate, y = distribution_id)) +
  geom_line()

equities |>
  filter(symbol == symbol_) |>
  arrange(refdate) |>
  collect() |>
  ggplot(aes(x = refdate, y = close, colour = factor(distribution_id))) +
  geom_line()

## check for missing points ----

date_range <- equities |>
  summarise(min = min(refdate), max = max(refdate)) |>
  collect()

chck_dts <- bizseq(date_range$min, date_range$max, "Brazil/B3")

chck_dts <- tibble(refdate = chck_dts)

equities |>
  filter(symbol == symbol_) |>
  full_join(chck_dts) |>
  arrange(refdate) |>
  pull(close, as_vector = TRUE) |>
  anyNA()
