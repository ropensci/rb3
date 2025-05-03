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
  cli::cli_h2("Fetching market data for {.var {template}}")

  # Download phase
  metadata_list <- download_market_files(template, force_download, throttle, ...)

  if (length(metadata_list) == 0) {
    cli::cli_alert_warning("No data downloaded")
    return(invisible(NULL))
  }

  # Process phase
  process_market_files(template, metadata_list, reprocess)

  invisible(NULL)
}

#' Download market data files based on template and parameters
#'
#' @param template Name of the template to use
#' @param force_download Whether to force download even if file exists in cache
#' @param throttle Whether to introduce delay between downloads
#' @param ... Parameter combinations for data to fetch
#'
#' @return List of metadata for successfully downloaded files
#'
#' @noRd
download_market_files <- function(template, force_download = FALSE, throttle = FALSE, ...) {
  cli::cli_h3("Downloading data")
  start_time <- Sys.time()

  parameter_grid <- expand.grid(..., stringsAsFactors = FALSE)

  # Single download case (no parameters)
  if (nrow(parameter_grid) == 0) {
    pb <- cli::cli_progress_bar("Downloading data", total = 1)
    metadata <- download_single_file(template, pb, force_download, throttle)
    metadata_list <- list(metadata)
  } else {
    # Multiple downloads case
    metadata_list <- download_multiple_files(template, parameter_grid, force_download, throttle)
  }

  end_time <- Sys.time()
  elapsed <- as.numeric(difftime(end_time, start_time, units = "secs"))

  # Filter out NULL entries (failed downloads)
  initial_count <- length(metadata_list)
  metadata_list <- purrr::keep(metadata_list, ~ !is.null(.x))

  # Report results
  cli::cli_inform(c(v = "{length(metadata_list)} file{?s} downloaded [{round(elapsed, 2)}s]"))
  if (length(metadata_list) < initial_count) {
    cli::cli_alert_warning("{initial_count - length(metadata_list)} file{?s} could not be downloaded - check messages above")
  }

  return(metadata_list)
}

#' Download a single market data file
#'
#' @param template Template name
#' @param pb Progress bar ID
#' @param force_download Whether to force download even if file exists in cache
#' @param throttle Whether to introduce delay between downloads
#' @param ... Additional parameters for download
#'
#' @return Metadata for the downloaded file or NULL if download failed
#'
#' @noRd
download_single_file <- function(template, pb, force_download = FALSE, throttle = FALSE, ...) {
  on.exit(cli::cli_progress_update(id = pb))

  # Check for existing metadata to avoid redundant downloads
  metadata <- template_meta_create_or_load(template, ...)
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

#' Download multiple market data files
#'
#' @param template Template name
#' @param parameter_grid Data frame with parameter combinations
#' @param force_download Whether to force download even if file exists in cache
#' @param throttle Whether to introduce delay between downloads
#'
#' @return List of metadata for successfully downloaded files
#'
#' @noRd
download_multiple_files <- function(template, parameter_grid, force_download = FALSE, throttle = FALSE) {
  # Check for existing metadata to avoid redundant downloads
  existing_metadata <- purrr::pmap(parameter_grid, get_file_metadata, template = template)

  if (force_download) {
    download_indices <- seq_along(existing_metadata)
    skip_indices <- integer(0)
  } else {
    skip_indices <- which(purrr::map_lgl(existing_metadata, ~ !is.null(.x)))
    download_indices <- which(purrr::map_lgl(existing_metadata, is.null))
  }

  # Report on files to download vs. skip
  if (length(skip_indices) > 0) {
    cli::cli_alert_info("Downloading {length(download_indices)}/{length(existing_metadata)} file{?s}, skipping {length(skip_indices)}/{length(existing_metadata)}")
  } else {
    cli::cli_alert_info("Downloading {length(download_indices)}/{length(existing_metadata)} file{?s}")
  }

  metadata_list <- list()

  # Download files that need downloading
  if (length(download_indices) > 0) {
    download_grid <- parameter_grid[download_indices, , drop = FALSE]
    pb <- cli::cli_progress_bar("Downloading data", total = nrow(download_grid))

    metadata_list <- purrr::pmap(download_grid, download_single_file,
      template = template, pb = pb,
      force_download = force_download, throttle = throttle
    )

    cli::cli_process_done(id = pb)
  }

  return(metadata_list)
}

#' Process downloaded market data files
#'
#' @param template Template name
#' @param metadata_list List of metadata for downloaded files
#' @param reprocess Whether to reprocess files even if they are already processed
#'
#' @return NULL (invisibly)
#'
#' @noRd
process_market_files <- function(template, metadata_list, reprocess) {
  cli::cli_h3("Processing {length(metadata_list)} file{?s}")

  # Process input layer
  input_layer_changed <- create_input_layer(metadata_list, reprocess)

  # Process staging layer if configured
  template_obj <- template_retrieve(template)
  if (!is.null(template_obj$writers$staging) && input_layer_changed) {
    cli::cli_alert_info("Input layer changed, creating staging layer")
    # Create staging layer
    create_staging_layer(template_obj)
  }

  return(invisible(NULL))
}

#' Create input layer from downloaded files
#'
#' @param metadata_list List of metadata for downloaded files
#' @param reprocess Whether to reprocess files even if they are already processed
#'
#' @return NULL (invisibly)
#'
#' @noRd
create_input_layer <- function(metadata_list, reprocess) {
  cli::cli_alert_info("Creating {.strong input} layer")
  pb <- cli::cli_progress_bar("Creating input layer", total = length(metadata_list))

  # count valid files before processing
  valid_count_before <- sum(purrr::map_lgl(metadata_list, ~ .x$is_valid))
  # process file
  start_time <- Sys.time()
  metadata_list <- purrr::map(metadata_list, process_file, pb = pb, reprocess = reprocess)
  end_time <- Sys.time()
  # count valid files after processing
  valid_count_after <- sum(purrr::map_lgl(metadata_list, ~ .x$is_valid))

  elapsed <- as.numeric(difftime(end_time, start_time, units = "secs"))
  cli::cli_process_done(id = pb)
  if (valid_count_before != valid_count_after) {
    cli::cli_inform(c(v = "{.strong input} layer created [{round(elapsed, 2)}s]"))
  } else {
    cli::cli_inform(c(v = "{.strong input} layer not updated - no new files detected [{round(elapsed, 2)}s]"))
  }

  # Check if the number of valid files has changed
  # It indicates that the input layer has been updated
  # and the staging layer needs to be recreated
  return(valid_count_before != valid_count_after)
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

#' Get metadata for a file with specific parameters
#'
#' @param ... Parameters for the file
#' @param template Template name
#'
#' @return Metadata for the file or NULL if not found
#'
#' @noRd
get_file_metadata <- function(..., template) {
  template_obj <- template_retrieve(template)
  checksum <- meta_checksum(template_obj$id, ..., extra_arg = template_extra_arg(template_obj))
  tryCatch(meta_get(checksum), error = function(e) NULL)
}

#' Get existing metadata for all parameter combinations
#'
#' @param template Template name
#' @param ... Parameters to expand into combinations
#'
#' @return List of metadata objects
#'
#' @noRd
get_existing_meta <- function(template, ...) {
  df <- expand.grid(..., stringsAsFactors = FALSE)
  purrr::pmap(df, get_file_metadata, template = template)
}
