
library(rb3)
library(tidyverse)
library(bizdays)
library(purrr)

source("examples/companies-info.R")

chy <- cotahist_get(Sys.Date(), "yearly")
eqs <- cotahist_equity_get(chy)
symbols_table <- cotahist_equity_symbols_get(chy)

cash_divs_df <- company_cash_dividends_get(eqs$symbol)