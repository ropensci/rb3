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
#' @return An arrow Dataset class that can be used with dplyr to filter the data of interest.
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
#' df_daily <- cotahist_get("daily") |> filter(refdate == "2014-01-03") |> collect()
#' }
#'
#' @export
cotahist_get <- function(type = c("yearly", "monthly", "daily")) {
  type <- match.arg(type)
  template <- template_retrieve(str_glue("b3-cotahist-{type}"))
  template_dataset(template)
}

.select_instrument <- function(x) {
  x |> select(
    "refdate", "symbol", "open", "high", "low", "close", "volume",
    "traded_contracts", "trade_quantity", "distribution_id", "isin"
  )
}

.select_options <- function(x) {
  x |> select(
    "refdate", "symbol", "type", "strike_price", "maturity_date",
    "open", "high", "low", "close", "volume", "traded_contracts",
    "trade_quantity", "isin",
  )
}

.cotahist_options_get <- function(x, .security_category) {
  x |>
    .filter_instrument_data(c(70, 80), .security_category) |>
    collect() |>
    mutate(
      type = factor(.data$instrument_market, c(70, 80), c("call", "put"))
    )
}

.filter_instrument_data <- function(x, .instrument_market, .security_category) {
  x |>
    filter(
      .data$instrument_market %in% .instrument_market,
      str_sub(.data$isin, 7, 9) %in% .security_category,
    )
}

#' Extraction of data from COTAHIST datasets
#'
#' A set of functions that implement filters to obtain organized and useful 
#' data from the COTAHIST datasets.
#'
#' The functions `cotahist_equity_get()`, `cotahist_etfs_get()`, `cotahist_bdrs_get()`, 
#' `cotahist_units_get()`, `cotahist_fiis_get()`, `cotahist_fidcs_get()`, 
#' `cotahist_fiagros_get()`, and `cotahist_indexes_get()` return dataframes with 
#' the following columns: "refdate", "symbol", "open", "high", "low", 
#' "close", "volume", "traded_contracts", "trade_quantity", 
#' "distribution_id", "isin".
#'
#' - `cotahist_equity_get()` returns data for stocks and UNITs.  
#' - `cotahist_etfs_get()` returns data for ETFs.  
#' - `cotahist_bdrs_get()` returns data for BDRs.  
#' - `cotahist_units_get()` returns data exclusively for UNITs.  
#' - `cotahist_indexes_get()` returns data for indices. The index data returned by `cotahist_indexes_get()`
#'   corresponds to option expiration days, meaning there is only one index quote per month.  
#' - `cotahist_fiis_get()`, `cotahist_fidcs_get()`, and `cotahist_fiagros_get()` return data for funds.  
#'
#' The functions `cotahist_equity_options_get()`, `cotahist_index_options_get()`, 
#' and `cotahist_funds_options_get()` return dataframes with the following columns: 
#' "refdate", "symbol", "type", "strike_price", "maturity_date", 
#' "open", "high", "low", "close", "volume", "traded_contracts", 
#' "trade_quantity", "isin".
#'
#' - `cotahist_equity_options_get()` returns data for stock options.  
#' - `cotahist_index_options_get()` returns data for index options, currently only for IBOVESPA.  
#' - `cotahist_funds_options_get()` returns data for fund options, currently only for ETFs.  
#'
#' The function `cotahist_get_symbols()` returns data related to the provided symbols.
#'
#' @param x A cotahist dataset
#' 
#' @return A dataframe containing the requested market data.
#'
#' @name cotahist-extracts
#' @examples
#' \dontrun{
#' df <- cotahist_get() |> cotahist_equity_get()
#' }
#' @export
cotahist_equity_get <- function(x) {
  .filter_instrument_data(x, 10, c("UNT", "CDA", "ACN")) |>
    .select_instrument() |>
    collect()
}

#' @rdname cotahist-extracts
#' @examples
#' \dontrun{
#' df <- cotahist_get() |> cotahist_brds_get()
#' }
#' @export
cotahist_bdrs_get <- function(x) {
  .filter_instrument_data(x, 10, "BDR") |>
    .select_instrument() |>
    collect()
}

#' @rdname cotahist-extracts
#' @examples
#' \dontrun{
#' df <- cotahist_get() |> cotahist_units_get()
#' }
#' @export
cotahist_units_get <- function(x) {
  .filter_instrument_data(x, 10, c("UNT", "CDA")) |>
    .select_instrument() |>
    collect()
}

#' @rdname cotahist-extracts
#' @examples
#' \dontrun{
#' df <- cotahist_get() |> cotahist_etfs_get()
#' }
#' @export
cotahist_etfs_get <- function(x) {
  x |>
    filter(.data$bdi_code == 14, str_starts(.data$specification_code, "CI")) |>
    .filter_instrument_data(10, "CTF") |>
    .select_instrument() |>
    collect()
}

#' @rdname cotahist-extracts
#' @examples
#' \dontrun{
#' df <- cotahist_get() |> cotahist_fiis_get()
#' }
#' @export
cotahist_fiis_get <- function(x) {
  x |>
    filter(.data$bdi_code %in% c(5, 12)) |>
    .filter_instrument_data(10, "CTF") |>
    .select_instrument() |>
    collect()
}

