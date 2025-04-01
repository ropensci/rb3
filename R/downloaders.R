check_args <- function(..., required_args) {
  args <- list(...)
  for (arg_name in required_args) {
    if (!hasName(args, arg_name)) {
      cli_alert_danger("{arg_name} argument not provided")
      return(FALSE)
    }
  }
  TRUE
}

save_resource <- function(res, encoding, dest) {
  if (
    headers(res)[["content-type"]] == "application/octet-stream" ||
      headers(res)[["content-type"]] == "application/x-zip-compressed"
  ) {
    bin <- content(res, as = "raw")
    writeBin(bin, dest)
  } else {
    text <- content(res, as = "text", encoding = encoding)
    writeLines(text, dest, useBytes = TRUE)
  }
}

handle_response <- function(res, encoding, dest) {
  if (status_code(res) != 200 || !.safecontent(res)) {
    cli_alert_danger("Failed to download file: {.url {url}}, status code = {status_code(res)}")
    return(FALSE)
  }
  save_resource(res, encoding, dest)
  TRUE
}

.safecontent <- function(x) {
  cl <- headers(x)[["content-length"]]
  if (is.null(cl)) {
    TRUE
  } else {
    cl != 0
  }
}

url_encode <- function(url, ...) {
  args <- list(...)
  params <- toJSON(args, auto_unbox = TRUE)
  params_enc <- base64encode(charToRaw(params))
  url <- parse_url(url)
  url$path <- c(url$path, params_enc)
  url
}

download_marketdata_wrapper <- function(., dest, ...) {
  if (
    is.null(.$downloader$args) ||
      (!is.null(.$downloader$args) && check_args(..., required_args = names(.$downloader$args)))) {
    return(.$download_marketdata(., dest, ...))
  }
  FALSE
}

# just_download_data ----

just_download_data <- function(url, encoding, dest, verifyssl = TRUE) {
  verifyssl <- if (is.null(verifyssl)) TRUE else verifyssl
  encoding <- if (is.null(encoding)) "utf8" else encoding
  res <- GET(url, config(ssl_verifypeer = verifyssl))
  handle_response(res, encoding, dest)
}

simple_download <- function(., dest, ...) {
  just_download_data(.$downloader$url, .$downloader$encoding, dest, .$downloader$verifyssl)
}

datetime_download <- function(., dest, ...) {
  args <- list(...)
  url <- strftime(args$refdate, .$downloader$url)
  just_download_data(url, .$downloader$encoding, dest, .$downloader$verifyssl)
}

base64_datetime_download <- function(., dest, ...) {
  if (!datetime_download(., dest, ...)) {
    return(FALSE)
  }
  b64 <- scan(dest, "", quiet = TRUE)
  txt <- rawToChar(base64enc::base64decode(b64))
  writeBin(txt, dest)
  TRUE
}

sprintf_download <- function(., dest, ...) {
  args <- list(...)
  url <- do.call(sprintf, c(.$downloader$url, args))
  just_download_data(url, .$downloader$encoding, dest, .$downloader$verifyssl)
}

curve_download <- function(., dest, ...) {
  args <- list(...)
  url <- parse_url(.$downloader$url)
  url$query <- list(
    Data = format(as.Date(args$refdate), "%d/%m/%Y"),
    Data1 = format(as.Date(args$refdate), "%Y%m%d"),
    slcTaxa = args$curve_name
  )
  just_download_data(url, .$downloader$encoding, dest, .$downloader$verifyssl)
}

stock_indexes_composition_download <- function(., dest, ...) {
  url <- url_encode(.$downloader$url, pageNumber = 1, pageSize = 9999)
  just_download_data(url, .$downloader$encoding, dest, .$downloader$verifyssl)
}

stock_indexes_theo_portfolio_download <- function(., dest, ...) {
  args <- list(...)
  url <- url_encode(.$downloader$url,
    pageNumber = 1,
    pageSize = 9999,
    language = "en-us",
    index = args$index
  )
  just_download_data(url, .$downloader$encoding, dest, .$downloader$verifyssl)
}

stock_indexes_current_portfolio_download <- function(., dest, ...) {
  args <- list(...)
  # segment = 2 equals segment = 1 in terms of content, the difference is that segment = 1
  # doesn't have segment information
  url <- url_encode(.$downloader$url,
    pageNumber = 1,
    pageSize = 9999,
    language = "en-us",
    index = args$index,
    segment = 2
  )
  just_download_data(url, .$downloader$encoding, dest, .$downloader$verifyssl)
}

stock_indexes_statistics_download <- function(., dest, ...) {
  args <- list(...)
  url <- url_encode(.$downloader$url,
    language = "pt-br",
    index = args$index_name,
    year = args$year
  )
  just_download_data(url, .$downloader$encoding, dest, .$downloader$verifyssl)
}

company_listed_supplement_download <- function(., dest, ...) {
  args <- list(...)
  url <- url_encode(.$downloader$url,
    issuingCompany = args$company_name,
    language = "pt-br"
  )
  just_download_data(url, .$downloader$encoding, dest, .$downloader$verifyssl)
}

company_details_download <- function(., dest, ...) {
  args <- list(...)
  url_encoded_download(.$downloader$url, .$downloader$encoding, dest, .$downloader$verifyssl,
    codeCVM = args$code_cvm,
    language = "pt-br"
  )
}

company_cash_dividends_download <- function(., dest, ...) {
  args <- list(...)
  trading_name <- str_replace_all(args$trading_name, "[^A-Z0-9 ]+", "")
  url <- url_encode(.$downloader$url,
    tradingName = trading_name,
    language = "pt-br",
    pageNumber = 1,
    pageSize = 9999
  )
  just_download_data(url, .$downloader$encoding, dest, .$downloader$verifyssl)
}

# post_download_data ----

post_download_data <- function(url, encoding, dest, verifyssl, ...) {
  verifyssl <- if (is.null(verifyssl)) TRUE else verifyssl
  res <- POST(url, body = list(...), encode = "form", config(ssl_verifypeer = verifyssl))
  handle_response(res, encoding, dest)
}

settlement_prices_download <- function(., dest, ...) {
  args <- list(...)
  strdate <- format(as.Date(args$refdate), "%d/%m/%Y")
  post_download_data(.$downloader$url, .$downloader$encoding, dest, .$downloader$verifyssl,
    dData1 = strdate
  )
}
