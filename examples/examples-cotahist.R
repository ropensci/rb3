
library(rb3)
library(tidyverse)

dates <- seq(as.Date("2018-01-01"), Sys.Date(), by = "years")

chs <- map(dates, cotahist_get)

bdrs <- map_dfr(chs, cotahist_bdrs_get)

bdrs |>
  group_by(symbol) |>
  count(sort = TRUE) |>
  head(20) |>
  View()

bdrs |>
  filter(symbol == "AAPL34") |>
  arrange(refdate) |>
  ggplot(aes(x = refdate, y = transactions_quantity, colour = factor(distribution_id))) +
  geom_line()

bdrs |>
  filter(symbol == "DISB34") |>
  arrange(refdate) |>
  ggplot(aes(x = refdate, y = distribution_id)) +
  geom_line()

chck_dts <- bizseq(min(bdrs$refdate), max(bdrs$refdate), "Brazil/B3")

chck_dts <- tibble(refdate = chck_dts)

bdrs |>
  filter(symbol == "AAPL34") |>
  full_join(chck_dts) |>
  arrange(refdate) |>
  pull(close)


equities <- map_dfr(chs, cotahist_equity_get)

equities |>
  group_by(symbol) |>
  count(sort = TRUE) |>
  head(20) |>
  View()

symbol_ <- "ABEV3"

equities |>
  filter(symbol == symbol_) |>
  arrange(refdate) |>
  ggplot(aes(x = refdate, y = distribution_id)) +
  geom_line()

equities |>
  filter(symbol == symbol_) |>
  arrange(refdate) |>
  ggplot(aes(x = refdate, y = close, colour = factor(distribution_id))) +
  geom_line()

chck_dts <- bizseq(min(equities$refdate), max(equities$refdate), "Brazil/B3")

chck_dts <- tibble(refdate = chck_dts)

equities |>
  filter(symbol == symbol_) |>
  full_join(chck_dts) |>
  arrange(refdate) |>
  pull(close)