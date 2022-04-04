
#' @export
width <- function(x) {
  x <- as.numeric(x)
  class(x) <- c("numeric", "width")
  x
}

#' @export
to_date <- function(format = NULL) {
  if (is.null(format)) {
    format <- "%Y-%m-%d"
  }
  handler <- function(x) {
    as.Date(x, format = format)
  }
  attr(handler, "type") <- "Date"
  class(handler) <- c("function", "handler")
  handler
}

#' @export
to_time <- function(format = NULL) {
  if (is.null(format)) {
    format <- "%H:%M:%S"
  }
  handler <- function(x) {
    strptime(x, format = format)
  }
  attr(handler, "type") <- "POSIXct"
  class(handler) <- c("function", "handler")
  handler
}

#' @export
to_factor <- function(levels = NULL, labels = levels) {
  handler <- function(x) {
    if (is.null(levels)) {
      factor(x)
    } else {
      factor(x, levels = levels, labels = labels)
    }
  }
  attr(handler, "type") <- "factor"
  class(handler) <- c("function", "handler")
  handler
}

#' @export
to_numeric <- function(dec = 0, sign = "") {
  handler <- function(x) {
    if (is(dec, "character")) {
      dec <- get(dec, envir = parent.frame())
    }
    if (!sign %in% c("+", "-", "")) {
      sign <- get(sign, envir = parent.frame())
    }
    x <- paste0(sign, x)
    as.numeric(x) / (10^as.numeric(dec))
  }
  attr(handler, "type") <- "numeric"
  class(handler) <- c("function", "handler")
  handler
}

#' @export
pass_thru_handler <- function() {
  handler <- identity
  attr(handler, "type") <- "character"
  class(handler) <- c("function", "handler")
  handler
}