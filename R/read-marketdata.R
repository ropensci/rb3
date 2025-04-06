#' Read and parse raw market data files downloaded from the B3 website.
#'
#' @description
#' B3 provides various files containing valuable information about
#' traded assets on the exchange and over-the-counter (OTC) market.
#' These files include historical market data, trading data, and asset registration
#' data for stocks, derivatives, and indices. This function reads these
#' files and parses their content according to the specifications
#' defined in a template.
#'
#' @param meta A list containing the downloaded file's metadata, typically returned by \code{\link{download_marketdata}}.
#'
#' @details
#' This function reads the downloaded file and parses its content according
#' to the specifications and schema defined in the template associated with the `meta` object.
#' The template specifies the file format, column definitions, and data types.
#'
#' The parsed data is then written to a partitioned dataset in Parquet format,
#' stored in a directory structure based on the template name and data layer.
#' This directory is located within the `db` subdirectory of the `rb3.cachedir` directory.
#' The partitioning scheme is also defined in the template, allowing for efficient
#' querying of the data using the `arrow` package.
#'
#' If an error occurs during file processing, the function issues a warning,
#' removes the downloaded file and its metadata, and returns `NULL`.
#'
#' @return This function invisibly returns the parsed `data.frame` if successful, or `NULL` if an error occurred.
#'
#' @seealso \code{\link{list_templates}}
#' @seealso \code{\link{rb3.cachedir}}
#' @seealso \code{\link{download_marketdata}}
#'
#' @examples
#' \dontrun{
#' meta <- download_marketdata("b3-cotahist-daily", refdate = as.Date("2024-04-05"))
#' read_marketdata(meta)
#' }
#'
#' @export
read_marketdata <- function(meta) {
  filename <- try(meta$downloaded[[1]], silent = TRUE)
  if (inherits(filename, "try-error")) {
    cli_alert_warning("File could not be read for meta {.strong {meta$download_checksum}}")
    return(invisible(NULL))
  }
  template <- template_retrieve(meta$template)
  df <- read_file_wrapper(template, filename, meta)
  if (is.null(df) || nrow(df) == 0) {
    cli_alert_warning("File could not be read: {.file {filename}}")
    meta_clean(meta)
    return(invisible(NULL))
  }
  for (writer in template$writers) {
    ds <- writer$process_marketdata(df)
    path <- template_db_folder(template, layer = writer$layer)
    ds <- arrow::arrow_table(ds, schema = template_schema(template, writer$layer))
    arrow::write_dataset(ds, path, partitioning = writer$partition)
  }
  invisible(df)
}


#' Fetch and process market data
#'
#' Downloads market data based on a template and parameter combinations, then reads
#' the data into a database.
#'
#' @param template A character string specifying the market data template to use
#' @param do_cache A logical value indicating whether to cache the downloaded files
#'   (default is `FALSE`). If `TRUE`, the downloaded files will be cached for future use.
#'   This can be useful for avoiding repeated downloads of the same data.
#' @param throttle A logical value indicating whether to throttle the download requests
#'   (default is `FALSE`). If `TRUE`, a 1-second delay is introduced between requests
#'   to avoid overwhelming the server.
#' @param ... Named arguments that will be expanded into a grid of all combinations
#'   to fetch data for
#'
#' @details
#' This function performs two main steps:
#' 1. Downloads market data files by creating all combinations of the provided parameters
#'    and calling `download_marketdata()` for each combination
#' 2. Processes the downloaded files by reading them into a database using `read_marketdata()`
#'
#' Progress indicators are displayed during both steps, and warnings are shown for
#' combinations that failed to download or produced invalid files.
#'
#' The throttle parameter is useful for avoiding server overload and ensuring
#' that the requests are sent at a reasonable rate. If set to `TRUE`, a 1-second
#' delay is introduced between each download request.
#'
#' @examples
#' \dontrun{
#' fetch_marketdata("b3-cotahist-yearly", year = 2020:2024)
#' fetch_marketdata("b3-cotahist-daily", refdate = bizseq("2025-01-01", "2025-03-10", "Brazil/B3"))
#' fetch_marketdata("b3-reference-rates",
#'   refdate = bizseq("2025-01-01", "2025-03-10", "Brazil/B3"),
#'   curve_name = c("DIC", "DOC", "PRE")
#' )
#' fetch_marketdata("b3-indexes-historical-data", throttle = TRUE, index = c("IBOV", "IBXX", "IBXL"), year = 2000:2025)
#' }
#'
#' @export
fetch_marketdata <- function(template, do_cache = FALSE, throttle = FALSE, ...) {
  df <- expand.grid(..., stringsAsFactors = FALSE)
  cli::cli_h1("Fetching market data for {.var {template}}")
  # ----
  pb <- cli::cli_progress_step("Downloading data", spinner = TRUE)
  ms <- purrr::pmap(df, download_, template = template, pb = pb, do_cache = do_cache, throttle = throttle)
  cli::cli_process_done(id = pb)
  # ----
  pb <- cli::cli_progress_step("Reading data into DB", spinner = TRUE)
  purrr::map(ms, read_, pb = pb)
  cli::cli_process_done(id = pb)
  cli::cli_alert_info("{length(ms)} files downloaded")
  invisible(NULL)
}

process_marketdata <- function(template, ...) {
  template <- template_retrieve(template)
  df <- expand.grid(..., stringsAsFactors = FALSE)
  cli::cli_h1("Processing market data for {.var {template$id}}")
  # ----
  cli::cli_text("Loading metadata")
  ms <- purrr::pmap(df, meta_get_, template = template)
  ms <- purrr::keep(ms, ~ !is.null(.x))
  # ----
  pb <- cli::cli_progress_step("Reading data into DB", spinner = TRUE)
  purrr::map(ms, read_, pb = pb)
  cli::cli_process_done(id = pb)
  cli::cli_alert_info("{length(ms)} metadata processed")
  invisible(NULL)
}

meta_get_ <- function(..., template) {
  meta <- try(meta_load(template$id, ..., extra_arg = template_extra_arg(template)), silent = TRUE)
  if (inherits(meta, "try-error")) {
    return(NULL)
  }
  meta
}

download_ <- function(..., template, pb, throttle, do_cache) {
  cli::cli_progress_update(id = pb)
  row <- list(...)
  m <- do.call(download_marketdata, c(template, do_cache = do_cache, row))
  if (throttle) {
    Sys.sleep(1)
  }
  if (is.null(m)) {
    msg <- paste(names(row), row, sep = " = ", collapse = ", ")
    cli::cli_alert_warning("No data downloaded for args {.val {msg}}")
  }
  m
}

read_ <- function(m, pb) {
  cli::cli_progress_update(id = pb)
  if (!is.null(m)) {
    x <- read_marketdata(m)
    if (is.null(x)) {
      row <- m$download_args
      msg <- paste(names(row), map(row, format), sep = " = ", collapse = ", ")
      cli::cli_alert_warning("Invalid file for args: {.val {msg}}")
    }
  }
  NULL
}
