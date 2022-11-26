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
cotahist_get <- function(refdate,
                         type = c("yearly", "monthly", "daily"),
                         cache_folder = cachedir(),
                         do_cache = TRUE) {
  type <- match.arg(type)
  tpl <- switch(type,
    yearly = "COTAHIST_YEARLY",
    monthly = "COTAHIST_MONTHLY",
    daily = "COTAHIST_DAILY"
  )
  refdate <- as.Date(refdate)
  fname <- download_marketdata(tpl, cache_folder, do_cache, refdate = refdate)
  if (!is.null(fname)) {
    read_marketdata(fname, tpl)
  } else {
    alert("danger", "Failed {tpl} download for reference date {refdate}",
      tpl = tpl, refdate = refdate
    )
    NULL
  }
}

format_equity <- function(df, with_isin = FALSE) {
  df[["refdate"]] <- df[["data_referencia"]]
  df[["symbol"]] <- df[["cod_negociacao"]]
  df[["open"]] <- df[["preco_abertura"]]
  df[["high"]] <- df[["preco_max"]]
  df[["low"]] <- df[["preco_min"]]
  df[["close"]] <- df[["preco_ult"]]
  df[["average"]] <- df[["preco_med"]]
  df[["best_bid"]] <- df[["preco_melhor_oferta_compra"]]
  df[["best_ask"]] <- df[["preco_melhor_oferta_venda"]]
  df[["volume"]] <- df[["volume_titulos_negociados"]]
  df[["traded_contracts"]] <- df[["qtd_titulos_negociados"]]
  df[["transactions_quantity"]] <- df[["qtd_negocios"]]
  df[["distribution_id"]] <- df[["num_dist"]]
  isin <- if (with_isin) "cod_isin" else NULL
  cols <- c(
    "refdate", "symbol", "open", "high", "low", "close", "average",
    "best_bid", "best_ask", "volume", "traded_contracts",
    "transactions_quantity", "distribution_id", isin
  )
  df[, cols]
}

format_options <- function(df, with_isin = FALSE) {
  df[["refdate"]] <- df[["data_referencia"]]
  df[["symbol"]] <- df[["cod_negociacao"]]
  df[["open"]] <- df[["preco_abertura"]]
  df[["high"]] <- df[["preco_max"]]
  df[["low"]] <- df[["preco_min"]]
  df[["close"]] <- df[["preco_ult"]]
  df[["average"]] <- df[["preco_med"]]
  df[["type"]] <- factor(df[["tipo_mercado"]], c(70, 80), c("Call", "Put"))
  df[["strike"]] <- df[["preco_exercicio"]]
  df[["maturity_date"]] <- df[["data_vencimento"]]
  df[["volume"]] <- df[["volume_titulos_negociados"]]
  df[["traded_contracts"]] <- df[["qtd_titulos_negociados"]]
  df[["transactions_quantity"]] <- df[["qtd_negocios"]]
  df[["distribution_id"]] <- df[["num_dist"]]
  isin <- if (with_isin) "cod_isin" else NULL
  cols <- c(
    "refdate", "symbol", "type", "strike", "maturity_date",
    "open", "high", "low", "close", "average", "volume", "traded_contracts",
    "transactions_quantity", "distribution_id", isin
  )
  df[, cols]
}

