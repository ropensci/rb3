
#' @export
convert_to <- function(filename, template = NULL, format = TRUE, output_format = "csv") {
  template <- .retrieve_template(filename, template)
  fname <- Filename(name = filename)
  df <- template$read_file(filename, format)
  new_filename <- fname$changeExt(output_format)
  if (output_format == "csv") {
    write.table(df, file = new_filename, sep = ",", dec = ".", row.names = FALSE)
  } else if (output_format == "json") {
    writeLines(jsonlite::toJSON(df), new_filename)
  }
  new_filename
}