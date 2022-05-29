#' Download datasets
#'
#' Download datasets for a given template.
#'
#' @param template the template name
#' @param cache_folder Location of cache folder (default = cachedir())
#' @param do_cache a logical indicating if the existing file (previously
#'        downloaded) should be used or replaced.
#' @param ... aditional arguments
#'
#' @return a string with the file path of downloaded file or `NULL` if download
#'        fails.
#'
#' This function downloads data sets for those templates that specifies a
#' `downloader` attribute.
#' If `dest` is not provided, `cache_folder` is used and a file with template
#' id is saved inside it.
#'
#' @examples
#' \dontrun{
#' fname <- download_marketdata("CDIIDI")
#' }
#'
#' @export
download_marketdata <- function(template,
                                cache_folder = cachedir(),
                                do_cache = TRUE, ...) {
  template <- .retrieve_template(NULL, template)
  x <- list(...)
  code_ <- digest(x)
  dest <- file.path(
    cache_folder,
    str_glue("{template$id}-{code_}.{template$downloader$format}")
  )

  if (file.exists(dest) && do_cache) {
    # message(str_glue("Skipping download - using cached version"))
    fname <- unzip_recursive(dest)
    return(fname)
  }

  if (template$download_marketdata(dest, ...)) {
    fname <- unzip_recursive(dest)
    return(fname)
  } else {
    return(NULL)
  }
}

unzip_recursive <- function(fname) {
  if (length(fname) == 1 &&
    str_ends(str_to_lower(fname), ".zip")) {
    exdir <- str_replace(fname, "\\.zip$", "")
    l <- unzip(fname, exdir = exdir)
    unzip_recursive(l)
  } else {
    fname
  }
}

just_download_data <- function(url, encoding, dest) {
  res <- GET(url)
  if (status_code(res) != 200) {
    return(FALSE)
  }
  save_resource(res, encoding, dest)
  TRUE
}

save_resource <- function(res, encoding, dest) {
  if (headers(res)[["content-type"]] == "application/octet-stream" ||
    headers(res)[["content-type"]] == "application/x-zip-compressed") {
    bin <- content(res, as = "raw")
    writeBin(bin, dest)
  } else {
    text <- content(res, as = "text", encoding = encoding)
    writeLines(text, dest, useBytes = TRUE)
  }
}