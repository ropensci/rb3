library(rb3)
library(tidyverse)
library(bizdays)
library(purrr)

ch <- cotahist_get(preceding(Sys.Date() - 1, "Brazil/ANBIMA"), "daily")
eqs <- cotahist_equity_get(ch)

parse_isin <- function(isin) {
  tibble(
    isin = isin,
    country = str_sub(isin, 1, 2),
    asset_name = str_sub(isin, 3, 6),
    asset_type = str_sub(isin, 7, 9),
    spec_type = str_sub(isin, 10, 11),
    control = str_sub(isin, 12)
  ) |> mutate(
    spec_type = str_replace(spec_type, "PR", "PN"),
    spec_type = str_replace(spec_type, "OR", "ON")
  )
}

create_codes <- function(codes) {
  left_join(codes, parse_isin(codes$isin), "isin") |>
    rename(symbol = code)
}

.company_supplement_get <- function(code) {
  template <- "GetListedSupplementCompany"
  f <- download_marketdata(template, company_name = code)
  read_marketdata(f, template)
}

.company_info_get <- function(code) {
  company_info <- .company_supplement_get(code)

  template <- "GetDetailsCompany"
  f <- download_marketdata(template, code_cvm = company_info$Info$codeCVM)
  company_details <- read_marketdata(f, template)

  sectors <- str_split(company_details$Info$industryClassification, "/")
  sectors <- sectors[[1]] |> str_trim()
  tibble(
    asset_name = company_info$Info$code,
    trading_name = company_info$Info$tradingName,
    company_name = company_details$Info$companyName,
    activity = company_details$Info$activity,
    stock_capital = company_info$Info$stockCapital,
    code_cvm = company_info$Info$codeCVM,
    total_shares = company_info$Info$totalNumberShares,
    common_shares = company_info$Info$numberCommonShares,
    preferred_shares = company_info$Info$numberPreferredShares,
    codes = list(company_details$OtherCodes),
    sector = sectors[1],
    subsector = sectors[2],
    market_segment = sectors[3],
    round_lot = company_info$Info$roundLot,
    quoted_since = company_info$Info$quotedPerShareSince,
    segment = company_info$Info$segment
  )
}

company_info_get <- function(symbols) {
  codes <- tibble(
    symbol = symbols,
    asset_name = str_sub(symbol, 1, 4)
  ) |>
    group_by(asset_name) |>
    summarise(symbols = list(symbol))

  rxx <- function(x, idx = 0) {
    codes_ <- codes[x, ]
    res <- if (idx == 0) {
      try(.company_info_get(codes_$asset_name), TRUE)
    } else {
      try(.company_info_get(codes_$symbols[[1]][idx]), TRUE)
    }
    if (is(res, "try-error") && length(codes_$symbols[[1]]) >= idx + 1) {
      rxx(x, idx + 1)
    } else {
      res
    }
  }
  companies_list <- map(seq_len(nrow(codes)), rxx)
  bind_rows(companies_list)
}

.company_stock_dividends_get <- function(code) {
  company_info <- .company_supplement_get("ABEV3")

  template <- "GetDetailsCompany"
  f <- download_marketdata(template, code_cvm = company_info$Info$codeCVM)
  company_details <- read_marketdata(f, template)

  if (is.null(company_info$StockDividends)) {
    return(NULL)
  }

  company_info$StockDividends |>
    left_join(company_details$OtherCodes, by = c("isinCode" = "isin")) |>
    rename(
      symbol = code,
      isin = isinCode,
      approved = approvedOn,
      last_date_prior_ex = lastDatePrior,
      description = label
    ) |>
    select(symbol, isin, approved, last_date_prior_ex, description, factor)
}

company_stock_dividends_get <- function(symbols) {
  codes <- tibble(
    symbol = symbols,
    asset_name = str_sub(symbol, 1, 4)
  ) |>
    group_by(asset_name) |>
    summarise(symbols = list(symbol))

  rxx <- function(x, idx = 0) {
    codes_ <- codes[x, ]
    res <- if (idx == 0) {
      try(.company_stock_dividends_get(codes_$asset_name), TRUE)
    } else {
      try(.company_stock_dividends_get(codes_$symbols[[1]][idx]), TRUE)
    }
    if (is(res, "try-error") && length(codes_$symbols[[1]]) >= idx + 1) {
      rxx(x, idx + 1)
    } else {
      res
    }
  }
  companies_list <- map(seq_len(nrow(codes)), rxx)
  bind_rows(companies_list)
}

company_stock_dividends_get(c("TXRX3", "TXRX4"))
divs_df <- company_stock_dividends_get(eqs$symbol)

.company_subscriptions_get <- function(code) {
  company_info <- .company_supplement_get(code)

  template <- "GetDetailsCompany"
  f <- download_marketdata(template, code_cvm = company_info$Info$codeCVM)
  company_details <- read_marketdata(f, template)

  if (is.null(company_info$Subscriptions)) {
    return(NULL)
  }

  company_info$Subscriptions |>
    left_join(company_details$OtherCodes, by = c("isinCode" = "isin")) |>
    rename(
      symbol = code,
      isin = isinCode,
      approved = approvedOn,
      last_date_prior_ex = lastDatePrior,
      description = label,
      trading_period = tradingPeriod,
      price_unit = priceUnit,
      subscription_date = subscriptionDate,
    ) |>
    select(
      symbol, isin, approved, last_date_prior_ex, description, percentage,
      trading_period, price_unit, subscription_date
    )
}

