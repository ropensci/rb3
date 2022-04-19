#' Get COTAHIST data from B3
#'
#' Download COTAHIST file and parses it returning structured data into R
#' objects.
#'
#' @param refdate the reference date used to download the file. This reference
#'        date will be formated as year/month/day according to the given type.
#'        Accepts ISO formated date strings.
#'
#' All valueable information is in the `HistoricalPrices` element of the
#' returned list.
#' `Header` and `Trailer` have informations regarding file generation.
#'
#' @return a list with 3 data.frames: `Header`, `HistoricalPrices`, `Trailer`.
#'
#' @examples
#' \dontrun{
#' df <- cotahist_get(2001)
#' }
#'
#' @export
cotahist_get <- function(refdate, type = c("yearly", "monthly", "daily")) {
  type <- match.arg(type)
  tpl <- switch(type,
    yearly = "COTAHIST_YEARLY",
    monthly = "COTAHIST_MONTHLY",
    daily = "COTAHIST_DAILY"
  )
  refdate <- as.Date(refdate)
  fname <- download_data(tpl, refdate = refdate)
  if (!is.null(fname)) {
    d <- tempdir()
    l <- unzip(fname, exdir = d)
    read_marketdata(l, tpl)
  } else {
    cli::cli_alert_danger("Failed {tpl} download for reference date {refdate}")
    NULL
  }
}