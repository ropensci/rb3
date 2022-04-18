

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