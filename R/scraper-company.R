.company_supplement_get <- function(code,
                                    cache_folder = cachedir(),
                                    do_cache = TRUE) {
  template <- "GetListedSupplementCompany"
  f <- download_marketdata(template,
    company_name = code,
    cache_folder = cache_folder,
    do_cache = do_cache
  )
  read_marketdata(f, template, do_cache = do_cache)
}

.company_supplementary_info_get <- function(code, company_supl,
                                        cache_folder = cachedir(),
                                        do_cache = TRUE) {
  template <- "GetDetailsCompany"
  f <- download_marketdata(template,
    code_cvm = company_supl$Info$codeCVM,
    cache_folder = cache_folder,
    do_cache = do_cache
  )
  company_details <- read_marketdata(f, template, do_cache = do_cache)

  sectors <- str_split(company_details$Info$industryClassification, "/")
  sectors <- sectors[[1]] |> str_trim()
  codes <- company_details$OtherCodes
  codes$asset_name <- company_supl$Info$code
  codes <- rename(codes, symbol = code)
  tibble(
    asset_name = company_supl$Info$code,
    trading_name = company_supl$Info$tradingName,
    company_name = company_details$Info$companyName,
    activity = as.character(company_details$Info$activity),
    stock_capital = company_supl$Info$stockCapital,
    code_cvm = company_supl$Info$codeCVM,
    total_shares = company_supl$Info$totalNumberShares,
    common_shares = company_supl$Info$numberCommonShares,
    preferred_shares = company_supl$Info$numberPreferredShares,
    codes = list(codes),
    sector = sectors[1],
    subsector = sectors[2],
    market_segment = sectors[3],
    round_lot = company_supl$Info$roundLot,
    quoted_since = company_supl$Info$quotedPerSharSince,
    segment = company_supl$Info$segment
  )
}

.company_supplementary_stock_dividends_get <- function(code, company_supl,
                                                   cache_folder = cachedir(),
                                                   do_cache = TRUE) {
  company_info <- .company_supplementary_info_get(code, company_supl,
    cache_folder = cache_folder,
    do_cache = do_cache
  )

  if (is.null(company_supl$StockDividends)) {
    return(NULL)
  }

  divs <- company_supl$StockDividends |>
    rename(
      isin = "isinCode",
      approved = "approvedOn",
      last_date_prior_ex = "lastDatePrior",
      description = "label"
    ) |>
    select("isin", "approved", "last_date_prior_ex", "description", "factor")

  inner_join(company_info$codes[[1]], divs, by = "isin")
}

.company_supplementary_subscriptions_get <- function(code, company_supl,
                                                 cache_folder = cachedir(),
                                                 do_cache = TRUE) {
  company_info <- .company_supplementary_info_get(code, company_supl,
    cache_folder = cache_folder,
    do_cache = do_cache
  )

  if (is.null(company_supl$Subscriptions)) {
    return(NULL)
  }

  subs <- company_supl$Subscriptions |>
    rename(
      isin = "isinCode",
      approved = "approvedOn",
      last_date_prior_ex = "lastDatePrior",
      description = "label",
      trading_period = "tradingPeriod",
      price_unit = "priceUnit",
      subscription_date = "subscriptionDate",
    ) |>
    select("isin", "approved", "last_date_prior_ex", "description",
           "percentage", "trading_period", "price_unit", "subscription_date")

  inner_join(company_info$codes[[1]], subs, by = "isin")
}

.company_supplementary_cash_dividends_get <- function(code, company_supl,
                                                  cache_folder = cachedir(),
                                                  do_cache = TRUE) {
  # Proventos distribuídos pelo emissor nos últimos 12 meses ou o último,
  # se anterior aos 12 últimos meses.
  if (!is.null(company_supl$CashDividends)) {
    company_info <- .company_supplementary_info_get(code, company_supl,
      cache_folder = cache_folder,
      do_cache = do_cache
    )

    divs <- company_supl$CashDividends |>
      mutate(ratio = 1) |>
      rename(
        isin = "isinCode",
        approved = "approvedOn",
        last_date_prior_ex = "lastDatePrior",
        description = "label",
        value_cash = "rate",
      ) |>
      select("isin", "description", "approved", "last_date_prior_ex",
             "value_cash", "ratio")
    
    inner_join(company_info$codes[[1]], divs, by = "isin")
  } else {
    NULL
  }
}

