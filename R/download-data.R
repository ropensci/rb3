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
#' - Metadata: JSON files in 'meta/' directory, named by download_checksum
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
  meta <- template_meta_create(template, ..., extra_arg = template_extra_arg(template))

  if (length(meta[["downloaded"]]) > 0 && !do_cache) {
    cli_alert_info("Meta {.strong {meta$download_checksum}} already exists. Use {.code do_cache = TRUE} to download again.")
    return(meta)
  }

  dest <- tempfile(fileext = str_glue(".{template$downloader$format}"))
  if (download_marketdata_wrapper(template, dest, ...)) {
    filename <- unzip_recursive(dest)
    filename <- select_file_if_multiple(filename, template$downloader[["if-has-multiple-files-use"]])
    if (file.size(filename) <= 2) {
      cli_alert_warning("File is empty: {.file {filename}}")
      return(NULL)
    }
    md5 <- tools::md5sum(filename)
    ext <- "gz"
    dest_fname <- meta_dest_file(meta, md5, ext)
    if (file.exists(dest_fname)) {
      cli_alert_info("File {.file {dest_fname}} already exists for meta {.strong {meta$download_checksum}}")
      return(meta)
    }
    downloaded <- R.utils::compressFile(filename, dest_fname, ext, gzfile, overwrite = TRUE)
    if (length(meta[["downloaded"]]) > 0) {
      cli_alert_info("Replacing downloaded file {.file {meta$downloaded}}")
      cli_alert_info("                     with {.file {downloaded}}")
      unlink(meta[["downloaded"]])
      meta[["downloaded"]] <- list()
    }
    meta_add_download(meta) <- downloaded
    meta_save(meta)
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

select_file_if_multiple <- function(files, tag) {
  if (length(files) == 1 || is.null(tag)) {
    return(files[[1]])
  } else if (tag == "newer") {
    return(sort(files, decreasing = TRUE)[[1]])
  }
}
