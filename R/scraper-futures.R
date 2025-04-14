#' Convert Maturity Code to Corresponding Month
#'
#' This function takes a character string representing the maturity code of a 
#' futures contract and returns the corresponding month as an integer. It supports 
#' both the new and old maturity code formats used in futures contracts.
#'
#' @param x A character vector with the maturity code(s) of futures contracts. 
#'          The codes can be either a single letter (e.g., "F", "G", "H", ...) 
#'          representing the new code format or a three-letter abbreviation (e.g., 
#'          "JAN", "FEV", "MAR", ...) representing the old code format.
#'
#' @details
#' The function distinguishes between two maturity code formats: 
#' - The **new code format** uses a single letter (e.g., "F" = January, 
#'   "G" = February, etc.).
#' - The **old code format** uses a three-letter abbreviation (e.g., 
#'   "JAN" = January, "FEV" = February, etc.).
#' 
#' @return A vector of integers corresponding to the months of the year, where 
#'         1 = January, 2 = February, ..., 12 = December.
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

#' Convert Maturity Code to Date
#'
#' This function converts a vector of maturity codes into actual dates.
#'
#' @param x A character vector containing maturity codes.
#' @param expr A string specifying the expression of the date, default is "first day".
#' @param refdate An optional reference date used to determine the base year for old codes.
#'
#' @return A vector of dates corresponding to the input maturity codes.

#' Convert Maturity Code to Date
#'
#' This function converts a vector of maturity codes into actual dates.
#' Get the corresponding maturity date for the three characters string
#' that represent maturity of futures contracts.
#'
#' @param x a character vector with three letters string that represent
#'        maturity of futures contracts.
#' @param expr a string which indicates the day to use in maturity date, default is "first day".
#'        See `bizdays::getdate` for more details on this argument
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

#' @title Retrieves B3 Futures Settlement Prices
#' 
#' @description
#' This function fetches settlement price data for B3 futures contracts.
#' This function retrieves futures settlement prices from the B3 dataset,
#' adding a `symbol` column that combines `commodity` and `maturity_code`.
#'
#' @return
#' An `arrow_dplyr_query` or `ArrowObject`, representing a lazily evaluated query. The underlying data is not
#' collected until explicitly requested, allowing efficient manipulation of large datasets without immediate
#' memory usage.  
#' To trigger evaluation and return the results as an R `tibble`, use `collect()`.
#' 
#' The returned data includes the following columns:
#' \itemize{
#'   \item \code{refdate}: Reference date for the prices.
#'   \item \code{symbol}: Futures contract symbol, created by concatenating the commodity code and the maturity code.
#'   \item \code{commodity}: Commodity code of the futures contract.
#'   \item \code{maturity_code}: Maturity code of the futures contract.
#'   \item \code{previous_price}: Closing price from the previous trading day.
#'   \item \code{price}: Current price of the futures contract.
#'   \item \code{price_change}: Price variation compared to the previous day.
#'   \item \code{settlement_value}: Settlement value of the futures contract.
#' }
#'
#' @source [B3 Market Data](https://www.b3.com.br/en_us/market-data-and-indices/data-services/market-data/historical-data/derivatives/trading-session-settlements/)
#' 
#' @examples
#' \dontrun{
#' df_fut <- futures_get() |> filter(refdate == Sys.Date()) |> collect()
#' head(df_fut)
#' }
#' @export
futures_get <- function() {
  template <- template_retrieve("b3-futures-settlement-prices")
  template_dataset(template, layer = 2)
}

process_futures <- function(ds) {
  ds |>
    mutate(
      symbol = paste0(.data$commodity, .data$maturity_code),
    ) |>
    select(
      "refdate",
      "symbol",
      "commodity",
      "maturity_code",
      "previous_price",
      "price",
      "price_change",
      "settlement_value",
    )
}
