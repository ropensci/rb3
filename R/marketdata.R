#' @title Read files from Brazilian Financial Market
#' 
#' @description 
#' Read the many files used in Brazilian Financial Market and 
#' convert them into useful formats and data structures.
#' 
#' @name marketdataBR
#' 
#' @docType package
#' 
#' @import proto
#' @import stringr
NULL

.retrieve_template <- function(filename, template) {
  template <- if (is.null(template))
    MarketData$retrieve_template( basename(filename) )
  else
    MarketData$retrieve_template(template)
  if (is.null(template))
    stop('Unknown template.')
  template
}

registry <- proto::proto(expr={
  ..container <- list()
  put <- function(., key, value) {
    .$..container[[key]] <- value
    invisible(NULL)
  }

  get <- function(., key) {
    val <- try(base::get(key, .$..container), TRUE)
    if (is(val, 'try-error')) NULL else val
  }
})

MarketData <- proto::proto(expr={
  read_file <- function(., filename, format=TRUE) {
    .$..read_file(filename, format)
  }

  ..registry <- registry

  register <- function(., .class) {
    filename <- try(.class$filename)
    if (! is(filename, 'try-error'))
      .$..registry$put(filename, .class)
    .$..registry$put(.class$name, .class)
  }

  retrieve_template <- function(., key) .$..registry$get(key)
  
  format_data <- function(., df) identity(df)
})

MarketDataFWF <- MarketData$proto(expr={
  read_file <- function(., filename, format=TRUE) {
    df <- read_fwf(filename, .$widths, colnames=.$colnames)
    if (format) .$format_data(df) else df
  }
})