.company_listed_cash_dividends_get <- function(code, company_supl,
                                               cache_folder = cachedir(),
                                               do_cache = TRUE) {
  template <- "GetListedCashDividends"
  f <- download_marketdata(template,
    trading_name = company_supl$Info$tradingName,
    cache_folder = cache_folder,
    do_cache = do_cache
  )
  company_dividends <- read_marketdata(f, template, do_cache = do_cache)

  # Data do Últ. Preço 'Com' (III) - dateClosingPricePriorExDate
  # (III) - A informação 'preço teórico' indica que a ação não apresentou
  # cotação na B3 desde que ficou 'ex' a algum provento anterior.
  # Se tal data estiver em branco, significa que não houve negócio com o ativo.
  if (!is.null(company_dividends)) {
    company_info <- .company_supplementary_info_get(code,
      cache_folder = cache_folder,
      do_cache = do_cache
    )
    codes <- company_info$codes[[1]]
    codes <- inner_join(codes, parse_isin(codes$isin),
      by = c("isin", "asset_name")
    )
    divs <- company_dividends |>
      mutate(
        asset_name = company_supl$Info$code
      ) |>
      rename(
        spec_type = "typeStock",
        approved = "dateApproval",
        last_date_prior_ex = "lastDatePriorEx",
        description = "corporateAction",
        value_cash = "valueCash",
      )
    inner_join(codes, divs, by = c("asset_name", "spec_type")) |>
      select("symbol", "isin", "asset_name", "description", "approved",
             "last_date_prior_ex", "value_cash", "ratio")
  } else {
    NULL
  }
}

.company_mget <- function(func, symbols, cache_folder, do_cache) {
  codes <- tibble(symbol = symbols) |>
    mutate(asset_name = str_sub(.data$symbol, 1, 4)) |>
    group_by(.data$asset_name) |>
    summarise(symbols = list(unique(.data$symbol)))

  rxx <- function(x, idx = 0) {
    codes_ <- codes[x, ]
    company_supl <- .company_supplement_get(codes_$asset_name,
      cache_folder = cache_folder,
      do_cache = do_cache
    )
    res <- if (idx == 0) {
      try(func(codes_$asset_name,
        company_supl = company_supl,
        cache_folder = cache_folder, do_cache = do_cache
      ), TRUE)
    } else {
      try(func(codes_$symbols[[1]][idx],
        company_supl = company_supl,
        cache_folder = cache_folder, do_cache = do_cache
      ), TRUE)
    }
    if (is(res, "try-error")) {
      if (length(codes_$symbols[[1]]) >= idx + 1) {
        rxx(x, idx + 1)
      } else {
        NULL
      }
    } else {
      res
    }
  }
  companies_list <- map(seq_len(nrow(codes)), rxx)
  bind_rows(companies_list)
}

#' Gets information about the company
#'
#' Gets informations like sector, subsector, segment, total number of shares
#' and many more.
#'
#' @param code Represents the company, can be the stock symbol, like `PETR4` or
#' the first four characters `PETR`
#' @param cache_folder Location of cache folder (default = cachedir())
#' @param do_cache Whether to use cache or not (default = TRUE)
#'
#' @return data.frame with company information
#'
#' @details
#'
#' The `code` parameter can be the stock symbol, but the returned data refers
#' to the company, always.
#'
#' @examples
#' \dontrun{
#' company_info_get(c("PETR", "VALE", "MGLU"))
#' }
#'
#' @export
company_info_get <- function(code,
                             cache_folder = cachedir(),
                             do_cache = TRUE) {
  .company_mget(.company_supplementary_info_get, code,
    cache_folder = cache_folder,
    do_cache = do_cache
  )
}

#' Gets company's stocks dividends
#'
#' Gets a list of all stocks dividends paid by the company.
#' *A stock dividend is a payment to shareholders that consists of additional
#' shares rather than cash.* (https://www.investopedia.com/)
#'
#' @param code Represents the company, can be the stock symbol, like `PETR4` or
#' the first four characters `PETR`
#' @param cache_folder Location of cache folder (default = cachedir())
#' @param do_cache Whether to use cache or not (default = TRUE)
#'
#' @return data.frame with all stocks dividends
#'
#' @details
#'
#' The `code` parameter can be the stock symbol, but the returned data refers
#' to the company, always.
#' The returned data.frame has all company's symbols that paid dividends in
#' stocks.
#'
#' @examples
#' \dontrun{
#' company_stock_dividends_get(c("PETR", "VALE", "MGLU"))
#' }
#'
#' @export
company_stock_dividends_get <- function(code,
                                        cache_folder = cachedir(),
                                        do_cache = TRUE) {
  .company_mget(.company_supplementary_stock_dividends_get, code,
    cache_folder = cache_folder,
    do_cache = do_cache
  )
}

