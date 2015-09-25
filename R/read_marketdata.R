
#' @export
read_marketdata <- function(filename, template=NULL, parse_fields=TRUE) {
  template <- .retrieve_template(filename, template)
  template$read_file(filename, parse_fields)
}
