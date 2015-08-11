

#' as.template
as.template <- function(x, ...) UseMethod('as.template', x)

#' 
as.template.character <- function(x, ...) {
    structure(...)
}

find_template <- function(filename=NULL, template=NULL) {
    
}