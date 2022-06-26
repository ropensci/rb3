
cotahist_equity_symbols_get <- function(ch) {
  df <- ch[["HistoricalPrices"]] |>
    filter(
      .data$tipo_mercado %in% 10,
      str_sub(.data$cod_isin, 7, 9) %in% c("UNT", "CDA", "ACN")
    )

  spec_split <- df[["especificacao"]] |> str_split("\\s+")
  codes <- parse_isin(df[["cod_isin"]])
  codes[["spec_type"]] <- spec_split |> map_chr(\(x) x[1])
  codes[["symbol"]] <- df[["cod_negociacao"]]
  codes |>
    select(
      symbol, asset_name, spec_type, isin_spec_type, isin, country
    ) |>
    unique() |>
    arrange(symbol)
}

smartget <- function(key, dict) {
  x <- try(get(key, dict, inherits = FALSE), TRUE)
  if (is(x, "try-error")) {
    NA
  } else {
    x
  }
}

parse_isin <- function(isin) {
  tibble(
    isin = isin,
    country = str_sub(isin, 1, 2),
    asset_name = str_sub(isin, 3, 6),
    asset_type = str_sub(isin, 7, 9),
    isin_spec_type = str_sub(isin, 10, 11),
    control = str_sub(isin, 12)
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
    activity = as.character(company_details$Info$activity),
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
    quoted_since = company_info$Info$quotedPerSharSince,
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
  company_info <- .company_supplement_get(code)

  template <- "GetDetailsCompany"
  f <- download_marketdata(template, code_cvm = company_info$Info$codeCVM)
  company_details <- read_marketdata(f, template)

  if (is.null(company_info$StockDividends)) {
    return(NULL)
  }

  company_info$StockDividends |>
    rename(
      isin = isinCode,
      approved = approvedOn,
      last_date_prior_ex = lastDatePrior,
      description = label
    ) |>
    select(isin, approved, last_date_prior_ex, description, factor)
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

.company_subscriptions_get <- function(code) {
  company_info <- .company_supplement_get(code)

  template <- "GetDetailsCompany"
  f <- download_marketdata(template, code_cvm = company_info$Info$codeCVM)
  company_details <- read_marketdata(f, template)

  if (is.null(company_info$Subscriptions)) {
    return(NULL)
  }

  company_info$Subscriptions |>
    rename(
      isin = isinCode,
      approved = approvedOn,
      last_date_prior_ex = lastDatePrior,
      description = label,
      trading_period = tradingPeriod,
      price_unit = priceUnit,
      subscription_date = subscriptionDate,
    ) |>
    select(
      isin, approved, last_date_prior_ex, description, percentage,
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

.company_cash_dividends_get <- function(code) {
  company_info <- .company_supplement_get(code)

  # template <- "GetDetailsCompany"
  # f <- download_marketdata(template, code_cvm = company_info$Info$codeCVM)
  # company_details <- read_marketdata(f, template)

  template <- "GetListedCashDividends"
  f <- download_marketdata(template,
    trading_name = company_info$Info$tradingName
  )
  company_dividends <- read_marketdata(f, template)

  # Proventos distribuídos pelo emissor nos últimos 12 meses ou o último,
  # se anterior aos 12 últimos meses.
  # cs1 <- if (!is.null(company_info$CashDividends)) {
  #   company_info$CashDividends |>
  #     left_join(symbols_table, c("isinCode" = "isin")) |>
  #     mutate(
  #       closing_date_prior_ex = NA,
  #       closing_price_prior_ex = NA,
  #       quoted_per_shares = NA,
  #       corporate_action_price = NA,
  #       ratio = 1,
  #     ) |>
  #     rename(
  #       approved = approvedOn,
  #       payment_date = paymentDate,
  #       last_date_prior_ex = lastDatePrior,
  #       description = label,
  #       value_cash = rate,
  #     ) |>
  #     select(
  #       symbol, asset_name, spec_type, description, approved,
  #       last_date_prior_ex, value_cash, ratio, payment_date,
  #       closing_date_prior_ex, closing_price_prior_ex, quoted_per_shares,
  #       corporate_action_price
  #     )
  # } else {
  #   NULL
  # }

  # Data do Últ. Preço 'Com' (III) - dateClosingPricePriorExDate
  # (III) - A informação 'preço teórico' indica que a ação não apresentou
  # cotação na B3 desde que ficou 'ex' a algum provento anterior.
  # Se tal data estiver em branco, significa que não houve negócio com o ativo.
  cs2 <- if (!is.null(company_dividends)) {
    company_dividends |>
      mutate(
        asset_name = company_info$Info$code
      ) |>
      # left_join(
      #   symbols_table,
      #   c("typeStock" = "spec_type", "asset_name" = "asset_name")
      # ) |>
      rename(
        spec_type = typeStock,
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
        asset_name, spec_type, description, approved,
        last_date_prior_ex, value_cash, ratio,
        closing_date_prior_ex, closing_price_prior_ex, quoted_per_shares,
        corporate_action_price
      )
  } else {
    NULL
  }

  if (anyNA(cs2$spec_type)) {
    warning(str_glue(code, " NA spec_type error"))
  }

  # bind_rows(cs1, cs2)
  cs2
}

company_cash_dividends_get <- function(symbols, symbols_table) {
  codes <- tibble(
    symbol = symbols,
    asset_name = str_sub(symbol, 1, 4)
  ) |>
    group_by(asset_name) |>
    summarise(symbols = list(symbol))

  rxx <- function(x, idx = 0) {
    codes_ <- codes[x, ]
    res <- if (idx == 0) {
      try(
        .company_cash_dividends_get(codes_$asset_name),
        TRUE
      )
    } else {
      try(
        .company_cash_dividends_get(codes_$symbols[[1]][idx]),
        TRUE
      )
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