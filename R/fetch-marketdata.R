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
  cli::cli_h2("Fetching market data for {.var {template}}")
  # ----
  cli::cli_h3("Downloading data")
  start_ <- Sys.time()
  if (nrow(df) == 0) {
    pb <- cli::cli_progress_bar("Downloading data", total = 1)
    m <- download_(template = template, pb = pb, do_cache = do_cache, throttle = throttle)
    ms <- list(m)
  } else {
    # check for existing metas ----
    metas <- purrr::pmap(df, meta_, template = template)
    if (do_cache) {
      to_skip_idx <- integer(0)
      to_download_idx <- seq_along(metas)
    } else {
      to_skip_idx <- purrr::map_lgl(metas, ~ !is.null(.x)) |> which()
      to_download_idx <- purrr::map_lgl(metas, is.null) |> which()
    }
    if (length(to_skip_idx) > 0) {
      cli::cli_alert_info("Downloading {length(to_download_idx)}/{length(metas)} file{?s}, skipping {length(to_skip_idx)}/{length(metas)}")
    } else {
      cli::cli_alert_info("Downloading {length(to_download_idx)}/{length(metas)} file{?s}")
    }
    if (length(to_download_idx) > 0) {
      dfx <- df[to_download_idx, , drop = FALSE]
      pb <- cli::cli_progress_bar("Downloading data", total = nrow(dfx))
      ms <- purrr::pmap(dfx, download_,
        template = template, pb = pb, do_cache = do_cache, throttle = throttle
      )
      cli::cli_process_done(id = pb)
    } else {
      ms <- list()
    }
  }
  end_ <- Sys.time()
  elapsed <- as.numeric(difftime(end_, start_, units = "secs"))
  cli::cli_inform(c(v = "{length(ms)} file{?s} downloaded [{round(elapsed, 2)}s]"))
  # ----
  initial_len <- length(ms)
  ms <- purrr::keep(ms, ~ !is.null(.x))
  if (length(ms) == 0) {
    cli::cli_alert_warning("No data downloaded")
    return(invisible(NULL))
  } else if (length(ms) < initial_len) {
    cli::cli_alert_warning("{length(ms)} file{?s} could not be downloaded - check messages above")
  }
  # ----
  cli::cli_h3("Processing {length(ms)} file{?s}")
  # Creating input layer ----
  cli::cli_alert_info("Creating {.strong input} layer")
  pb <- cli::cli_progress_bar("Creating input layer", total = length(ms))
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

get_existing_meta <- function(template, ...) {
  df <- expand.grid(..., stringsAsFactors = FALSE)
  purrr::pmap(df, meta_, template = template)
}

meta_ <- function(..., template) {
  template <- template_retrieve(template)
  checksum <- meta_checksum(template$id, ..., extra_arg = template_extra_arg(template))
  tryCatch(meta_get(checksum), error = function(e) NULL)
}

download_ <- function(..., template, pb, throttle, do_cache) {
  cli::cli_progress_update(id = pb)
  m <- withCallingHandlers(
    tryCatch(
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
    ),
    message = function(m) {
      invokeRestart("muffleMessage")
    }
  )
  if (is.null(m)) {
    row <- list(...)
    msg <- paste(names(row), row, sep = " = ", collapse = ", ")
    cli::cli_progress_output("No data downloaded for args {.val {msg}}", id = pb)
  }
  m
}

read_ <- function(m, pb) {
  cli::cli_progress_update(id = pb)
  x <- withCallingHandlers(
    {
      read_marketdata(m)
    },
    message = function(m) {
      invokeRestart("muffleMessage")
    }
  )
  if (!x$is_valid) {
    row <- m$download_args
    msg <- paste(names(row), purrr::map(row, format), sep = " = ", collapse = ", ")
    cli::cli_progress_output("Invalid file for args: {.val {msg}}", id = pb)
  }
}
