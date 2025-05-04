#' Fetch and process market data
#'
#' Downloads market data based on a template and parameter combinations, then reads
#' the data into a database.
#'
#' @param template A character string specifying the market data template to use
#' @param force_download A logical value indicating whether to force downloading files
#'   even if they already exist in the cache (default is `FALSE`). If `TRUE`, the function
#'   will download files again even if they were previously downloaded.
#' @param reprocess A logical value indicating whether to reprocess files even if they
#'  are already processed (default is `FALSE`). If `TRUE`, the function will reprocess
#'  the files in the input layer, even if they were previously processed.
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
fetch_marketdata <- function(template, force_download = FALSE, reprocess = FALSE, throttle = FALSE, ...) {
  cli::cli_h1("Fetching market data for {.var {template}}")

  metadata_list <- create_meta_list(template, ...)

  # Download phase
  metadata_list <- download_market_files(metadata_list, force_download, throttle)

  # Process phase
  ## Process input layer
  input_layer_changed <- process_input_layer(metadata_list, reprocess)
  ## Process staging layer
  process_staging_layer(template, input_layer_changed, reprocess)

  invisible(NULL)
}

#' Download market data files based on template and parameters
#'
#' @param force_download Whether to force download even if file exists in cache
#' @param throttle Whether to introduce delay between downloads
#' @param ... Parameter combinations for data to fetch
#'
#' @return List of metadata for successfully downloaded files
#'
#' @noRd
download_market_files <- function(metadata_list, force_download = FALSE, throttle = FALSE) {
  cli::cli_text("── {.strong Downloading data}")
  pb <- cli::cli_progress_bar("Downloading data", total = length(metadata_list))
  on.exit(cli::cli_process_done(id = pb))

  # Count files already downloaded
  downloaded_count_before <- sum(purrr::map_lgl(metadata_list, ~ .x$is_downloaded))
  # Report on files to download vs. skip
  if (force_download) {
    cli::cli_alert_info("Downloading {length(metadata_list)} file{?s}")
  } else {
    cli::cli_alert_info("Downloading {length(metadata_list) - downloaded_count_before} file{?s}, skipping {downloaded_count_before}")
  }

  start_time <- Sys.time()
  metadata_list <- purrr::map(metadata_list, download_single_file,
    pb = pb, force_download = force_download, throttle = throttle
  )
  end_time <- Sys.time()
  elapsed <- as.numeric(difftime(end_time, start_time, units = "secs"))

  # Report results
  downloaded_count_after <- sum(purrr::map_lgl(metadata_list, ~ .x$is_downloaded))
  if (force_download) {
    cli::cli_inform(c(v = "{.strong Downloaded} {length(metadata_list)} file{?s} [{round(elapsed, 2)}s]"))
  } else {
    cli::cli_inform(c(v = "{downloaded_count_after - downloaded_count_before} file{?s} downloaded [{round(elapsed, 2)}s]"))
  }

  return(metadata_list)
}

#' Download a single market data file
#'
#' @param metadata Metadata for the file to download
#' @param pb Progress bar ID
#' @param force_download Whether to force download even if file exists in cache
#' @param throttle Whether to introduce delay between downloads
#' @param ... Additional parameters for download
#'
#' @return Metadata for the downloaded file or NULL if download failed
#'
#' @noRd
download_single_file <- function(metadata, pb = NULL, force_download = FALSE, throttle = FALSE) {
  on.exit(cli::cli_progress_update(id = pb))

  # Download the file if it doesn't exist or if forced
  metadata <- withCallingHandlers(
    {
      if (!metadata$is_downloaded || force_download) {
        metadata <- download_marketdata(metadata)
        if (throttle) {
          Sys.sleep(1)
        }
      }
      metadata
    },
    message = function(m) {
      invokeRestart("muffleMessage")
    }
  )

  if (!metadata$is_downloaded) {
    args <- metadata$download_args
    arg_str <- paste(names(args), purrr::map(args, format), sep = " = ", collapse = ", ")
    cli::cli_progress_output("Failed to download file for args: {.val {arg_str}}", id = pb)
  }

  return(metadata)
}

