tag <- function(x) {
  class(x) <- c("character", "tag")
  x
}

width <- function(x) {
  x <- as.numeric(x)
  class(x) <- c("numeric", "width")
  x
}

# Create a handler with common attributes
create_handler <- function(handler_fn, type, ...) {
  attrs <- list(...)
  attrs$type <- type
  for (name in names(attrs)) {
    attr(handler_fn, name) <- attrs[[name]]
  }
  class(handler_fn) <- c("function", "handler")
  handler_fn
}

to_date_handler <- function(format = NULL) {
  if (is.null(format)) {
    format <- "%Y-%m-%d"
  }
  handler <- function(x) {
    as.Date(x, format = format)
  }
  create_handler(handler, "Date", format = format)
}

to_time_handler <- function(format = NULL) {
  if (is.null(format)) {
    format <- "%H:%M:%S"
  }
  handler <- function(x) {
    strptime(x, format = format)
  }
  create_handler(handler, "POSIXct", format = format)
}

to_factor_handler <- function(levels = NULL, labels = levels) {
  handler <- function(x) {
    if (is.null(levels)) {
      factor(x)
    } else {
      factor(x, levels = levels, labels = labels)
    }
  }
  create_handler(handler, "factor", levels = levels, labels = labels)
}

to_numeric_handler <- function(dec = 0, sign = "") {
  handler <- function(x) {
    if (inherits(dec, "character")) {
      dec <- get(dec, envir = parent.frame())
    }
    if (!sign %in% c("+", "-", "")) {
      sign <- get(sign, envir = parent.frame())
    }
    x <- paste0(sign, x)
    as.numeric(x) / (10^as.numeric(dec))
  }
  create_handler(handler, "numeric", dec = dec, sign = sign)
}

pass_thru_handler <- function() {
  create_handler(identity, "character")
}

to_strtime_handler <- function(format = NULL, tz = NULL) {
  if (is.null(format)) {
    format <- "%H%M%OS"
  }
  if (is.null(tz)) {
    tz <- "GMT"
  }
  handler <- function(x) {
    z <- stringr::str_pad(x, 9, pad = "0") |> 
      stringr::str_match("(\\d{6})(\\d{3})")
    t <- stringr::str_c(z[, 2], ".", z[, 3])
    strptime(t, format = format, tz = tz)
  }
  create_handler(handler, "strtime", format = format)
}
