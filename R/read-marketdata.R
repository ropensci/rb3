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
#' @param cache_folder location of cache folder (default = cachedir())
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
read_marketdata <- function(meta, cache_folder = cachedir()) {
  filename <- meta$downloaded
  if (file.size(filename) <= 2) {
    alert("warning", str_glue("File is empty: {filename}"))
    clean_meta(meta, cache_folder)
    return(NULL)
  }
  template <- template_retrieve(meta$template)
  db_folder <- file.path(cache_folder, "db", template$id)
  if (!dir.exists(db_folder)) {
    dir.create(db_folder, recursive = TRUE)
  }
  df <- template$read_file(template, filename, TRUE)
  if (is.null(df)) {
    alert("warning", str_glue("File could not be read: {filename}"))
    clean_meta(meta, cache_folder)
    return(NULL)
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
  ds_file <- file.path(db_folder, str_glue("{label[1]}.parquet"))
  tb <- arrow::arrow_table(df, schema = template_schema(template))
  arrow::write_parquet(df, ds_file, compression = "gzip")
  df
}

clean_meta <- function(meta, cache_folder) {
  alert("info", str_glue("Removing file {meta$downloaded}"))
  unlink(meta$downloaded)
  meta_file <- file.path(cache_folder, "meta", str_glue("{meta$download_checksum}.json"))
  alert("info", str_glue("Removing meta {meta_file}"))
  unlink(meta_file)
}

empty_file_error <- function(message) {
  structure(
    class = c("empty_file_error", "condition"),
    list(message = message, call = sys.call(-1))
  )
}
