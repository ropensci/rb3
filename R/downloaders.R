simple_download <- function(., dest, ...) {
  enc <- if (is.null(.$downloader$encoding)) "utf8" else .$downloader$encoding
  just_download_data(.$downloader$url, enc, dest)
}

datetime_download <- function(., dest, ...) {
  params <- list(...)
  if (is.null(params$refdate)) {
    msg <- "refdate argument not provided - download can't be done"
    cli::cli_alert_danger(msg)
    return(FALSE)
  }
  url <- strftime(params$refdate, .$downloader$url)
  enc <- if (is.null(.$downloader$encoding)) "utf8" else .$downloader$encoding
  just_download_data(url, enc, dest)
}

settlement_prices_download <- function(., dest, ...) {
  params <- list(...)
  if (is.null(params$refdate)) {
    msg <- "refdate argument not provided - download can't be done"
    cli::cli_alert_danger(msg)
    return(FALSE)
  }
  strdate <- format(as.Date(params$refdate), "%d/%m/%Y")
  res <- httr::POST(.$downloader$url,
    body = list(dData1 = strdate),
    encode = "form"
  )
  if (httr::status_code(res) != 200) {
    return(FALSE)
  }
  enc <- if (is.null(.$downloader$encoding)) "utf8" else .$downloader$encoding
  save_resource(res, enc, dest)
  TRUE
}