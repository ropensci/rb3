#' Get composition of B3 indexes
#'
#' Gets the composition of listed B3 indexes.
#'
#' @param index_name a string with the index name
#' @param cache_folder Location of cache folder (default = cachedir())
#' @param do_cache Whether to use cache or not (default = TRUE)
#'
#' @return a character vector with symbols that belong to the given index name
#'
#' @examples
#' \dontrun{
#' index_comp_get("IBOV")
#' }
#' @export
index_comp_get <- function(index_name,
                           cache_folder = cachedir(),
                           do_cache = TRUE) {
  f <- download_marketdata("GetTheoricalPortfolio", cache_folder, do_cache,
    index_name = index_name
  )
  df <- read_marketdata(
    f, "GetTheoricalPortfolio", TRUE,
    do_cache
  )
  df$Results$code
}

#' Get the assets weights of B3 indexes
#'
#' Gets the assets weights of B3 indexes.
#'
#' @param index_name a string with the index name
#' @param cache_folder Location of cache folder (default = cachedir())
#' @param do_cache Whether to use cache or not (default = TRUE)
#'
#' @return
#' data.frame with symbols that belong to the given index name with its weights
#' and theorical positions.
#'
#' @examples
#' \dontrun{
#' index_weights_get("IBOV")
#' }
#' @export
index_weights_get <- function(index_name,
                              cache_folder = cachedir(),
                              do_cache = TRUE) {
  f <- download_marketdata("GetTheoricalPortfolio", cache_folder, do_cache,
    index_name = index_name
  )
  df <- read_marketdata(
    f, "GetTheoricalPortfolio", TRUE,
    do_cache
  )
  ds <- df$Results[, c("code", "part", "theoricalQty")]
  colnames(ds) <- c("symbol", "weight", "position")
  ds$weight <- ds$weight / 100
  ds
}

#' Get the date of indexes composition last update
#'
#' Gets the date where the indexes have been updated lastly.
#'
#' @param cache_folder Location of cache folder (default = cachedir())
#' @param do_cache Whether to use cache or not (default = TRUE)
#'
#' @return the Date when the indexes have been updated
#'
#' @examples
#' \dontrun{
#' indexes_last_update()
#' }
#' @export
indexes_last_update <- function(cache_folder = cachedir(),
                                do_cache = TRUE) {
  f <- download_marketdata("GetStockIndex",
    cache_folder = cache_folder, do_cache = do_cache
  )
  df <- read_marketdata(f, "GetStockIndex", do_cache = do_cache)
  df$Header$update
}

#' Get B3 indexes available
#'
#' Gets B3 indexes available.
#'
#' @param cache_folder Location of cache folder (default = cachedir())
#' @param do_cache Whether to use cache or not (default = TRUE)
#'
#' @return a character vector with symbols of indexes available
#'
#' @examples
#' \dontrun{
#' indexes_get()
#' }
#' @export
indexes_get <- function(cache_folder = cachedir(),
                        do_cache = TRUE) {
  f <- download_marketdata("GetStockIndex",
    cache_folder = cache_folder, do_cache = do_cache
  )
  df <- read_marketdata(f, "GetStockIndex", do_cache = do_cache)
  str_split(df$Results$indexes, ",") |>
    unlist() |>
    unique() |>
    sort()
}

#' Get B3 indexes available
#'
#' Gets B3 indexes available.
#'
#' @param index_name a string with the index name
#' @param cache_folder Location of cache folder (default = cachedir())
#' @param do_cache Whether to use cache or not (default = TRUE)
#'
#' @return
#' A dataframe with the index stocks, their weights, segments and positions.
#'
#' @examples
#' \dontrun{
#' index_by_segment_get("IBOV")
#' }
#' @export
index_by_segment_get <- function(index_name,
                                 cache_folder = cachedir(),
                                 do_cache = TRUE) {
  f <- download_marketdata("GetPortfolioDay",
    cache_folder = cache_folder,
    do_cache = do_cache,
    index_name = index_name
  )
  pp <- read_marketdata(f, "GetPortfolioDay", do_cache = do_cache)
  df <- pp$Results[, c("code", "segment", "part", "part_acum", "theoricalQty")]
  colnames(df) <- c("symbol", "segment", "weight", "segment_weight", "position")
  df$weight <- df$weight / 100
  df$segment_weight <- df$segment_weight / 100
  df$refdate <- pp$Header$date

  df
}

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
#' A dataframe with index data (OHLC, average and daily oscilation)
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
  tpl <- .retrieve_template(NULL, "IndexReport")
  date_vec <- bizseq(first_date, last_date, tpl$calendar)
  date_vec <- date_vec[seq(1, length(date_vec), by = by)]

  bind_rows(
    map(cli::cli_progress_along(
      date_vec,
      format = paste0(
        "{cli::pb_spin} Fetching data points",
        "{cli::pb_current}/{cli::pb_total}",
        " | {cli::pb_bar} {cli::pb_percent} | {cli::pb_eta_str}"
      )
    ),
    get_single_indexreport,
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