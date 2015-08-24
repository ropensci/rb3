
#' @export
read_marketdata <- function(filename, template=NULL, format=TRUE) {
  template <- .retrieve_template(filename, template)
  template$read_file(filename, format)
}
