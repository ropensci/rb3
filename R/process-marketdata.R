#' Process previously downloaded market data
#'
#' This function processes market data that has been previously downloaded
#' by loading the metadata and reading the data into the database.
#'
#' @param template A character string specifying the market data template to use
#' @param ... Named arguments that will be expanded into a grid of all combinations
#'   to process data for
#'
#' @details
#' This function is primarily used internally to process already downloaded data,
#' without re-downloading it. It's useful for reprocessing data after making changes
#' to the template or data processing pipeline.
#'
#' @examples
#' \dontrun{
#' # Process previously downloaded data
#' process_marketdata("b3-cotahist-yearly", year = 2020:2024)
#' }
#'
#' @noRd 
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
