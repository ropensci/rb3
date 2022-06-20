library(rb3)
library(tidyverse)
library(bizdays)
library(purrr)

ch <- cotahist_get(preceding(Sys.Date() - 1, "Brazil/ANBIMA"), "daily")

eqs <- cotahist_equity_get(ch)

eqs |> distinct(symbol)

company_info_get <- function(symbol) {
  cat(symbol, "\n")
  template <- "GetListedSupplementCompany"
  f <- download_marketdata(template, company_name = symbol)
  company_info <- try(read_marketdata(f, template), TRUE)
  if (is(company_info, "try-error")) {
    f <- download_marketdata(template, company_name = str_sub(symbol, 1, 4))
    company_info <- try(read_marketdata(f, template), TRUE)
  }
  template <- "GetDetailsCompany"
  f <- download_marketdata(template, code_cvm = company_info$Info$codeCVM)
  company_details <- read_marketdata(f, template)

  segment <- str_split(company_details$Info$industryClassification, "/")
  segment <- list(segment[[1]] |> str_trim())
  df <- tibble(
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
  df$id <- digest::digest(df)
  df$symbol <- symbol
  df
}

company_df <- map(eqs$symbol, company_info_get)

company_df <- do.call(rbind, company_df)

companies_list <- split(company_df, company_df$id)

company_df <- map_dfr(companies_list, function(x) x[1, ])

company_df$segment |>
  map_lgl(\(x) length(x) == 3) |>
  all()

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
f <- download_marketdata(template, company_name = "TRPL3")
company_info <- read_marketdata(f, template)

template <- "GetDetailsCompany"
f <- download_marketdata(template, code_cvm = company_info$Info$codeCVM)
company_details <- read_marketdata(f, template)

template <- "GetListedCashDividends"
f <- download_marketdata(template, trading_name = company_info$Info$tradingName)
company_dividends <- read_marketdata(f, template)