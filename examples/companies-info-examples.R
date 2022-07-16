
library(rb3)
library(tidyverse)
library(bizdays)
library(purrr)

source("examples/companies-info.R")

ch <- cotahist_get(getdate("last bizday", Sys.Date(), "Brazil/ANBIMA"), "daily")
eqs <- cotahist_equity_get(ch)

divs_df <- company_stock_dividends_get(eqs$symbol)
subs_df <- company_subscriptions_get(eqs$symbol)
symbols_table <- cotahist_equity_symbols_get(ch)
cash_divs_df <- company_cash_dividends_get(eqs$symbol, symbols_table)
company_df <- company_info_get(eqs$symbol)

company_df |>
  group_by(sector) |>
  summarise(
    market_cap = sum(stock_capital),
    n = n()
  ) |>
  arrange(n)

# ----

template <- "GetListedSupplementCompany"
f <- download_marketdata(template, company_name = "ITUB")
company_info <- read_marketdata(f, template)

template <- "GetDetailsCompany"
f <- download_marketdata(template, code_cvm = company_info$Info$codeCVM)
company_details <- read_marketdata(f, template)

template <- "GetListedCashDividends"
f <- download_marketdata(template, trading_name = company_info$Info$tradingName)
company_dividends <- read_marketdata(f, template)