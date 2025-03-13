#' Read and parses files downloaded from B3 website.
#'
#' @description
#' B3 provides various files containing useful information about
#' traded assets on the exchange and over-the-counter (OTC) market.
#' These files include market data, trading data, and asset registration
#' data (stocks, derivatives, and indices). This function reads these
#' files and parses their content according to the specifications
#' defined in the template.
#'
#' @param meta a list with the metadata of the downloaded file.
#'
#' @details
#' This function reads the downloaded file according to the specifications
#' and schema defined in the template.
#' The schema is located in the `fields` field of the template and defines the
#' type of each column in the created dataset.
#'
#' The generated datasets are saved in a directory named after the
#' template and are located within the `db` directory, which is
#' inside the `cachedir` directory.
#' The datasets are saved in the Parquet format.
#' This way, it is possible to use datasets with the template
#' directories and perform queries using the `arrow` package.
#'
#' If an error occurs while processing a downloaded file, the file and its metadata are removed.
#'
#' @return This function returns a `data.frame` with the parsed file data.
#'
#' @seealso show_templates display_template
#' @seealso cachedir rb3.cachedir
#'
#' @examples
#' \dontrun{
#' meta <- download_marketdata("b3-cotahist-daily", refdate = as.Date("2024-04-05"))
#' read_marketdata(meta)
#' }
#' @export
read_marketdata <- function(meta) {
  filename <- meta$downloaded[[1]]
  template <- template_retrieve(meta$template)
  df <- template$read_file(template, filename)
  if (is.null(df)) {
    cli_alert_warning("File could not be read: {.file {filename}}")
    meta_clean(meta)
    return(invisible(NULL))
  }
  tag <- sapply(template$reader$partition, function(x) {
    x <- df[[x]] |>
      unique() |>
      na.omit() |>
      sort() |>
      format()
    x[1]
  })
  label <- paste0(tag, collapse = "_")
  db_folder <- template_db_folder(template)
  ds_file <- file.path(db_folder, str_glue("{label[1]}.parquet"))
  meta_add_processed_file(meta) <- ds_file
  meta_save(meta)
  tb <- arrow::arrow_table(df, schema = template_schema(template))
  arrow::write_parquet(tb, ds_file, compression = "gzip")
  invisible(meta)
}

fetch_marketdata <- function(template, ...) {
  df <- expand.grid(...)
  cli::cli_h1("Fetching market data for {.var {template}}")
  # ----
  pb <- cli::cli_progress_step("Downloading data", spinner = TRUE)
  ms <- purrr::pmap(df, function(...) {
    cli::cli_progress_update(id = pb)
    row <- list(...)
    m <- do.call(download_marketdata, c(template, row))
    if (is.null(m)) {
      msg <- paste(names(row), row, sep = " = ", collapse = ", ")
      cli::cli_alert_warning("No data downloaded for args {.val {msg}}")
    }
    m
  })
  cli::cli_process_done(id = pb)
  # ----
  pb <- cli::cli_progress_step("Reading data into DB", spinner = TRUE)
  purrr::map(ms, function(m) {
    cli::cli_progress_update(id = pb)
    if (!is.null(m)) {
      x <- suppressMessages(read_marketdata(m))
      if (is.null(x)) {
        row <- m$download_args
        msg <- paste(names(row), map(row, format), sep = " = ", collapse = ", ")
        cli::cli_alert_warning("Invalid file for args: {.val {msg}}")
      }
    }
    NULL
  })
  cli::cli_process_done(id = pb)
  cli::cli_alert_info("{length(ms)} files downloaded")
  invisible(NULL)
}

empty_file_error <- function(message) {
  structure(
    class = c("empty_file_error", "condition"),
    list(message = message, call = sys.call(-1))
  )
}
