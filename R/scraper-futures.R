
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

code2month <- function(x) {
  m <- c(
    F = 1, G = 2, H = 3, J = 4, K = 5, M = 6,
    N = 7, Q = 8, U = 9, V = 10, X = 11, Z = 12
  )
  m[x]
}

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
#' @param first_date First date ("YYYY-MM-DD")
#' @param last_date Last date ("YYYY-MM-DD")
#' @param by Number of days in between fetched dates (default = 1)
#' @param cache_folder Location of cache folder (default = cachedir())
#' @param do_cache Whether to use cache or not (default = TRUE)
#'
#' @return `data.frame` with futures prices.
#'
#' @examples
#' \dontrun{
#' df <- futures_get("2022-04-18", "2022-04-22")
#' }
#' @export
futures_get <- function(first_date = Sys.Date() - 5,
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
      format = "{pb_spin} Fetching data points {cli::pb_current}/{cli::pb_total} | {pb_bar} {pb_percent} | {pb_eta_str}"
    ),
    single_futures_get,
    date_vec,
    cache_folder = cache_folder,
    do_cache = do_cache
    )
  )
  return(df)
}

single_futures_get <- function(idx_date,
                               date_vec,
                               cache_folder = cachedir(),
                               do_cache = TRUE) {
  tpl <- "AjustesDiarios"
  refdate <- date_vec[idx_date]
  fname <- download_data(tpl, cache_folder, do_cache, refdate = refdate)
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