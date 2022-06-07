library(rb3)
library(tidyverse)

ch <- cotahist_get(Sys.Date(), "yearly")

fii <- cotahist_fiis_get(ch)

symbols <- fii |>
  group_by(symbol) |>
  summarise(volume = sum(volume)) |>
  slice_max(volume, n = 10) |>
  pull(symbol)

fii |>
  filter(symbol %in% symbols) |>
  ggplot(aes(x = refdate, y = volume, group = symbol, colour = symbol)) +
  geom_line() +
  scale_y_continuous(labels = scales::label_number_si())

eq <- cotahist_equity_get(ch)

symbols_eq <- eq |>
  group_by(symbol) |>
  summarise(volume = sum(volume)) |>
  slice_max(volume, n = 10) |>
  pull(symbol)

eq |>
  filter(symbol %in% symbols_eq) |>
  ggplot(aes(x = refdate, y = volume, group = symbol, colour = symbol)) +
  geom_line() +
  scale_y_continuous(labels = scales::label_number_si())

etfs <- cotahist_etfs_get(ch)

symbols_etfs <- etfs |>
  group_by(symbol) |>
  summarise(volume = sum(volume)) |>
  slice_max(volume, n = 10) |>
  pull(symbol)

etfs |>
  filter(symbol %in% symbols_etfs) |>
  ggplot(aes(x = refdate, y = volume, group = symbol, colour = symbol)) +
  geom_line() +
  scale_y_continuous(labels = scales::label_number_si())

# ----

library(rb3)
library(tidyverse)

ch <- cotahist_get(Sys.Date(), "yearly")

etfs <- cotahist_etfs_get(ch)

total_volume <- etfs |>
  summarise(volume = sum(volume)) |>
  pull(volume)

fmt <- scales::label_percent(accuracy = 0.1)

etfs |>
  group_by(symbol) |>
  summarise(volume = sum(volume)) |>
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

# ----

library(tidyverse)

ch <- cotahist_get("2021-12-01", "monthly")

symbols <- c(
  "ABEV3", "BBAS3", "B3SA3", "CIEL3", "EGIE3", "EZTC3", "INTB3", "ITSA4",
  "LREN3", "OIBR3", "PSSA3", "SBFG3", "WEGE3"
)
pos <- c(1202, 400, 1500, 1000, 800, 800, 299, 1050, 776, 5000, 930, 200, 100)
names(pos) <- symbols
df <- cotahist_get_symbols(ch, symbols)
max_date <- max(df$refdate)
symbols_ <- df |>
  filter(refdate == max_date) |>
  pull(symbol)
closing <- df |>
  filter(refdate == max_date) |>
  pull(close)
names(closing) <- symbols_

c1 <- (closing[symbols] * pos[symbols])
cbind(c1, pos)

rbcb::get_series(1619)