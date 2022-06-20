library(rb3)
library(tidyverse)
library(bizdays)
library(purrr)


ch <- cotahist_get(preceding(Sys.Date() - 1, "Brazil/ANBIMA"), "daily")

eqs <- cotahist_equity_get(ch)

eqs |> distinct(symbol)

company_info_get <- function(symbol) {
  print(symbol)
  asset_name <- str_sub(symbol, 1, 4)
  template <- "GetListedSupplementCompany"
  f <- download_marketdata(template, company_name = asset_name)
  company_info <- read_marketdata(f, template)
  template <- "GetDetailsCompany"
  f <- download_marketdata(template, code_cvm = company_info$Info$codeCVM)
  company_details <- read_marketdata(f, template)

  segment <- str_split(company_details$Info$industryClassification, "/")
  segment <- list(segment[[1]] |> str_trim())
  tibble(
    symbol = symbol,
    trading_name = company_info$Info$tradingName,
    company_name = company_details$Info$companyName,
    activity = company_details$Info$activity,
    stock_capital = company_info$Info$stockCapital,
    code_cvm = company_info$Info$codeCVM,
    total_shares = company_info$Info$totalNumberShares,
    common_shares = company_info$Info$numberCommonShares,
    preferred_shares = company_info$Info$numberPreferredShares,
    codes = list(company_details$OtherCodes$code),
    segment = segment,
  )
}

company_df <- map_dfr(eqs$symbol, company_info_get)

company_info_get("ALPK3")

company_dividends_get <- function(symbol) {
  asset_name <- str_sub(symbol, 1, 4)
  template <- "GetListedSupplementCompany"
  f <- download_marketdata(template, company_name = asset_name)
  company_info <- read_marketdata(f, template)
  template <- "GetListedCashDividends"
  f <- download_marketdata(template, trading_name = company_info$Info$tradingName)
  company_dividends <- read_marketdata(f, template)
  tibble(
    symbol = symbol,
  )
}


asset_name <- str_sub(symbol, 1, 4)
template <- "GetListedSupplementCompany"
f <- download_marketdata(template, company_name = "ALPK")
company_info <- read_marketdata(f, template)

template <- "GetDetailsCompany"
f <- download_marketdata(template, code_cvm = company_info$Info$codeCVM)
company_details <- read_marketdata(f, template)

template <- "GetListedCashDividends"
f <- download_marketdata(template, trading_name = company_info$Info$tradingName)
company_dividends <- read_marketdata(f, template)