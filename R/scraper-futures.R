
flatten_names <- function(nx) {
  for (ix in seq_along(nx)) {
    if (nx[ix] != "") {
      last_name <- nx[ix]
    }
    nx[ix] <- last_name
  }
  x <- nx |> stringr::str_match("^...")
  as.vector(x)
}

#' Get month from maturity code
#'
#' Get the corresponding month for the letters that represent maturities of
#' futures contracts.
#'
#' @param x a character with letters that represent the month of maturity of
#'        futures contracts.
#'
#' @return a vector of integers
#'
#' @examples
#' code2month(c("F", "G", "H", "J", "K", "M", "N", "Q", "U", "V", "X", "Z"))
#' @export
code2month <- function(x) {
  m <- c(
    F = 1, G = 2, H = 3, J = 4, K = 5, M = 6,
    N = 7, Q = 8, U = 9, V = 10, X = 11, Z = 12
  )
  m[x] |> unname()
}

#' Get maturity date from maturity code
#'
#' Get the corresponding maturity date for the three characters string
#' that represent maturity of futures contracts.
#'
#' @param x a character vector with three letters string that represent
#'        maturity of futures contracts.
#' @param expr a string which indicates the day to use in maturity date.
#'        See `bizdays::getdate` for more details on this argument.
#'
#' @return a Date vector with maturity dates
#'
#' @examples
#' maturity2date(c("F22", "F23", "G23", "H23", "F45"), "first day")
#' maturity2date(c("F23", "K35"), "15th day")
#' @export
maturity2date <- function(x, expr = "first day") {
  year <- as.integer(stringr::str_sub(x, 2)) + 2000
  month <- code2month(stringr::str_sub(x, 1, 1))
  month <- stringr::str_pad(month, 2, pad = "0")
  bizdays::getdate(expr, paste0(year, "-", month), "Brazil/ANBIMA")
}

#' Get futures prices from trading session settlements page
#'
#' Scrape page <https://www.b3.com.br/en_us/market-data-and-indices/data-services/market-data/historical-data/derivatives/trading-session-settlements/>
#' to get futures prices.
#'
#' @param refdate Specific date ("YYYY-MM-DD") to `yc_get` single curve
#' @param first_date First date ("YYYY-MM-DD") to `yc_mget` multiple curves
#' @param last_date Last date ("YYYY-MM-DD") to `yc_mget` multiple curves
#' @param by Number of days in between fetched dates (default = 1) in `yc_mget`
#' @param cache_folder Location of cache folder (default = cachedir())
#' @param do_cache Whether to use cache or not (default = TRUE)
#'
#' `futures_get` returns the future contracts for the given date and
#' `futures_mget` returns future contracts for multiple dates in a given range.
#'
#' @return `data.frame` with futures prices.
#'
#' @name futures_get
#'
#' @examples
#' \dontrun{
#' df <- futures_get("2022-04-18", "2022-04-22")
#' }
#' @export
futures_mget <- function(first_date = Sys.Date() - 5,
                         last_date = Sys.Date(),
                         by = 1,
                         cache_folder = cachedir(),
                         do_cache = TRUE) {
  first_date <- as.Date(first_date)
  last_date <- as.Date(last_date)
  date_vec <- bizdays::bizseq(first_date, last_date, "Brazil/ANBIMA")
  date_vec <- date_vec[seq(1, length(date_vec), by = by)]
  df <- dplyr::bind_rows(
    purrr::map(cli::cli_progress_along(
      date_vec,
      format = paste0(
        "{pb_spin} Fetching data points",
        "{cli::pb_current}/{cli::pb_total}",
        " | {pb_bar} {pb_percent} | {pb_eta_str}"
      )
    ),
    single_futures_get,
    date_vec,
    cache_folder = cache_folder,
    do_cache = do_cache
    )
  )
  return(df)
}

#' @rdname futures_get
#' @examples
#' \dontrun{
#' df_fut <- futures_get(Sys.Date())
#' head(df_fut)
#' }
#' @export
futures_get <- function(refdate = Sys.Date(),
                        cache_folder = cachedir(),
                        do_cache = TRUE) {
  single_futures_get(1, as.Date(refdate), cache_folder, do_cache)
}

single_futures_get <- function(idx_date,
                               date_vec,
                               cache_folder = cachedir(),
                               do_cache = TRUE) {
  tpl <- "AjustesDiarios"
  refdate <- date_vec[idx_date]
  fname <- download_marketdata(tpl, cache_folder, do_cache, refdate = refdate)
  if (!is.null(fname)) {
    df <- read_marketdata(fname, tpl, TRUE, cache_folder, do_cache)
    if (!is.null(df)) {
      dplyr::tibble(
        refdate = as.Date(refdate),
        commodity = flatten_names(df$mercadoria),
        maturity_code = df$vencimento,
        symbol = paste0(.data$commodity, .data$maturity_code),
        price_previous = df$pu_anterior,
        price = df$pu_atual,
        change = df$variacao,
        settlement_value = df$ajuste
      )
    } else {
      NULL
    }
  } else {
    cli::cli_alert_danger("Failed download")
    return(NULL)
  }
}