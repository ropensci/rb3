#' Download Raw Market Data Files from B3
#'
#' @description
#' Downloads and caches financial market datasets from B3 (Brazilian Stock Exchange)
#' based on predefined templates. Handles file downloading and caching.
#'
#' @param meta A metadata object.
#'
#' @return
#' Returns a meta object containing the downloaded file's metadata:
#' \itemize{
#'   \item template - Name of the template used
#'   \item download_checksum - Unique hash code for the download
#'   \item download_args - Arguments used for the download
#'   \item downloaded - Path to the downloaded file
#'   \item created - Timestamp of file creation
#'   \item is_downloaded - Whether the file was successfully downloaded
#'   \item is_processed - Whether the file was successfully processed
#'   \item is_valid - Whether the file is valid
#' }
#'
#' The `meta` object can be interpreted as a ticket for the download process.
#' It contains all the necessary information to identify the data, if it has been
#' downloaded, if it has been processed, and ince it is processed,
#' if the downloaded file is valid.
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
#' @seealso
#' * \code{\link{template_meta_create_or_load}} for creating a metadata object
#' * \code{\link{list_templates}} for listing available data templates
#' * \code{\link{template_retrieve}} for retrieving specific template details
#'
#' @seealso
#' \code{\link{read_marketdata}}, \code{\link{rb3.cachedir}}
#'
#' @examples
#' \dontrun{
#' # Create metadata for daily market data
#' meta <- template_meta_create_or_load("b3-cotahist-daily",
#'   refdate = as.Date("2024-04-05")
#' )
#' # Download using the metadata
#' meta <- download_marketdata(meta)
#'
#' # For reference rates
#' meta <- template_meta_create_or_load("b3-reference-rates",
#'   refdate = as.Date("2024-04-05"),
#'   curve_name = "PRE"
#' )
#' # Download using the metadata
#' meta <- download_marketdata(meta)
#' }
#'
#' @export
download_marketdata <- function(meta) {
  template <- template_retrieve(meta$template)

  tryCatch(
    perform_download(template, meta),
    error = function(e) {
      handle_download_error(e, meta)
    }
  )
}

# Perform the actual download
perform_download <- function(template, meta) {
  dest <- tempfile(fileext = str_glue(".{template$downloader$format}"))

  # Extract arguments from metadata to use with the template's download function
  args <- meta$download_args

  # Call the template's download function with the arguments from metadata
  if (do.call(template_download_marketdata, c(list(template, dest), args))) {
    process_downloaded_file(dest, template, meta)
  } else {
    cli::cli_abort("Download failed for meta {.strong {meta$download_checksum}}",
      class = "error_download_fail"
    )
  }
}

# Process the downloaded file
process_downloaded_file <- function(dest, template, meta) {
  filename <- unzip_recursive(dest)
  filename <- select_file_if_multiple(filename, template$downloader[["if-has-multiple-files-use"]])

  md5 <- tools::md5sum(filename)
  ext <- "gz"
  dest_fname <- meta_dest_file(meta, md5, ext)

  if (file.exists(dest_fname) && length(meta$downloaded) > 0) {
    cli::cli_abort("File already exists for meta {.strong {meta$download_checksum}}: {.file {dest_fname}}",
      class = "error_download_file_exists"
    )
  }

  finalize_download(filename, dest_fname, meta, ext)
}

# Finalize the download process
finalize_download <- function(filename, dest_fname, meta, ext) {
  downloaded <- R.utils::compressFile(filename, dest_fname, ext, gzfile, overwrite = TRUE)
  if (length(meta[["downloaded"]]) > 0) {
    x <- meta$downloaded[[1]]
    unlink(x)
    meta_add_download(meta) <- NULL
    cli::cli_alert_info("Replacing file {.file {x}} with {.file {downloaded}}")
  }
  meta_add_download(meta) <- downloaded
  meta_set_downloaded(meta) <- TRUE
  meta_set_processed(meta) <- FALSE
  meta_set_valid(meta) <- FALSE
  meta
}

# Handle errors during the download process
handle_download_error <- function(e, meta) {
  if (inherits(e, "error_download_fail")) {
    meta_set_downloaded(meta) <- FALSE
    return(meta)
  } else if (inherits(e, "error_download_file_exists")) {
    return(meta)
  } else {
    cli::cli_abort("Unknown error", class = "error_download_unknown", parent = e)
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
