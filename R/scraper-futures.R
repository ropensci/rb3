
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
#' @param refdate reference date used to obtain futures prices.
#'
#' If `refdate` is not provided the last available date is returned, otherwise
#' the provided date is used to fetch data.
#'
#' @return `data.frame` with futures prices.
#'
#' @examples
#' \dontrun{
#' df <- futures_get("2022-04-18")
#' }
#' @export
futures_get <- function(refdate) {
  tpl <- "AjustesDiarios"
  fname <- download_data(tpl, refdate = as.Date(refdate))
  if (!is.null(fname)) {
    df <- read_marketdata(fname, tpl)
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
    cli::cli_alert_danger("Failed CDIIDI download")
    return(NULL)
  }
}