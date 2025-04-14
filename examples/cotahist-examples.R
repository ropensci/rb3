library(rb3)
library(tidyverse)
library(lubridate)

fetch_marketdata("b3-cotahist-yearly", year = 2018:2024)

ch <- cotahist_get("yearly")

# FIIs ----
#
# FII volume

fii <- ch |> cotahist_filter_fii() |> filter(year(refdate) == 2024)

symbols <- fii |>
  group_by(symbol) |>
  summarise(volume = sum(volume)) |>
  arrange(desc(volume)) |>
  head(10) |>
  pull(symbol, as_vector = TRUE)

fii_monthly <- fii |>
  filter(symbol %in% symbols) |>
  mutate(month = floor_date(refdate, "month")) |>
  group_by(month, symbol) |>
  summarise(volume = sum(volume)) |>
  collect()

fii_monthly |>
  ggplot(aes(x = month, y = volume, group = symbol, colour = symbol)) +
  geom_line() +
  scale_y_continuous(labels = scales::label_number())

# Equities ----
## Equities volume ----

eq <- ch |> filter(year(refdate) == 2024) |> cotahist_filter_equity()

symbols_eq <- eq |>
  group_by(symbol) |>
  summarise(volume = sum(volume)) |>
  arrange(desc(volume)) |>
  head(10) |>
  pull(symbol, as_vector = TRUE)

eq_monthly <- eq |>
  filter(symbol %in% symbols_eq) |>
  mutate(month = floor_date(refdate, "month")) |>
  group_by(month, symbol) |>
  summarise(volume = sum(volume)) |>
  collect()

eq_monthly |>
  ggplot(aes(x = month, y = volume, group = symbol, colour = symbol)) +
  geom_line() +
  scale_y_continuous(labels = scales::label_number())

## see distribution_id ----

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

# ETFs ----
#

etfs <- ch |> filter(year(refdate) == 2024) |> cotahist_filter_etf()

symbols <- etfs |>
  group_by(symbol) |>
  summarise(volume = sum(volume)) |>
  arrange(desc(volume)) |>
  head(10) |>
  pull(symbol, as_vector = TRUE)

etfs_monthly <- etfs |>
  filter(symbol %in% symbols) |>
  mutate(month = floor_date(refdate, "month")) |>
  group_by(month, symbol) |>
  summarise(volume = sum(volume)) |>
  collect()

etfs_monthly |>
  ggplot(aes(x = month, y = volume, group = symbol, colour = symbol)) +
  geom_line() +
  scale_y_continuous(labels = scales::label_number())

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

# ----

total_volume <- etfs |>
  summarise(volume = sum(volume)) |>
  pull(volume, as_vector = TRUE)

fmt <- scales::label_percent(accuracy = 0.1)

etfs |>
  group_by(symbol) |>
  summarise(volume = sum(volume)) |>
  collect() |>
  mutate(volume_ratio = volume / total_volume) |>
  slice_max(volume_ratio, n = 10) |>
  mutate(volume_ratio_acc = cumsum(volume_ratio)) |>
  ggplot(aes(
    x = reorder(symbol, -volume_ratio), y = volume_ratio,
    label = fmt(volume_ratio)
  )) +
  geom_bar(stat = "identity", fill = "royalblue") +
  geom_text(nudge_y = 0.01) +
  scale_y_continuous(labels = scales::label_percent()) +
  labs(
    x = NULL, y = NULL,
    title = "Volume Financeiro das 10 Maiores ETFs",
    subtitle = "Percentual Volume Financeiro Negociado nas 10 Maiores ETFs em 2022",
    caption = "Dados obtidos com \U0001F4E6 rb3 - wilsonfreitas"
  )

symbols_etfs <- etfs |>
  group_by(symbol) |>
  summarise(volume = sum(volume)) |>
  collect() |>
  slice_max(volume, n = 5) |>
  pull(symbol)

total_volume <- etfs |>
  group_by(month = strftime(refdate, "%Y-%m")) |>
  summarise(volume = sum(volume)) |>
  pull(volume, as_vector = TRUE)

etfs |>
  filter(symbol %in% symbols_etfs) |>
  group_by(symbol, month = strftime(refdate, "%Y-%m")) |>
  summarise(volume = sum(volume)) |>
  collect() |>
  mutate(
    volume_ratio = volume / total_volume,
    volume_ratio_acc = cumsum(volume_ratio)
  ) |>
  ggplot(aes(
    x = month, y = volume_ratio, group = symbol, fill = symbol,
    label = fmt(volume_ratio)
  )) +
  geom_bar(stat = "identity", position = "stack") +
  geom_text(position = "stack") +
  scale_y_continuous(labels = scales::label_percent(), limits = c(0, 1), n.breaks = 6) +
  labs(
    x = NULL, y = NULL,
    title = "Volume Financeiro das 10 Maiores ETFs",
    subtitle = "Percentual Volume Financeiro no mês Negociado nas 10 Maiores ETFs em 2024",
    caption = "Dados obtidos com \U0001F4E6 rb3 - wilsonfreitas"
  )
