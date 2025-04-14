#' Access COTAHIST datasets
#'
#' The COTAHIST files are available with daily, monthly, and yearly data.
#' Therefore, the datasets correspond to these periods (`daily`, `monthly`, `yearly`).
#' See \code{\link{download_marketdata}} and \code{\link{read_marketdata}} for
#' instructions on how to download the files and create the datasets.
#'
#' The COTAHIST files contain historical quotation data (\emph{Cotações Históricas})
#' for stocks, stock options, stock forward contracts, ETFs, ETF options,
#' BDRs, UNITs, REITs (FIIs - \emph{Fundos Imobiliários}), FIAGROs (\emph{Fundos da Agroindústria}),
#' and FIDCs (\emph{Fundos de Direitos Creditórios}). These files from B3 hold
#' the oldest available information. The earliest annual file available dates back to 1986.
#' However, it is not recommended to use data prior to 1995 due to the monetary
#' stabilization process in 1994 (Plano Real).
#'
#' Note that the prices in the files are not adjusted for corporate actions.
#' As a result, only ETF series can be used without issues.
#'
#' @param type A string specifying the dataset to be used:
#'             `"daily"`, `"monthly"`, or `"yearly"`.
#'
#' @details Before using the dataset, it is necessary to download the files
#' using the \code{\link{download_marketdata}} function and create the datasets
#' with the \code{\link{read_marketdata}} function.
#'
#' @return
#' An `arrow_dplyr_query` or `ArrowObject`, representing a lazily evaluated query. The underlying data is not
#' collected until explicitly requested, allowing efficient manipulation of large datasets without immediate
#' memory usage.  
#' To trigger evaluation and return the results as an R `tibble`, use `collect()`.
#'
#' @examples
#' \dontrun{
#' # get all data to the year of 2001
#' meta <- download_marketdata("b3-cotahist-yearly", year = 2001)
#' read_marketdata(meta)
#' ds_yearly <- cotahist_get()
#'
#' # Earliest available annual file: 1986
#' # Recommended starting point: 1995 (after Plano Real)
#' }
#' \dontrun{
#' # To obtain data from January 2, 2014, the earliest available date:
#' meta <- download_marketdata("b3-cotahist-daily", refdate = as.Date("2014-01-02"))
#' read_marketdata(meta)
#' ds_daily <- cotahist_get("daily")
#' }
#' \dontrun{
#' # Once you download more dates, the data downloaded before remains stored and you can filter
#' # any date you want.
#' meta <- download_marketdata("b3-cotahist-daily", refdate = as.Date("2014-01-03"))
#' read_marketdata(meta)
#' df_daily <- cotahist_get("daily") |>
#'   filter(refdate == "2014-01-03") |>
#'   collect()
#' }
#'
#' @export
cotahist_get <- function(type = c("yearly", "monthly", "daily")) {
  type <- match.arg(type)
  template <- template_retrieve(str_glue("b3-cotahist-{type}"))
  template_dataset(template, layer = 2)
}

#' Filtering data from COTAHIST datasets
#'
#' A set of functions that implement filters to obtain organized and useful
#' data from the COTAHIST datasets.
#'
#' The functions bellow return data from plain instruments, stocks, funds and indexes.
#'
#' - `cotahist_filter_equity()` returns data for stocks and UNITs.
#' - `cotahist_filter_etf()` returns data for ETFs.
#' - `cotahist_filter_bdr()` returns data for BDRs.
#' - `cotahist_filter_unit()` returns data exclusively for UNITs.
#' - `cotahist_filter_index()` returns data for indices. The index data returned by `cotahist_filter_index()`
#'   corresponds to option expiration days, meaning there is only one index quote per month.
#' - `cotahist_filter_fii()`, `cotahist_filter_fidc()`, and `cotahist_filter_fiagro()` return data for funds.
#'
#' The functions bellow return data related to options, from equities, indexes and funds (ETFs).
#'
#' - `cotahist_filter_equity_options()` returns data for stock options.
#' - `cotahist_filter_index_options()` returns data for index options, currently only for IBOVESPA.
#' - `cotahist_filter_funds_options()` returns data for fund options, currently only for ETFs.
#'
#' @param x A cotahist dataset
#' 
#' @details
#' The dataset provided must have at least the columns `isin`, `instrument_market`, `bdi_code` and `specification_code`.
#' A combination of these columns is used to filter the desired data.
#'
#' @return A dataframe containing the requested market data.
#'
#' @name cotahist-extracts
NULL

