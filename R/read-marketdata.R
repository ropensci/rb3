#' Read and parses files delivered by B3
#'
#' B3, and previously BMF&Bovespa, used to deliver many files with a diverse
#' set of valuable data and informations that can be used to study of can
#' be called of marketdata.
#' There are files with informations about futures, option, interest
#' rates, currency rates, bonds and many other subjects.
#'
#' @param filename a string containing a path for the file.
#' @param template a string with the template name.
#' @param parse_fields a logical indicating if the fields must be parsed.
#' @param do_cache Whether to use cache or not (default = TRUE)
#'
#' The function `show_templates` can be used to view the available templates.
#'
#' @return `data.frame` of a list of `data.frame` containing data parsed from
#' files.
#'
#' @seealso show_templates display_template
#'
#' @examples
#' \dontrun{
#' path <- "Indic.txt"
#' df <- read_marketdata(path, template = "Indic")
#' path <- "PUWEB.TXT"
#' df <- read_marketdata(path, template = "PUWEB")
#' }
#' @export
read_marketdata <- function(meta, cache_folder = cachedir()) {
  filename <- meta$downloaded
  if (file.size(filename) <= 2) {
    msg <- str_glue("File is empty: {b}", b = filename)
    stop(empty_file_error(msg))
  }
  template <- template_retrieve(meta$template)
  db_folder <- file.path(cache_folder, "db", template$id)
  df <- template$read_file(template, filename, TRUE)
  label <- df[[template$reader$partition]] |> unique() |> na.omit() |> sort() |> format()
  ds_file <- file.path(db_folder, str_glue("{label[1]}.parquet"))
  tb <- arrow::arrow_table(df, schema = template_schema(template))
  arrow::write_dataset(df, ds_file)
  df
}

empty_file_error <- function(message) {
  structure(
    class = c("empty_file_error", "condition"),
    list(message = message, call = sys.call(-1))
  )
}