company_subscriptions_get <- function(symbols) {
  codes <- tibble(
    symbol = symbols,
    asset_name = str_sub(symbol, 1, 4)
  ) |>
    group_by(asset_name) |>
    summarise(symbols = list(symbol))

  rxx <- function(x, idx = 0) {
    codes_ <- codes[x, ]
    res <- if (idx == 0) {
      try(.company_subscriptions_get(codes_$asset_name), TRUE)
    } else {
      try(.company_subscriptions_get(codes_$symbols[[1]][idx]), TRUE)
    }
    if (is(res, "try-error") && length(codes_$symbols[[1]]) >= idx + 1) {
      rxx(x, idx + 1)
    } else {
      res
    }
  }
  companies_list <- map(seq_len(nrow(codes)), rxx)
  bind_rows(companies_list)
}

subs_df <- company_subscriptions_get(eqs$symbol)

.company_cash_dividends_get <- function(code) {
  company_info <- .company_supplement_get(code)

  template <- "GetDetailsCompany"
  f <- download_marketdata(template, code_cvm = company_info$Info$codeCVM)
  company_details <- read_marketdata(f, template)

  template <- "GetListedCashDividends"
  f <- download_marketdata(template, trading_name = company_info$Info$tradingName)
  company_dividends <- read_marketdata(f, template)

  codes <- create_codes(company_details$OtherCodes)

  cs1 <- if (!is.null(company_info$CashDividends)) {
    company_info$CashDividends |>
      left_join(codes, c("isinCode" = "isin")) |>
      mutate(
        closing_date_prior_ex = NA,
        closing_price_prior_ex = NA,
        quoted_per_shares = NA,
        corporate_action_price = NA,
        ratio = 1,
      ) |>
      rename(
        approved = approvedOn,
        payment_date = paymentDate,
        last_date_prior_ex = lastDatePrior,
        description = label,
        value_cash = rate,
      ) |>
      select(
        symbol, description, approved, last_date_prior_ex,
        value_cash, ratio, payment_date, closing_date_prior_ex,
        closing_price_prior_ex, quoted_per_shares, corporate_action_price
      )
  } else {
    NULL
  }

  cs2 <- if (!is.null(company_dividends)) {
    company_dividends |>
      mutate(
        asset_name = company_info$Info$code,
        payment_date = NA,
      ) |>
      left_join(codes, c("typeStock" = "spec_type", "asset_name" = "asset_name")) |>
      rename(
        approved = dateApproval,
        last_date_prior_ex = lastDatePriorEx,
        closing_date_prior_ex = dateClosingPricePriorExDate,
        closing_price_prior_ex = closingPricePriorExDate,
        quoted_per_shares = quotedPerShares,
        corporate_action_price = corporateActionPrice,
        description = corporateAction,
        value_cash = valueCash,
      ) |>
      select(
        symbol, description, approved, last_date_prior_ex,
        value_cash, ratio, payment_date, closing_date_prior_ex,
        closing_price_prior_ex, quoted_per_shares, corporate_action_price
      )
  } else {
    NULL
  }

  bind_rows(cs1, cs2)
}

company_cash_dividends_get <- function(symbols) {
  codes <- tibble(
    symbol = symbols,
    asset_name = str_sub(symbol, 1, 4)
  ) |>
    group_by(asset_name) |>
    summarise(symbols = list(symbol))

  rxx <- function(x, idx = 0) {
    codes_ <- codes[x, ]
    res <- if (idx == 0) {
      try(.company_cash_dividends_get(codes_$asset_name), TRUE)
    } else {
      try(.company_cash_dividends_get(codes_$symbols[[1]][idx]), TRUE)
    }
    if (is(res, "try-error") && length(codes_$symbols[[1]]) >= idx + 1) {
      rxx(x, idx + 1)
    } else {
      res
    }
  }
  companies_list <- map(seq_len(nrow(codes)), rxx)
  bind_rows(companies_list)
}

company_cash_dividends_get("ALPK4")
cash_divs_df <- company_cash_dividends_get(eqs$symbol)

company_df <- company_info_get(eqs$symbol)

company_df |>
  group_by(sector) |>
  summarise(
    market_cap = sum(stock_capital),
    n = n()
  ) |>
  arrange(n)

.company_cash_dividends_get("BBDC") |>
  arrange(symbol, desc(approved), desc(last_date_prior_ex))

template <- "GetListedSupplementCompany"
f <- download_marketdata(template, company_name = "ALPK")
company_info <- read_marketdata(f, template)

template <- "GetDetailsCompany"
f <- download_marketdata(template, code_cvm = company_info$Info$codeCVM)
company_details <- read_marketdata(f, template)

template <- "GetListedCashDividends"
f <- download_marketdata(template, trading_name = company_info$Info$tradingName)
company_dividends <- read_marketdata(f, template)