
download_data <- function(template, dest = NULL, overwrite = TRUE, ...) {
  template <- .retrieve_template(NULL, template)
  downloader <- downloaders_factory(template$downloader)
  if (is.null(dest)) {
    dest <- file.path(tempdir(), str_glue("{template$id}.{downloader$format}"))
  } else if (dir.exists(dest)) {
    dest <- file.path(dest, str_glue("{template$id}.{downloader$format}"))
  }

  if (file.exists(dest) && !overwrite) {
    message(str_glue("Skipping download - file {dest} exists"))
    return(NULL)
  }
  if (download_file(downloader, dest, ...)) {
    dest
  } else {
    NULL
  }
}

simple_downloader <- function(x) {
  this <- list(
    url = x$url,
    format = x$format,
    encoding = if (is.null(x$encoding)) "utf8" else x$encoding
  )

  structure(this, class = c("simple", "downloader"))
}

datetime_downloader <- function(x) {
  this <- list(
    url = x$url,
    format = x$format,
    encoding = if (is.null(x$encoding)) "utf8" else x$encoding
  )

  structure(this, class = c("datetime", "downloader"))
}

downloaders_factory <- function(x) {
  if (x$type == "simple") {
    simple_downloader(x)
  } else if (x$type == "datetime") {
    datetime_downloader(x)
  }
}

download_file <- function(x, dest, ...) UseMethod("download_file")

download_file.simple <- function(x, dest, ...) {
  just_download_data(x$url, x$encoding, dest)
}

download_file.datetime <- function(x, dest, ...) {
  params <- list(...)
  if (is.null(params$refdate)) {
    msg <- "refdate argument not provided - download can't be done"
    cli::cli_alert_danger(msg)
    return(FALSE)
  }
  url <- strftime(params$refdate, x$url)
  just_download_data(url, x$encoding, dest)
}

just_download_data <- function(url, encoding, dest) {
  res <- httr::GET(url)
  if (httr::status_code(res) != 200) {
    return(FALSE)
  }
  if (httr::headers(res)[["content-type"]] == "application/octet-stream" ||
    httr::headers(res)[["content-type"]] == "application/x-zip-compressed") {
    bin <- httr::content(res, as = "raw")
    writeBin(bin, dest)
  } else {
    text <- httr::content(res, as = "text", encoding = encoding)
    writeLines(text, dest)
  }
  TRUE
}