.filter_option_data <- function(x, .security_category) {
  .filter_instrument_data(x, c(70, 80), .security_category)
}

.filter_instrument_data <- function(x, .instrument_market, .security_category) {
  x |>
    filter(
      .data$instrument_market %in% .instrument_market,
      str_sub(.data$isin, 7, 9) %in% .security_category,
    )
}

#' @rdname cotahist-extracts
#' @examples
#' \dontrun{
#' df <- cotahist_get() |> cotahist_filter_equity()
#' }
#' @export
cotahist_filter_equity <- function(x) {
  .filter_instrument_data(x, 10, c("UNT", "CDA", "ACN"))
}

#' @rdname cotahist-extracts
#' @examples
#' \dontrun{
#' df <- cotahist_get() |> cotahist_filter_etf()
#' }
#' @export
cotahist_filter_etf <- function(x) {
  x |>
    filter(.data$bdi_code == 14, str_starts(.data$specification_code, "CI")) |>
    .filter_instrument_data(10, "CTF")
}

#' @rdname cotahist-extracts
#' @examples
#' \dontrun{
#' df <- cotahist_get() |> cotahist_filter_bdr()
#' }
#' @export
cotahist_filter_bdr <- function(x) {
  .filter_instrument_data(x, 10, "BDR")
}

#' @rdname cotahist-extracts
#' @examples
#' \dontrun{
#' df <- cotahist_get() |> cotahist_filter_unit()
#' }
#' @export
cotahist_filter_unit <- function(x) {
  .filter_instrument_data(x, 10, c("UNT", "CDA"))
}

#' @rdname cotahist-extracts
#' @examples
#' \dontrun{
#' df <- cotahist_get() |> cotahist_filter_fii()
#' }
#' @export
cotahist_filter_fii <- function(x) {
  x |>
    filter(.data$bdi_code %in% c(5, 12)) |>
    .filter_instrument_data(10, "CTF")
}

#' @rdname cotahist-extracts
#' @examples
#' \dontrun{
#' df <- cotahist_get() |> cotahist_filter_fidc()
#' }
#' @export
cotahist_filter_fidc <- function(x) {
  x |>
    filter(
      .data$bdi_code == 14, str_starts(.data$specification_code, "FIDC")
    ) |>
    .filter_instrument_data(10, "CTF")
}

#' @rdname cotahist-extracts
#' @examples
#' \dontrun{
#' df <- cotahist_get() |> cotahist_filter_fiagro()
#' }
#' @export
cotahist_filter_fiagro <- function(x) {
  x |>
    filter(.data$bdi_code == 13) |>
    .filter_instrument_data(10, "CTF")
}

#' @rdname cotahist-extracts
#' @examples
#' \dontrun{
#' df <- cotahist_get() |> cotahist_filter_index()
#' }
#' @export
cotahist_filter_index <- function(x) {
  .filter_instrument_data(x, 10, "IND")
}

#' @rdname cotahist-extracts
#' @examples
#' \dontrun{
#' df <- cotahist_get() |> cotahist_filter_equity_options()
#' }
#' @export
cotahist_filter_equity_options <- function(x) {
  .filter_option_data(x, c("ACN", "UNT", "CDA"))
}

#' @rdname cotahist-extracts
#' @examples
#' \dontrun{
#' df <- cotahist_get() |> cotahist_filter_index_options()
#' }
#' @export
cotahist_filter_index_options <- function(x) {
  .filter_option_data(x, "IND")
}

