#' Download Raw Market Data Files from B3
#'
#' @description
#' Downloads and caches financial market datasets from B3 (Brazilian Stock Exchange)
#' based on predefined templates. Handles file downloading and caching.
#'
#' @param template character string specifying the template name
#' @param do_cache logical; if TRUE forces a new download even if cached file exists (default: FALSE)
#' @param ... additional arguments passed to template-specific download functions
#'
#' @return
#' Returns a meta object containing the downloaded file's metadata:
#' \itemize{
#'   \item template - Name of the template used
#'   \item download_checksum - Unique hash code for the download
#'   \item download_args - Arguments passed via ...
#'   \item downloaded - Path to the downloaded file
#'   \item created - Timestamp of file creation
#' }
#'
#' @details
#' The function follows this workflow:
#' 1. Checks if requested data exists in cache
#' 2. Downloads data if needed (based on template specifications)
#' 3. Manages file compression and storage
#' 4. Maintains metadata for tracking and verification
#'
#' Files are organized in the `rb3.cachedir` as follows:
#' - Data: Gzipped files in 'raw/' directory, named by file's checksum
#'
#' Templates are YAML documents that define:
#' - Download parameters and methods
#' - Data reading instructions
#' - Dataset structure (columns, types)
#' 
#' Templates can be found using `list_templates()` and retrieved with `template_retrieve()`.
#' 
#' @return A meta object containing the downloaded file's metadata.
#' This meta object is used with the `read_marketdata` function to read the downloaded file.
#'
#' @seealso 
#' * \code{\link{list_templates}} for listing available data templates
#' * \code{\link{template_retrieve}} for retrieving specific template details
#' 
#' @seealso
#' \code{\link{read_marketdata}}, \code{\link{rb3.cachedir}}
#' 
#' @examples
#' \dontrun{
#' # Download daily market data
#' meta <- download_marketdata("b3-cotahist-daily", 
#'                             refdate = as.Date("2024-04-05"))
#' read_marketdata(meta)
#' 
#' # Download reference rates
#' meta <- download_marketdata("b3-reference-rates",
#'                             refdate = as.Date("2024-04-05"),
#'                             curve_name = "PRE")
#' read_marketdata(meta)
#' }
#'
#' @export
download_marketdata <- function(template, do_cache = FALSE, ...) {
  template <- template_retrieve(template)
  meta <- try(template_meta_new(template, ...), silent = TRUE)
  if (inherits(meta, "try-error")) {
    if (do_cache) {
      meta <- template_meta_load(template, ...)
    } else {
      e <- attr(meta, "condition")
      cli::cli_abort("Meta exists", parent = e)
    }
  }
  tryCatch({
    .download_marketdata(template, meta, ...)
  }, error = function(e) {
    if (inherits(e, "error_download_fail") || inherits(e, "error_download_empty_file")) {
      meta_clean(meta)
      return(NULL)
    } else if (inherits(e, "error_download_file_exists")) {
      return(meta)
    } else {
      cli::cli_alert("Unknown error", parent = e)
    }
  })
}

.download_marketdata <- function(template, meta, ...) {
  dest <- tempfile(fileext = str_glue(".{template$downloader$format}"))
  if (download_marketdata_wrapper(template, dest, ...)) {
    filename <- unzip_recursive(dest)
    filename <- select_file_if_multiple(filename, template$downloader[["if-has-multiple-files-use"]])
    if (file.size(filename) <= 2) {
      cli::cli_abort("File is empty: {.file {filename}}",
        class = "error_download_empty_file"
      )
    }
    md5 <- tools::md5sum(filename)
    ext <- "gz"
    dest_fname <- meta_dest_file(meta, md5, ext)
    if (file.exists(dest_fname) && length(meta$downloaded) > 0) {
      cli::cli_abort("File already exists for meta {.strong {meta$download_checksum}}: {.file {dest_fname}}",
        class = "error_download_file_exists"
      )
    }
    downloaded <- R.utils::compressFile(filename, dest_fname, ext, gzfile, overwrite = TRUE)
    if (length(meta[["downloaded"]]) > 0) {
      x <- meta[["downloaded"]][[1]]
      unlink(x)
      cli::cli_alert_info("Removing file {.file {x}}")
      cli::cli_alert_info("Saving file {.file {downloaded}}")
      meta_add_download(meta) <- NULL
    }
    meta_add_download(meta) <- downloaded
    return(meta)
  } else {
    cli::cli_abort("Download failed for meta {.strong {meta$download_checksum}}",
      class = "error_download_fail"
    )
  }
}

unzip_recursive <- function(fname) {
  if (length(fname) == 1 && str_ends(str_to_lower(fname), ".zip")) {
    exdir <- str_replace(fname, "\\.zip$", "")
    l <- utils::unzip(fname, exdir = exdir)
    unzip_recursive(l)
  } else {
    fname
  }
}

select_file_if_multiple <- function(files, tag) {
  if (length(files) == 1 || is.null(tag)) {
    return(files[[1]])
  } else if (tag == "newer") {
    return(sort(files, decreasing = TRUE)[[1]])
  }
}
