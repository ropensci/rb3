simple_download <- function(., dest, ...) {
  enc <- if (is.null(.$downloader$encoding)) "utf8" else .$downloader$encoding
  just_download_data(.$downloader$url, enc, dest, .$verifyssl)
}

datetime_download <- function(., dest, ...) {
  params <- list(...)
  if (is.null(params$refdate)) {
    msg <- "refdate argument not provided - download can't be done"
    alert("danger", msg)
    return(FALSE)
  }
  url <- strftime(params$refdate, .$downloader$url)
  enc <- if (is.null(.$downloader$encoding)) "utf8" else .$downloader$encoding
  just_download_data(url, enc, dest, .$verifyssl)
}

settlement_prices_download <- function(., dest, ...) {
  params <- list(...)
  if (is.null(params$refdate)) {
    msg <- "refdate argument not provided - download can't be done"
    alert("danger", msg)
    return(FALSE)
  }
  strdate <- format(as.Date(params$refdate), "%d/%m/%Y")
  verifyssl <- if (!is.null(.$verifyssl)) .$verifyssl else TRUE
  if (verifyssl) {
    res <- POST(.$downloader$url,
      body = list(dData1 = strdate),
      encode = "form"
    )
  } else {
    res <- POST(.$downloader$url,
      body = list(dData1 = strdate),
      encode = "form", config(ssl_verifypeer = FALSE)
    )
  }
  if (status_code(res) != 200) {
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
    alert("danger", msg)
    return(FALSE)
  }
  curve_name <- if (is.null(params$curve_name)) {
    "PRE"
  } else {
    params$curve_name
  }
  url <- parse_url(.$downloader$url)
  url$query <- list(
    Data = format(as.Date(params$refdate), "%d/%m/%Y"),
    Data1 = format(as.Date(params$refdate), "%Y%m%d"),
    slcTaxa = curve_name
  )
  verifyssl <- if (!is.null(.$verifyssl)) .$verifyssl else TRUE
  if (verifyssl) {
    res <- GET(url)
  } else {
    res <- GET(url, config(ssl_verifypeer = FALSE))
  }
  if (status_code(res) != 200) {
    return(FALSE)
  }
  enc <- if (is.null(.$downloader$encoding)) "utf8" else .$downloader$encoding
  save_resource(res, enc, dest)
  TRUE
}

stock_indexes_composition_download <- function(., dest, ...) {
  url_encoded_download(., dest,
    pageNumber = 1,
    pageSize = 9999
  )
}

stock_indexes_theo_portfolio_download <- function(., dest, ...) {
  if (!check_parameters(..., arg_name = "index_name")) {
    return(FALSE)
  }
  args <- list(...)
  url_encoded_download(., dest,
    pageNumber = 1,
    pageSize = 9999,
    language = "pt-br",
    index = args$index_name
  )
}

stock_indexes_current_portfolio_download <- function(., dest, ...) {
  if (!check_parameters(..., arg_name = "index_name")) {
    return(FALSE)
  }
  args <- list(...)
  segment <- 2
  if (hasName(args, "segment")) {
    segment <- args$segment
  }
  url_encoded_download(., dest,
    pageNumber = 1,
    pageSize = 9999,
    language = "pt-br",
    index = args$index_name,
    segment = segment
  )
}

stock_indexes_statistics_download <- function(., dest, ...) {
  if (!check_parameters(..., arg_name = "index_name")) {
    return(FALSE)
  }
  if (!check_parameters(..., arg_name = "year")) {
    return(FALSE)
  }
  args <- list(...)
  url_encoded_download(., dest,
    language = "pt-br",
    index = args$index_name,
    year = args$year
  )
}

company_listed_supplement_download <- function(., dest, ...) {
  if (!check_parameters(..., arg_name = "company_name")) {
    return(FALSE)
  }
  args <- list(...)
  url_encoded_download(., dest,
    issuingCompany = args$company_name, language = "pt-br"
  )
}

company_details_download <- function(., dest, ...) {
  if (!check_parameters(..., arg_name = "code_cvm")) {
    return(FALSE)
  }
  args <- list(...)
  url_encoded_download(., dest,
    codeCVM = args$code_cvm, language = "pt-br"
  )
}

company_cash_dividends_download <- function(., dest, ...) {
  if (!check_parameters(..., arg_name = "trading_name")) {
    return(FALSE)
  }
  args <- list(...)
  trading_name <- str_replace_all(args$trading_name, "[^A-Z0-9 ]+", "")
  url_encoded_download(., dest,
    tradingName = trading_name, language = "pt-br",
    pageNumber = 1, pageSize = 9999
  )
}

check_parameters <- function(..., arg_name) {
  args <- list(...)
  if (!hasName(args, arg_name)) {
    alert("danger", "{arg_name} argument not provided", arg_name = arg_name)
    FALSE
  } else {
    TRUE
  }
}

url_encoded_download <- function(., dest, ...) {
  args <- list(...)
  params <- toJSON(args, auto_unbox = TRUE)
  params_enc <- base64encode(charToRaw(params))
  url <- parse_url(.$downloader$url)
  url$path <- c(url$path, params_enc)
  verifyssl <- if (!is.null(.$verifyssl)) .$verifyssl else TRUE
  if (verifyssl) {
    res <- GET(url)
  } else {
    res <- GET(url, config(ssl_verifypeer = 0L))
  }
  if (status_code(res) != 200) {
    return(FALSE)
  }
  enc <- if (is.null(.$downloader$encoding)) "utf8" else .$downloader$encoding
  save_resource(res, enc, dest)
  TRUE
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