#' @rdname cotahist-extracts
#' @examples
#' \dontrun{
#' df <- cotahist_get() |> cotahist_filter_fund_options()
#' }
#' @export
cotahist_filter_fund_options <- function(x) {
  .filter_option_data(x, "CTF")
}

#' Enhanced Dataset Creation
#'
#' To maximize the utility of B3's existing datasets, several functions integrate data from multiple
#' sources to generate specialized datasets for specific analytical needs. For instance,
#' `cotahist_equity_options_superset()` combines data from COTAHIST datasets
#' (`b3-cotahist-yearly`, `b3-cotahist-monthly`, and `b3-cotahist-daily`) and Reference Rates
#' (`b3-reference-rates`) to construct a dataset containing stock options data. This dataset
#' includes details such as the closing price of the underlying stock, its ticker symbol, and the
#' applicable interest rate at option expiration. This comprehensive data enables users to perform
#' option pricing and calculate implied volatility.
#'
#' @param symbols list of symbols to extract market data from the COTAHIST dataset.
#'
#' @details
#' The functions `cotahist_equity_options_superset()`, `cotahist_funds_options_superset()`,
#' `cotahist_index_options_superset()`, and `cotahist_options_by_symbol_superset()` use
#' information from the COTAHIST datasets (`b3-cotahist-yearly`, `b3-cotahist-monthly`,
#' and `b3-cotahist-daily`) and Reference Rates (`b3-reference-rates`) and return a dataframe
#' containing stock option data, including the closing price of the underlying stocks, the ticker
#' of the underlying asset, and the interest rate at the option's expiration. The returned dataframe
#' contains the following columns: "refdate", "symbol", "type", "symbol_underlying",
#' "strike_price", "maturity_date", "r_252", "close", "close_underlying", "volume",
#' "trade_quantity", and "traded_contracts".
#'
#' `cotahist_options_by_symbol_superset()` returns the same dataset but filtered for the specified asset ticker.
#'
#' Returned objects preserve lazy evaluation whenever possible and avoid being
#' collected until the last possible moment. Exceptions occur when operations
#' cannot be performed using Arrow's operators — in such cases, data will be
#' collected and `data.frame`s will be returned. Please refer to the documentation
#' to identify the situations where this behavior applies.
#' 
#' @return
#' The function `cotahist_options_by_symbol_superset()` return an object that inherits from a `arrow_dplyr_query`
#' since it tries to preserve the lazy evaluation and avoids collecting the data before its return.
#'
#' @examples
#' \dontrun{
#' date <- preceding(Sys.Date() - 1, "Brazil/ANBIMA")
#' bova_options <- cotahist_options_by_symbols_get("BOVA11") |> filter(refdate == date)
#' petr_options <- cotahist_options_by_symbols_get(c("PETR4", "PETR3")) |> filter(refdate == date)
#' }
#'
#' @name superdataset
NULL

#' @rdname superdataset
#' @export
cotahist_options_by_symbols_get <- function(symbols) {
  ch <- cotahist_get()
  yc <- yc_brl_get() |> select("refdate", "forward_date", "r_252")

  eqs <- ch |>
    filter(.data$symbol %in% symbols) |>
    select("refdate", "symbol", "close", "isin")

  eqs_opts <- ch |>
    filter(.data$instrument_market %in% c(70, 80)) |>
    select("refdate", "symbol", "strike_price", "maturity_date", "close", "volume", "isin", "instrument_market")

  eq <- dplyr::inner_join(eqs_opts, eqs,
    by = c("refdate", "isin"), suffix = c("", "_underlying"), relationship = "many-to-one"
  )
  ds <- dplyr::inner_join(eq, yc, by = c("refdate" = "refdate", "maturity_date" = "forward_date"))

  ds |>
    mutate(type = ifelse(.data$instrument_market == 80, "call", "put")) |>
    select(
      "refdate",
      "symbol_underlying",
      "close_underlying",
      "symbol",
      "type",
      "strike_price",
      "maturity_date",
      "close",
      "volume",
      "r_252",
    )
}

process_cotahist <- function(ds) {
  ds |> filter(.data$regtype == 1)
}
