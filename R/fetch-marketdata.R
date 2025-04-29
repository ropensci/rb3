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
#' fetch_marketdata("b3-indexes-historical-data",
#'   throttle = TRUE, index = c("IBOV", "IBXX", "IBXL"),
#'   year = 2000:2025
#' )
#' }
#'
#' @export
fetch_marketdata <- function(template, do_cache = FALSE, throttle = FALSE, ...) {
  df <- expand.grid(..., stringsAsFactors = FALSE)
  cli::cli_h1("Fetching market data for {.var {template}}")
  # ----
  start_ <- Sys.time()
  if (nrow(df) == 0) {
    pb <- cli::cli_progress_bar("Downloading data", total = 1, clear = FALSE)
    m <- download_(template = template, pb = pb, do_cache = do_cache, throttle = throttle)
    ms <- list(m)
  } else {
    pb <- cli::cli_progress_bar("Downloading data", total = nrow(df), clear = FALSE)
    ms <- purrr::pmap(df, download_, template = template, pb = pb, do_cache = do_cache, throttle = throttle)
  }
  end_ <- Sys.time()
  elapsed <- as.numeric(difftime(end_, start_, units = "secs"))
  cli::cli_process_done(id = pb)
  # ----
  ms <- purrr::keep(ms, ~ !is.null(.x))
  if (length(ms) == 0) {
    cli::cli_alert_warning("No data downloaded")
    return(invisible(NULL))
  }
  # ----
  cli::cli_inform(c(v = "{length(ms)} file{?s} downloaded [{round(elapsed, 2)}s]"))
  # Creating input layer ----
  pb <- cli::cli_progress_bar("Creating input layer", total = length(ms), clear = FALSE)
  start_ <- Sys.time()
  purrr::map(ms, read_, pb = pb)
  end_ <- Sys.time()
  elapsed <- as.numeric(difftime(end_, start_, units = "secs"))
  cli::cli_process_done(id = pb)
  cli::cli_inform(c(v = "{.strong input} layer created [{round(elapsed, 2)}s]"))
  # Creating staging layer ----
  template <- template_retrieve(template)
  if (!is.null(template$writers$staging)) {
    cli::cli_alert_info("Creating {.strong staging} layer")
    start_ <- Sys.time()
    ds <- template_dataset(template, layer = template$writers$input$layer)
    ds <- template$writers$staging$process_marketdata(ds)
    if (!is.null(template$writers$staging$partition)) {
      arrow::write_dataset(
        ds,
        template_db_folder(template, layer = template$writers$staging$layer),
        partitioning = template$writers$staging$partition
      )
    } else {
      arrow::write_dataset(
        ds,
        template_db_folder(template, layer = template$writers$staging$layer)
      )
    }
    end_ <- Sys.time()
    elapsed <- as.numeric(difftime(end_, start_, units = "secs"))
    cli::cli_inform(c(v = "{.strong staging} layer created [{round(elapsed, 2)}s]"))
  }

  invisible(NULL)
}

download_ <- function(..., template, pb, throttle, do_cache) {
  cli::cli_progress_update(id = pb)
  m <- tryCatch(
    {
      m <- download_marketdata(template, do_cache = do_cache, ...)
      if (throttle) {
        Sys.sleep(1)
      }
      m
    },
    error = function(e) {
      template_meta_load(template, ...)
    }
  )
  if (is.null(m)) {
    row <- list(...)
    msg <- paste(names(row), row, sep = " = ", collapse = ", ")
    cli::cli_alert_info("No data downloaded for args {.val {msg}}")
  }
  m
}

read_ <- function(m, pb) {
  cli::cli_progress_update(id = pb)
  x <- read_marketdata(m)
  if (is.null(x)) {
    row <- m$download_args
    msg <- paste(names(row), purrr::map(row, format), sep = " = ", collapse = ", ")
    cli::cli_alert_warning("Invalid file for args: {.val {msg}}")
  }
}
