#' Get COTAHIST data from B3
#'
#' Download COTAHIST file and parses it returning structured data into R
#' objects.
#'
#' @param year the year of the COTAHIST file.
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
cotahist_get <- function(year) {
  refdate <- as.Date(ISOdate(year, 1, 1))
  fname <- download_data("COTAHIST", refdate = refdate)
  if (!is.null(fname)) {
    d <- tempdir()
    l <- unzip(fname, exdir = d)
    read_marketdata(l, "COTAHIST")
  } else {
    cli::cli_alert_danger("Failed COTAHIST download for year {year}")
    NULL
  }
}