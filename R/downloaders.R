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

curve_download <- function(., dest, ...) {
  params <- list(...)
  if (is.null(params$refdate)) {
    msg <- "refdate argument not provided - download can't be done"
    cli::cli_alert_danger(msg)
    return(FALSE)
  }
  curve_name <- if (is.null(params$curve_name)) {
    "PRE"
  } else {
    params$curve_name
  }
  url <- httr::parse_url(.$downloader$url)
  url$query <- list(
    Data = format(as.Date(params$refdate), "%d/%m/%Y"),
    Data1 = format(as.Date(params$refdate), "%Y%m%d"),
    slcTaxa = curve_name
  )
  res <- httr::GET(url)
  if (httr::status_code(res) != 200) {
    return(FALSE)
  }
  enc <- if (is.null(.$downloader$encoding)) "utf8" else .$downloader$encoding
  save_resource(res, enc, dest)
  TRUE
}

stock_indexes_composition_download <- function(., dest, ...) {
  params <- jsonlite::toJSON(list(
    pageNumber = 1,
    pageSize = 9999
  ), auto_unbox = TRUE)
  params_enc <- base64enc::base64encode(charToRaw(params))
  url <- httr::parse_url(.$downloader$url)
  url$path <- c(url$path, params_enc)
  res <- httr::GET(url)
  res <- httr::GET(url)
  if (httr::status_code(res) != 200) {
    return(FALSE)
  }
  enc <- if (is.null(.$downloader$encoding)) "utf8" else .$downloader$encoding
  save_resource(res, enc, dest)
  TRUE
}