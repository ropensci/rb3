#' Download datasets
#'
#' Download datasets for a given template.
#'
#' @param template the template name
#' @param cache_folder Location of cache folder (default = cachedir())
#' @param do_cache a logical indicating if the existing file (previously
#'        downloaded) should be used or replaced.
#' @param ... additional arguments
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
                                do_cache = FALSE, ...) {
  template <- template_retrieve(template)

  download_args <- list(...)
  l_ <- c(id = template$id, download_args)
  x <- lapply(l_, format)
  names(x) <- names(l_)
  code_ <- digest(x)

  raw_folder <- file.path(cache_folder, "raw")
  if (!dir.exists(raw_folder)) {
    dir.create(raw_folder, recursive = TRUE)
  }

  meta_folder <- file.path(cache_folder, "meta")
  if (!dir.exists(meta_folder)) {
    dir.create(meta_folder, recursive = TRUE)
  }
  meta_file <- file.path(meta_folder, str_glue("{code_}.json"))
  meta <- if (file.exists(meta_file)) {
    fromJSON(meta_file)
  } else {
    list(
      template = template$id,
      download_checksum = code_,
      file_checksum = NULL,
      download_args = download_args,
      downloaded = NULL,
      timestamp = NULL
    )
  }

  if (!is.null(meta[["downloaded"]]) && !do_cache) {
    return(meta)
  }

  dest <- tempfile(fileext = str_glue(".{template$downloader$format}"))
  if (template$download_marketdata(template, dest, ...)) {
    fname <- unzip_recursive(dest)
    md5 <- tools::md5sum(fname)
    if (!is.null(meta[["file_checksum"]]) && md5 == meta[["file_checksum"]]) {
      return(meta)
    }
    meta[["file_checksum"]] <- md5
    dest_fname <- file.path(raw_folder, str_glue("{meta$file_checksum}.gz"))
    downloaded <- R.utils::compressFile(fname, dest_fname, "gz", gzfile,
      overwrite = TRUE
    )
    if (!is.null(meta[["downloaded"]])) {
      unlink(meta[["downloaded"]])
    }
    meta[["downloaded"]] <- downloaded
    meta[["timestamp"]] <- file.info(meta[["downloaded"]])[["ctime"]]
    writeLines(toJSON(meta, auto_unbox = TRUE), meta_file)
    return(meta)
  } else {
    return(NULL)
  }
}

unzip_recursive <- function(fname) {
  if (length(fname) == 1 && str_ends(str_to_lower(fname), ".zip")) {
    exdir <- str_replace(fname, "\\.zip$", "")
    l <- unzip(fname, exdir = exdir)
    unzip_recursive(l)
  } else {
    fname
  }
}

.safecontent <- function(x) {
  cl <- headers(x)[["content-length"]]
  if (is.null(cl)) {
    TRUE
  } else {
    cl != 0
  }
}

just_download_data <- function(url, encoding, dest, verifyssl = TRUE) {
  res <- if (!is.null(verifyssl) && !verifyssl) {
    GET(url, config(ssl_verifypeer = FALSE))
  } else {
    GET(url)
  }
  if (status_code(res) != 200 || !.safecontent(res)) {
    return(FALSE)
  }
  save_resource(res, encoding, dest)
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