#' Process staging layer if configured
#'
#' @param template Template name
#' @param input_layer_changed Whether the input layer has changed
#' @param reprocess Whether to reprocess files even if they are already processed
#'
#' @return NULL (invisibly)
#'
#' @noRd
process_staging_layer <- function(template, input_layer_changed, reprocess) {
  # Process staging layer if configured
  template_obj <- template_retrieve(template)
  if (!is.null(template_obj$writers$staging) && (input_layer_changed || reprocess)) {
    cli::cli_alert_info("input layer changed")
    # Create staging layer
    create_staging_layer(template_obj)
  }
}

#' Create input layer from downloaded files
#'
#' @param metadata_list List of metadata for downloaded files
#' @param reprocess Whether to reprocess files even if they are already processed
#'
#' @return NULL (invisibly)
#'
#' @noRd
process_input_layer <- function(metadata_list, reprocess) {
  cli::cli_text("── {.strong Processing {length(metadata_list)} file{?s}}")
  cli::cli_alert_info("Updating {.strong input} layer")
  pb <- cli::cli_progress_bar("Updating input layer", total = length(metadata_list))
  on.exit(cli::cli_process_done(id = pb))

  # Count valid files before processing
  valid_count_before <- sum(purrr::map_lgl(metadata_list, ~ .x$is_valid))
  # process file
  start_time <- Sys.time()
  metadata_list <- purrr::map(metadata_list, process_file, pb = pb, reprocess = reprocess)
  end_time <- Sys.time()
  elapsed <- as.numeric(difftime(end_time, start_time, units = "secs"))
  # Count valid files after processing
  valid_count_after <- sum(purrr::map_lgl(metadata_list, ~ .x$is_valid))
  # Check if the number of valid files has changed
  # It indicates that the input layer has been updated
  # and the staging layer needs to be recreated
  input_layer_changed <- valid_count_before != valid_count_after

  if (input_layer_changed) {
    cli::cli_inform(c(v = "{.strong input} layer updated [{round(elapsed, 2)}s]"))
  } else if (reprocess) {
    cli::cli_inform(c(v = "{.strong input} layer reprocessed [{round(elapsed, 2)}s]"))
  } else {
    cli::cli_inform(c(v = "{.strong input} layer not updated - no new files detected [{round(elapsed, 2)}s]"))
  }

  return(input_layer_changed)
}

#' Create staging layer from input layer
#'
#' @param template Template object
#'
#' @return NULL (invisibly)
#'
#' @noRd
create_staging_layer <- function(template) {
  cli::cli_alert_info("Creating {.strong staging} layer")
  start_time <- Sys.time()

  # Load dataset from input layer
  ds <- template_dataset(template, layer = template$writers$input$layer)

  # Process dataset using template-specific function
  ds <- template$writers$staging$process_marketdata(ds)

  # Write dataset with appropriate partitioning
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

  end_time <- Sys.time()
  elapsed <- as.numeric(difftime(end_time, start_time, units = "secs"))
  cli::cli_inform(c(v = "{.strong staging} layer created [{round(elapsed, 2)}s]"))

  return(invisible(NULL))
}

#' Process a single downloaded file
#'
#' @param metadata Metadata for the downloaded file
#' @param pb Progress bar ID
#'
#' @return Result of read_marketdata operation
#'
#' @noRd
process_file <- function(metadata, pb, reprocess = FALSE) {
  on.exit(cli::cli_progress_update(id = pb))

  result <- withCallingHandlers(
    {
      if (!metadata$is_processed || reprocess) {
        metadata <- read_marketdata(metadata)
      }
      metadata
    },
    message = function(m) {
      invokeRestart("muffleMessage")
    }
  )

  if (!result$is_valid) {
    args <- metadata$download_args
    arg_str <- paste(names(args), purrr::map(args, format), sep = " = ", collapse = ", ")
    cli::cli_progress_output("Invalid file for args: {.val {arg_str}}", id = pb)
  }

  return(result)
}

#' Get/create meta for a template with specific parameters
#'
#' @param ... Parameters for the file
#' @param template Template name
#'
#' @return list of meta objects
#'
#' @noRd
create_meta_list <- function(template, ...) {
  parameter_grid <- expand.grid(..., stringsAsFactors = FALSE)
  if (nrow(parameter_grid) == 0) {
    list(template_meta_create_or_load(template))
  } else {
    purrr::pmap(parameter_grid, function(...) template_meta_create_or_load(template, ...))
  }
}
