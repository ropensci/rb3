#' Get COTAHIST data from B3
#'
#' Download COTAHIST file and parses it returning structured data into R
#' objects.
#'
#' @param refdate the reference date used to download the file. This reference
#'        date will be formatted as year/month/day according to the given type.
#'        Accepts ISO formatted date strings.
#' @param type a string with `yearly` for all data of the given year, `monthly`
#'        for all data of the given month and `daily` for the given day.
#' @param cache_folder Location of cache folder (default = cachedir())
#' @param do_cache Whether to use cache or not (default = TRUE)
#'
#' All valuable information is in the `HistoricalPrices` element of the
#' returned list.
#' `Header` and `Trailer` have informations regarding file generation.
#' The `HistoricalPrices` element has a data.frame with data of many assets
#' traded in the stock exchange: stocks, bdrs, funds, ETFs, equity options,
#' forward contracts on equities and a few warrants due to some corporate
#' events.
#'
#' @return a list with 3 data.frames: `Header`, `HistoricalPrices`, `Trailer`.
#'
#' @examples
#' \dontrun{
#' # get all data to the year of 2001
#' df_2001 <- cotahist_get("2001-01-01", "yearly")
#' # get data of January of 2001
#' df_200101 <- cotahist_get("2001-01-01", "monthly")
#' # get data of 2001-01-02
#' df_daily <- cotahist_get("2001-01-02", "daily")
#' }
#'
#' @export
cotahist_get <- function(type = c("yearly", "monthly", "daily")) {
  type <- match.arg(type)
  template <- template_retrieve(str_glue("b3-cotahist-{type}"))
  template_dataset(template)
}

.select_equity <- function(x) {
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

#' Extract data from COTAHIST dataset
#'
#' Extracts specific data from COTAHIST dataset: stocks, funds, BDRs, ETFs,
#' UNITs, options on stocks, options on indexes, ...
#'
#' @param x COTAHIST dataset returned from `cotahist_get`.
#'
#' @return a data.frame with prices, volume, traded quantities informations
#'
#' @name cotahist-extracts
#' @examples
#' \dontrun{
#' df <- cotahist_equity_get(x)
#' }
#' @export
cotahist_equity_get <- function(x) {
  .filter_instrument_data(x, 10, c("UNT", "CDA", "ACN")) |>
    .select_equity() |>
    collect()
}

#' @rdname cotahist-extracts
#' @examples
#' \dontrun{
#' df <- cotahist_brds_get(x)
#' }
#' @export
cotahist_bdrs_get <- function(x) {
  .filter_instrument_data(x, 10, "BDR") |>
    .select_equity() |>
    collect()
}

#' @rdname cotahist-extracts
#' @examples
#' \dontrun{
#' df <- cotahist_units_get(x)
#' }
#' @export
cotahist_units_get <- function(x) {
  .filter_instrument_data(x, 10, c("UNT", "CDA")) |>
    .select_equity() |>
    collect()
}

#' @rdname cotahist-extracts
#' @examples
#' \dontrun{
#' df <- cotahist_etfs_get(x)
#' }
#' @export
cotahist_etfs_get <- function(x) {
  x |>
    filter(.data$bdi_code == 14, str_starts(.data$specification_code, "CI")) |>
    .filter_instrument_data(10, "CTF") |>
    .select_equity() |>
    collect()
}

#' @rdname cotahist-extracts
#' @examples
#' \dontrun{
#' df <- cotahist_fiis_get(x)
#' }
#' @export
cotahist_fiis_get <- function(x) {
  x |>
    filter(.data$bdi_code %in% c(5, 12)) |>
    .filter_instrument_data(10, "CTF") |>
    .select_equity() |>
    collect()
}

#' @rdname cotahist-extracts
#' @examples
#' \dontrun{
#' df <- cotahist_fidcs_get(x)
#' }
#' @export
cotahist_fidcs_get <- function(x) {
  x |>
    filter(
      .data$bdi_code == 14, str_starts(.data$specification_code, "FIDC")
    ) |>
    .filter_instrument_data(10, "CTF") |>
    .select_equity() |>
    collect()
}

#' @rdname cotahist-extracts
#' @examples
#' \dontrun{
#' df <- cotahist_fiagros_get(x)
#' }
#' @export
cotahist_fiagros_get <- function(x) {
  x |>
    filter(.data$bdi_code == 13) |>
    .filter_instrument_data(10, "CTF") |>
    .select_equity() |>
    collect()
}

#' @rdname cotahist-extracts
#' @examples
#' \dontrun{
#' df <- cotahist_indexes_get(x)
#' }
#' @export
cotahist_indexes_get <- function(x) {
  .filter_instrument_data(x, 10, "IND") |>
    .select_equity() |>
    collect()
}

#' @rdname cotahist-extracts
#' @examples
#' \dontrun{
#' df <- cotahist_equity_options_get(x)
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
#' df <- cotahist_index_options_get(x)
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
#' df <- cotahist_funds_options_get(x)
#' }
#' @export
cotahist_funds_options_get <- function(x) {
  x |>
    .cotahist_options_get("CTF") |>
    .select_options()
}

#' @rdname cotahist-extracts
#'
#' @param symbols list of symbols to extract market data from cotahist
#'
#' @examples
#' \dontrun{
#' df <- cotahist_get_symbols(x, c("BBDC4", "ITSA4", "JHSF3"))
#' }
#' @export
cotahist_get_symbols <- function(x, symbols) {
  x |>
    filter(.data$symbol %in% symbols) |>
    collect()
}

#' Extracts equity option superset of data
#'
#' Equity options superset is a dataframe that brings together all data
#' regarding equities, equity options and interest rates.
#' This data forms a complete set (superset) up and ready to run options
#' models, implied volatility calculations and volatility models.
#'
#' @param ch cotahist data structure
#' @param yc yield curve
#' @param symbol character with the name of the stock
#'
#' @return
#' A dataframe with data of equities, equity options, and interest rates.
#'
#' @examples
#' \dontrun{
#' refdate <- Sys.Date() - 1
#' ch <- cotahist_get(refdate, "daily")
#' yc <- yc_get(refdate)
#' ch_ss <- cotahist_equity_options_superset(ch, yc)
#' petr4_ch_ss <- cotahist_options_by_symbol_superset("PETR4", ch, yc)
#' }
#' @name cotahist-options-superset
#'
#'
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
      filter(.data$isin == eqs$isin[1]) |>
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
  inner_join(eqs_opts, eqs, by = c("refdate", "isin"), suffix = c("", "_underlying"), relationship = "many-to-one") |>
    mutate(
      fixing_maturity_date = following(.data$maturity_date, "Brazil/ANBIMA")
    ) |>
    inner_join(yc |> select("refdate", "forward_date", "r_252"),
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

#' @rdname cotahist-options-superset
#' @export
cotahist_equity_options_superset <- function(ch, yc) {
  .cotahist_options_superset(ch, yc, .security_category = c("UNT", "CDA", "ACN"))
}

#' @rdname cotahist-options-superset
#' @export
cotahist_funds_options_superset <- function(ch, yc) {
  .cotahist_options_superset(ch, yc, .security_category = "CTF")
}

#' @rdname cotahist-options-superset
#' @export
cotahist_index_options_superset <- function(ch, yc) {
  .cotahist_options_superset(ch, yc, .security_category = "IND")
}

#' @rdname cotahist-options-superset
#' @export
cotahist_options_by_symbol_superset <- function(symbol, ch, yc) {
  .cotahist_options_superset(ch, yc, .symbol = symbol)
}
