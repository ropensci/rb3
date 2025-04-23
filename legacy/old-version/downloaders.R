base64_datetime_download <- function(., dest, ...) {
  if (!datetime_download(., dest, ...)) {
    return(FALSE)
  }
  b64 <- scan(dest, "", quiet = TRUE)
  txt <- rawToChar(base64enc::base64decode(b64))
  writeBin(txt, dest)
  TRUE
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

