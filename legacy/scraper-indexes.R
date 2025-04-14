#' Fetches indexes data from B3
#'
#' Downloads index data from B3 website
#' <https://www.b3.com.br/pt_br/market-data-e-indices/servicos-de-dados/market-data/historico/boletins-diarios/pesquisa-por-pregao/pesquisa-por-pregao/>.
#'
#' @param refdate Specific date ("YYYY-MM-DD") to `yc_get` single curve
#' @param first_date First date ("YYYY-MM-DD") to `yc_mget` multiple curves
#' @param last_date Last date ("YYYY-MM-DD") to `yc_mget` multiple curves
#' @param by Number of days in between fetched dates (default = 1) in `yc_mget`
#' @param cache_folder Location of cache folder (default = cachedir())
#' @param do_cache Whether to use cache or not (default = TRUE)
#'
#' @details
#' `indexreport_get` returns index data for the given date and
#' `indexreport_mget` returns index data for a given range of dates.
#'
#' @return
#' A dataframe with index data (OHLC, average and daily oscillation)
#'
#' @name indexreport_get
#'
#' @examples
#' \dontrun{
#' df_ir <- indexreport_mget(Sys.Date() - 5, Sys.Date())
#' head(df_ir)
#' }
#' @export
indexreport_mget <- function(first_date = Sys.Date() - 5,
                             last_date = Sys.Date(),
                             by = 1,
                             cache_folder = cachedir(),
                             do_cache = TRUE) {
  first_date <- as.Date(first_date)
  last_date <- as.Date(last_date)
  tpl <- template_retrieve("IndexReport")
  date_vec <- bizseq(first_date, last_date, tpl$calendar)
  date_vec <- date_vec[seq(1, length(date_vec), by = by)]

  bind_rows(
    log_map_process_along(date_vec, get_single_indexreport,
      "Fetching data points",
      date_vec = date_vec,
      cache_folder = cache_folder,
      do_cache = do_cache
    )
  )
}

#' @rdname indexreport_get
#' @examples
#' \dontrun{
#' df_ir <- indexreport_get(Sys.Date())
#' head(df_ir)
#' }
#' @export
indexreport_get <- function(refdate = Sys.Date(),
                            cache_folder = cachedir(),
                            do_cache = TRUE) {
  get_single_indexreport(1, as.Date(refdate), cache_folder, do_cache)
}

#' Fetches a single marketdata
#'
#' @param idx_date index of data (1.. n_dates)
#' @param date_vec Vector of dates
#' @param cache_folder Location of cache folder (default = cachedir())
#' @param do_cache Whether to use cache or not (default = TRUE)
#' @param ... orther arguments
#'
#' @return
#' A dataframe or `NULL`
#'
#' @noRd
get_single_marketdata <- function(template,
                                  idx_date,
                                  date_vec,
                                  cache_folder,
                                  do_cache, ...) {
  refdate <- date_vec[idx_date]
  fname <- download_marketdata(template, cache_folder, do_cache,
    refdate = refdate, ...
  )
  if (!is.null(fname)) {
    read_marketdata(fname, template, TRUE, do_cache)
  } else {
    cli_alert_danger("Error: no data found for date {refdate}")
    NULL
  }
}

get_single_indexreport <- function(idx_date,
                                   date_vec,
                                   cache_folder,
                                   do_cache) {
  df <- get_single_marketdata(
    "IndexReport", idx_date, date_vec, cache_folder, do_cache
  )
  if (!is.null(df)) {
    cols <- c(
      "refdate", "symbol", "open", "high", "low", "close", "average",
      "oscillation"
    )
    df[, cols]
  } else {
    NULL
  }
}
