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
#' @param meta A metadata object.
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
#' @seealso \code{\link{list_templates}}
#' @seealso \code{\link{rb3.cachedir}}
#' @seealso \code{\link{download_marketdata}}
#'
#' @examples
#' \dontrun{
#' # Create metadata for daily market data
#' meta <- template_meta_create_or_load("b3-cotahist-daily",
#'   refdate = as.Date("2024-04-05")
#' )
#' # Download using the metadata
#' meta <- download_marketdata(meta)
#' meta <- read_marketdata(meta)
#' 
#' # For reference rates
#' meta <- template_meta_create_or_load("b3-reference-rates",
#'   refdate = as.Date("2024-04-05"),
#'   curve_name = "PRE"
#' )
#' # Download using the metadata
#' meta <- download_marketdata(meta)
#' meta <- read_marketdata(meta)
#' }
#'
#' @export
read_marketdata <- function(meta) {
  # Check if file was successfully downloaded
  if (!isTRUE(meta$is_downloaded)) {
    cli::cli_alert_warning("File was not successfully downloaded for meta {.strong {meta$download_checksum}}")
    return(invisible(meta))
  }
  
  filename <- try(meta$downloaded[[1]], silent = TRUE)
  if (inherits(filename, "try-error")) {
    cli::cli_alert_warning("No downloaded file found for meta {.strong {meta$download_checksum}}")
    return(invisible(meta))
  }
  
  if (!file.exists(filename)) {
    cli::cli_alert_warning("File could not be read for meta {.strong {meta$download_checksum}}")
    return(invisible(meta))
  }
  
  template <- template_retrieve(meta$template)
  df <- read_file_wrapper(template, filename, meta)
  if (is.null(df) || nrow(df) == 0) {
    cli::cli_alert_warning("File could not be read: {.file {filename}}")
    meta_set_processed(meta) <- TRUE
    meta_set_valid(meta) <- FALSE
    return(invisible(meta))
  }

  arrow::write_dataset(
    arrow::arrow_table(df, schema = template_schema(template, template$writers$input$layer)),
    template_db_folder(template, layer = template$writers$input$layer),
    partitioning = template$writers$input$partition
  )

  # Mark as processed if everything succeeded
  meta_set_processed(meta) <- TRUE
  # Mark as valid if everything succeeded
  meta_set_valid(meta) <- TRUE

  # Return invisible original object
  invisible(meta)
}