filter_equity_data <- function(x, instrument_market, security_category) {
  x[["HistoricalPrices"]] |>
    filter(
      .data$tipo_mercado %in% instrument_market,
      str_sub(.data$cod_isin, 7, 9) %in% security_category
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
  filter_equity_data(x, 10, c("UNT", "CDA", "ACN")) |> format_equity()
}

#' @rdname cotahist-extracts
#' @examples
#' \dontrun{
#' df <- cotahist_brds_get(x)
#' }
#' @export
cotahist_bdrs_get <- function(x) {
  filter_equity_data(x, 10, "BDR") |> format_equity()
}

#' @rdname cotahist-extracts
#' @examples
#' \dontrun{
#' df <- cotahist_units_get(x)
#' }
#' @export
cotahist_units_get <- function(x) {
  filter_equity_data(x, 10, c("UNT", "CDA")) |> format_equity()
}

#' @rdname cotahist-extracts
#' @examples
#' \dontrun{
#' df <- cotahist_etfs_get(x)
#' }
#' @export
cotahist_etfs_get <- function(x) {
  filter_equity_data(x, 10, "CTF") |>
    filter(.data$cod_bdi == 14, str_starts(.data$especificacao, "CI")) |>
    format_equity()
}

#' @rdname cotahist-extracts
#' @examples
#' \dontrun{
#' df <- cotahist_fiis_get(x)
#' }
#' @export
cotahist_fiis_get <- function(x) {
  filter_equity_data(x, 10, "CTF") |>
    filter(.data$cod_bdi %in% c(5, 12)) |>
    format_equity()
}

#' @rdname cotahist-extracts
#' @examples
#' \dontrun{
#' df <- cotahist_fidcs_get(x)
#' }
#' @export
cotahist_fidcs_get <- function(x) {
  filter_equity_data(x, 10, "CTF") |>
    filter(
      .data$cod_bdi == 14, str_starts(.data$especificacao, "FIDC")
    ) |>
    format_equity()
}

#' @rdname cotahist-extracts
#' @examples
#' \dontrun{
#' df <- cotahist_fiagros_get(x)
#' }
#' @export
cotahist_fiagros_get <- function(x) {
  filter_equity_data(x, 10, "CTF") |>
    filter(.data$cod_bdi == 13) |>
    format_equity()
}

#' @rdname cotahist-extracts
#' @examples
#' \dontrun{
#' df <- cotahist_indexes_get(x)
#' }
#' @export
cotahist_indexes_get <- function(x) {
  filter_equity_data(x, 10, "IND") |> format_equity()
}

#' @rdname cotahist-extracts
#' @examples
#' \dontrun{
#' df <- cotahist_equity_options_get(x)
#' }
#' @export
cotahist_equity_options_get <- function(x) {
  filter_equity_data(x, c(70, 80), c("ACN", "UNT", "CDA")) |> format_options()
}

#' @rdname cotahist-extracts
#' @examples
#' \dontrun{
#' df <- cotahist_index_options_get(x)
#' }
#' @export
cotahist_index_options_get <- function(x) {
  filter_equity_data(x, c(70, 80), "IND") |> format_options()
}

#' @rdname cotahist-extracts
#' @examples
#' \dontrun{
#' df <- cotahist_funds_options_get(x)
#' }
#' @export
cotahist_funds_options_get <- function(x) {
  filter_equity_data(x, c(70, 80), "CTF") |> format_options()
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
  x[["HistoricalPrices"]] |>
    filter(.data$cod_negociacao %in% symbols) |>
    format_equity()
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

#' @rdname cotahist-options-superset
#' @export
cotahist_equity_options_superset <- function(ch, yc) {
  eqs <- filter_equity_data(ch, 10, c("UNT", "CDA", "ACN")) |>
    format_equity(TRUE)
  eqs_opts <- filter_equity_data(ch, c(70, 80), c("UNT", "CDA", "ACN")) |>
    format_options(TRUE)
  inner_join(eqs_opts, eqs, by = "cod_isin", suffix = c("", ".underlying")) |>
    select(-c("refdate.underlying", "cod_isin")) |>
    mutate(
      fixing_maturity_date = following(.data$maturity_date, "Brazil/ANBIMA")
    ) |>
    inner_join(yc |> select("refdate", "forward_date", "r_252"),
      by = c("refdate", "fixing_maturity_date" = "forward_date")
    )
}

#' @rdname cotahist-options-superset
#' @export
cotahist_options_by_symbol_superset <- function(symbol, ch, yc) {
  eqs <- ch[["HistoricalPrices"]] |>
    filter(.data$cod_negociacao == symbol) |>
    format_equity(TRUE)
  eqs_opts <- ch[["HistoricalPrices"]] |>
    filter(.data$tipo_mercado %in% c(70, 80)) |>
    format_options(TRUE) |>
    filter(.data$cod_isin == eqs$cod_isin[1])
  inner_join(eqs_opts, eqs,
    by = c("refdate", "cod_isin"),
    suffix = c("", ".underlying")
  ) |>
    select(-c("cod_isin")) |>
    mutate(
      fixing_maturity_date = following(.data$maturity_date, "Brazil/ANBIMA")
    ) |>
    inner_join(yc |> select("refdate", "forward_date", "r_252"),
      by = c("refdate", "fixing_maturity_date" = "forward_date")
    )
}
