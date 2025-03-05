#' Get month from maturity code
#'
#' Get the corresponding month for the string that represent maturities of
#' futures contracts.
#'
#' @param x a character with letters that represent the month of maturity of
#'        futures contracts.
#'
#' @return a vector of integers
#'
#' @examples
#' code2month(c("F", "G", "H", "J", "K", "M", "N", "Q", "U", "V", "X", "Z"))
#' code2month(c("JAN", "FEV", "MAR", "NOV", "DEZ"))
#' @export
code2month <- function(x) {
  ifelse(
    str_length(x) == 1,
    code2month_newcode(x),
    code2month_oldcode(x)
  )
}

code2month_newcode <- function(x) {
  m <- c(
    F = 1, G = 2, H = 3, J = 4, K = 5, M = 6,
    N = 7, Q = 8, U = 9, V = 10, X = 11, Z = 12
  )
  m[x] |> unname()
}

code2month_oldcode <- function(x) {
  m <- c(
    JAN = 1, FEV = 2, MAR = 3, ABR = 4, MAI = 5, JUN = 6,
    JUL = 7, AGO = 8, SET = 9, OUT = 10, NOV = 11, DEZ = 12
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
#' @param refdate reference date to be passed. It is necessary to convert old
#'        maturities like JAN0, that can be Jan/2000 or Jan/2010. If `refdate`
#'        is greater that 2001-01-01 JAN0 is converted to Jan/2010, otherwise,
#'        Jan/2000.
#'
#' @return a Date vector with maturity dates
#'
#' @examples
#' maturity2date(c("F22", "F23", "G23", "H23", "F45"), "first day")
#' maturity2date(c("F23", "K35"), "15th day")
#' maturity2date(c("AGO2", "SET2"), "first day")
#' @export
maturity2date <- function(x, expr = "first day", refdate = NULL) {
  res <- character(length(x))
  ix <- which(str_length(x) == 3)
  if (length(ix)) {
    res[ix] <- maturity2date_newcode(x[ix], expr)
  }
  ix <- which(str_length(x) == 4)
  if (length(ix)) {
    res[ix] <- maturity2date_oldcode(x[ix], expr, refdate)
  }
  as.Date(res)
}

maturity2date_newcode <- function(x, expr = "first day") {
  year <- as.integer(str_sub(x, 2)) + 2000
  month <- code2month_newcode(str_sub(x, 1, 1))
  month <- str_pad(month, 2, pad = "0")
  getdate(expr, paste0(year, "-", month), "Brazil/BMF") |> as.character()
}

maturity2date_oldcode <- function(x, expr = "first day", refdate = NULL) {
  base_year <- 2000
  if (!is.null(refdate) && refdate >= as.Date("2001-01-01")) {
    base_year <- 2010
  }
  year <- as.integer(str_sub(x, 4)) + base_year
  month <- code2month_oldcode(str_sub(x, 1, 3))
  month <- str_pad(month, 2, pad = "0")
  getdate(expr, paste0(year, "-", month), "Brazil/BMF") |> as.character()
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
NULL

#' @rdname futures_get
#' @examples
#' \dontrun{
#' df_fut <- futures_get(Sys.Date())
#' head(df_fut)
#' }
#' @export
futures_get <- function(refdate, commodity = NULL) {
  template <- template_retrieve("b3-futures-settlement-prices")
  .commodity <- commodity
  .refdate <- refdate
  query <- if (is.null(commodity)) {
    dataset_get(template$id) |>
      filter(.data$refdate %in% .refdate)
  } else {
    dataset_get(template$id) |>
      filter(.data$refdate %in% .refdate, .data$commodity == .commodity)
  }
  query |>
    collect() |>
    mutate(
      symbol = paste0(.data$commodity, .data$maturity_code),
    ) |>
    select(
      refdate,
      symbol,
      commodity,
      maturity_code,
      previous_price,
      price,
      price_change,
      settlement_value,
    )
}
