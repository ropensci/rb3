
#' Converts B3 messy files to structured formats
#'
#' Convert B3 files to structured formats based on the template.
#'
#' @param filename a string containing a path for the file.
#' @param template a string with the template name.
#' @param parse_fields a logical indicating if the fields must be parsed.
#' @param format output format
#'
#' @return a string with the file path of generated file.
#'
#' @seealso read_marketdata
#'
#' @examples
#' \dontrun{
#' f <- system.file("extdata/Indic.txt", package = "rb3")
#' res <- convert_to(f, output_format = "csv")
#' res <- convert_to(f, output_format = "json")
#' }
#' @export
convert_to <- function(filename, template = NULL, parse_fields = TRUE,
                       format = "csv") {
  template <- .retrieve_template(filename, template)
  fname <- Filename(name = filename)
  df <- template$read_file(filename, parse_fields)
  new_filename <- fname$changeExt(format)
  if (format == "csv") {
    write.table(df,
      file = new_filename, sep = ",", dec = ".",
      row.names = FALSE
    )
  } else if (format == "json") {
    writeLines(jsonlite::toJSON(df), new_filename)
  }
  new_filename
}