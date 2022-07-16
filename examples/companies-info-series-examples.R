
library(rb3)
library(tidyverse)
library(bizdays)
library(purrr)

source("examples/companies-info.R")

chy <- cotahist_get("2018-01-01", "yearly")
eqs <- cotahist_equity_get(chy)
symbols_table <- cotahist_equity_symbols_get(chy)

cash_divs_df <- company_cash_dividends_get(eqs$symbol, symbols_table)

divs <- cash_divs_df |>
  filter(format(last_date_prior_ex, "%Y") == "2018")

# ----

cash_divs_df |>
  filter(symbol == "TAEE11") |>
  group_by(ano = format(last_date_prior_ex, "%Y")) |>
  summarise(value_cash = sum(value_cash)) |>
  ggplot(aes(x = ano, y = value_cash, group = 1)) +
  geom_line() +
  geom_point() +
  geom_smooth(method = lm)

# ----

symbol_ <- "EGIE3"

eqs |>
  filter(symbol == symbol_) |>
  arrange(refdate) |>
  mutate(change = c(diff(distribution_id), NA)) |>
  filter(change == 1)

divs |>
  filter(symbol == symbol_)

.company_cash_dividends_get("B3SA") |>
  filter(format(last_date_prior_ex, "%Y") == "2017")
.company_info_cash_dividends_get("EGIE")
.company_stock_dividends_get("EGIE")
.company_subscriptions_get("EGIE")

# ----

divs |>
  count(symbol, sort = TRUE)

# ----

symbol_ <- "B3SA3"

eqs |>
  select(refdate, symbol, close, distribution_id) |>
  left_join(
    divs |>
      select(symbol, description, last_date_prior_ex, value_cash, ratio),
    c("symbol", "refdate" = "last_date_prior_ex")
  ) |>
  filter(symbol == symbol_) |>
  arrange(refdate) |>
  View(title = symbol_)

# -----

cash_divs_df |>
  filter(symbol == symbol_)