#' Gets company's dividents in cash
#'
#' Gets a list of all dividents in cash paid by the company.
#' *A cash dividend is a payment made by a company out of its earnings to
#' investors in the form of cash.* (https://www.investopedia.com/)
#'
#' @param code Represents the company, can be the stock symbol, like `PETR4` or
#' the first four characters `PETR`
#' @param cache_folder Location of cache folder (default = cachedir())
#' @param do_cache Whether to use cache or not (default = TRUE)
#'
#' @return data.frame with company information
#'
#' @details
#'
#' The `code` parameter can be the stock symbol, but the returned data refers
#' to the company, always.
#' The returned data.frame has all company's symbols that paid dividends in
#' cash.
#'
#' @examples
#' \dontrun{
#' company_cash_dividends_get(c("PETR", "VALE", "MGLU"))
#' }
#'
#' @export
company_cash_dividends_get <- function(code,
                                       cache_folder = cachedir(),
                                       do_cache = TRUE) {
  cs1 <- .company_mget(.company_listed_cash_dividends_get, code,
    cache_folder = cache_folder,
    do_cache = do_cache
  )
  cs2 <- .company_mget(.company_supplementary_cash_dividends_get, code,
    cache_folder = cache_folder,
    do_cache = do_cache
  )
  bind_rows(cs1, cs2) |>
    arrange("symbol", "last_date_prior_ex") |>
    unique()
}

#' Gets company's subscription rights
#'
#' Gets a list of all company's subscription rights.
#' *A subscription right is the right of existing shareholders in a company to
#' retain an equal percentage ownership by subscribing to new stock issuances
#' at or below market prices.* (https://www.investopedia.com/)
#'
#' @param code Represents the company, can be the stock symbol, like `PETR4` or
#' the first four characters `PETR`
#' @param cache_folder Location of cache folder (default = cachedir())
#' @param do_cache Whether to use cache or not (default = TRUE)
#'
#' @return data.frame with company information
#'
#' @details
#'
#' The `code` parameter can be the stock symbol, but the returned data refers
#' to the company, always.
#' The returned data.frame has all company's symbols that have issued
#' subscription rights.
#'
#' @examples
#' \dontrun{
#' company_subscriptions_get(c("PDGR", "VALE", "MGLU"))
#' }
#'
#' @export
company_subscriptions_get <- function(code,
                                      cache_folder = cachedir(),
                                      do_cache = TRUE) {
  .company_mget(.company_supplementary_subscriptions_get, code,
    cache_folder = cache_folder,
    do_cache = do_cache
  )
}

cotahist_companies_table_get <- function(ch) {
  df <- ch[["HistoricalPrices"]] |>
    filter(
      "tipo_mercado" %in% 10,
      str_sub("cod_isin", 7, 9) %in% c("UNT", "CDA", "ACN")
    )

  spec_split <- df[["especificacao"]] |> str_split("\\s+")
  codes <- parse_isin(df[["cod_isin"]])
  codes[["spec_type"]] <- spec_split |> map_chr(\(x) x[1])
  codes[["symbol"]] <- df[["cod_negociacao"]]
  codes |>
    select("symbol", "asset_name", "spec_type", "isin_spec_type", "isin",
           "country") |>
    unique() |>
    arrange("symbol")
}

parse_isin <- function(isin) {
  tibble(
    isin = isin,
    country = str_sub(isin, 1, 2),
    asset_name = str_sub(isin, 3, 6),
    asset_type = str_sub(isin, 7, 9),
    isin_spec_type = str_sub(isin, 10, 11),
    spec_type = .spec_type_map("isin_spec_type"),
    control = str_sub(isin, 12)
  )
}

.spec_type_map <- function(isin_spec_type) {
  spec_type_map <- c(
    PR = "PN",
    OR = "ON",
    PA = "PNA",
    PB = "PNB",
    PC = "PNC",
    PD = "PND",
    PE = "PNE",
    PF = "PNF",
    M1 = "UNT",
    `00` = "UNT"
  )
  spec_type_map[isin_spec_type]
}
