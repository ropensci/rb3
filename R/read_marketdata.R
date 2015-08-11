
#' read_marketdata
#' 
#' 
#' @export
read_marketdata <- function(filename, template) {
    content <- read(template, filename)
    format_data(template, content)
}