#' @rdname cotahist-extracts
#' @examples
#' \dontrun{
#' df <- cotahist_get() |> cotahist_fidcs_get()
#' }
#' @export
cotahist_fidcs_get <- function(x) {
  x |>
    filter(
      .data$bdi_code == 14, str_starts(.data$specification_code, "FIDC")
    ) |>
    .filter_instrument_data(10, "CTF") |>
    .select_instrument() |>
    collect()
}

#' @rdname cotahist-extracts
#' @examples
#' \dontrun{
#' df <- cotahist_get() |> cotahist_fiagros_get()
#' }
#' @export
cotahist_fiagros_get <- function(x) {
  x |>
    filter(.data$bdi_code == 13) |>
    .filter_instrument_data(10, "CTF") |>
    .select_instrument() |>
    collect()
}

#' @rdname cotahist-extracts
#' @examples
#' \dontrun{
#' df <- cotahist_get() |> cotahist_indexes_get()
#' }
#' @export
cotahist_indexes_get <- function(x) {
  .filter_instrument_data(x, 10, "IND") |>
    .select_instrument() |>
    collect()
}

#' @rdname cotahist-extracts
#' @examples
#' \dontrun{
#' df <- cotahist_get() |> cotahist_equity_options_get()
#' }
#' @export
cotahist_equity_options_get <- function(x) {
  x |>
    .cotahist_options_get(c("ACN", "UNT", "CDA")) |>
    .select_options()
}

#' @rdname cotahist-extracts
#' @examples
#' \dontrun{
#' df <- cotahist_get() |> cotahist_index_options_get()
#' }
#' @export
cotahist_index_options_get <- function(x) {
  x |>
    .cotahist_options_get("IND") |>
    .select_options()
}

#' @rdname cotahist-extracts
#' @examples
#' \dontrun{
#' df <- cotahist_get() |> cotahist_funds_options_get()
#' }
#' @export
cotahist_funds_options_get <- function(x) {
  x |>
    .cotahist_options_get("CTF") |>
    .select_options()
}

#' @rdname cotahist-extracts
#'
#' @param symbols list of symbols to extract market data from the COTAHIST dataset.
#'
#' @examples
#' \dontrun{
#' df <- cotahist_get() |> cotahist_get_symbols(c("BBDC4", "ITSA4", "JHSF3"))
#' }
#' @export
cotahist_get_symbols <- function(x, symbols) {
  x |>
    filter(.data$symbol %in% symbols) |>
    collect()
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
#' @param ch A cotahist dataset
#' @param yc An yield curve dataset
#' @param fut futures dataset
#' @param symbol A string with the name of the stock
#'
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
#' @return A dataframe with the super-dataset.
#'
#' @examples
#' \dontrun{
#' date_ <- Sys.Date() - 1
#' ch <- cotahist_get() |> filter(refdate == date_)
#' yc <- yc_brl_get() |> filter(refdate == date_)
#' ch_ss <- cotahist_equity_options_superset(ch, yc)
#' petr4_ch_ss <- cotahist_options_by_symbol_superset("PETR4", ch, yc)
#' }
#' 
#' @name superdataset
NULL

.cotahist_options_superset <- function(ch, yc, .security_category = NULL, .symbol = NULL) {
  if (!is.null(.security_category)) {
    eqs <- .filter_instrument_data(ch, 10, .security_category) |> collect()
    eqs_opts <- .cotahist_options_get(ch, .security_category)
  } else if (!is.null(.symbol)) {
    eqs <- ch |>
      filter(.data$symbol == .symbol) |>
      collect()
    eqs_opts <- ch |>
      filter(.data$isin == eqs$isin[1], .data$instrument_market %in% c(70, 80)) |>
      collect() |>
      mutate(
        type = factor(.data$instrument_market, c(70, 80), c("call", "put"))
      )
  } else {
    stop("You must provide either a security category or a symbol.")
  }
  yc_df <- yc |>
    select("refdate", "forward_date", "r_252") |>
    collect()
  eq <- inner_join(eqs_opts, eqs, by = c("refdate", "isin"), suffix = c("", "_underlying"), relationship = "many-to-one") |>
    mutate(
      fixing_maturity_date = following(.data$maturity_date, "Brazil/ANBIMA")
    )
  inner_join(eq, yc_df |> select("refdate", "forward_date", "r_252"),
      by = c("refdate", "fixing_maturity_date" = "forward_date")
    ) |>
    select(
      "refdate",
      "symbol",
      "type",
      "symbol_underlying",
      "strike_price",
      "maturity_date",
      "r_252",
      "close",
      "close_underlying",
      "volume",
      "trade_quantity",
      "traded_contracts",
    )
}

#' @rdname superdataset
#' @export
cotahist_equity_options_superset <- function(ch, yc) {
  .cotahist_options_superset(ch, yc, .security_category = c("UNT", "CDA", "ACN"))
}

#' @rdname superdataset
#' @export
cotahist_funds_options_superset <- function(ch, yc) {
  .cotahist_options_superset(ch, yc, .security_category = "CTF")
}

#' @rdname superdataset
#' @export
cotahist_index_options_superset <- function(ch, yc) {
  .cotahist_options_superset(ch, yc, .security_category = "IND")
}

#' @rdname superdataset
#' @export
cotahist_options_by_symbol_superset <- function(symbol, ch, yc) {
  .cotahist_options_superset(ch, yc, .symbol = symbol)
}
