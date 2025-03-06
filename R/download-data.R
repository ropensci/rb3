#' Download datasets
#'
#' Download datasets for a given template.
#'
#' @param template the template name
#' @param cache_folder location of cache folder (default = cachedir())
#' @param do_cache a logical indicating if the file should be downloaded again
#' @param ... additional arguments
#'
#' @return a list with the metadata of the downloaded file (see details).
#'
#' The function returns a list containing the metadata of the
#' downloaded file, including the following information:  
#' - `template`: Template name
#' - `download_checksum`: Download hash code,
#'    generated from the template name and the arguments passed in the ellipsis (`...`)  
#' - `file_checksum`: File hash code
#' - `download_args`: Arguments passed in the ellipsis (`...`)  
#' - `downloaded`: Path to the downloaded file  
#' - `timestamp`: Timestamp of when the file was saved
#' 
#' A metadata file is saved in the `meta` directory inside `rb3.cachedir`.
#' This metadata file is in JSON format, and its filename is the download hash code (`download_checksum`).
#' It ensures the uniqueness of the download.
#'
#' All downloaded files are compressed using Gzip and named with their file checksum (`file_checksum`),
#' also to ensure uniqueness.
#' The downloaded files are stored in the `raw` directory, which is located inside `rb3.cachedir`.
#' 
#' @details
#' This function downloads a file based on a template.
#' The template is a YAML document that defines a dataset.
#' It specifies how the file is downloaded, how it is read,
#' and the structure of the dataset, including column names
#' and data types.
#' 
#' The `do_cache` argument is `FALSE` by default, indicating that if the file already exists in the cache,
#' it will not be downloaded again.
#' First, it checks if the metadata file exists; if it does, it is returned.
#' If `do_cache` is `TRUE`, the file is downloaded again, and the metadata is updated.
#' If the downloaded file is identical to the cached file, verified using `file_checksum`,
#' the metadata is returned.
#' 
#' The additional arguments in the ellipsis (`...`) are passed to the template function that handles data downloads.
#' 
#' @seealso cachedir rb3.cachedir
#'
#' @examples
#' \dontrun{
#' download_marketdata("b3-cotahist-daily", refdate = as.Date("2024-04-05"))
#' 
#' m <- download_marketdata("b3-reference-rates", refdate = as.Date("2024-04-05"), curve_name = "PRE")
#' read_marketdata(m)
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
