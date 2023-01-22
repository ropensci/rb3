
fields <- function(...) {
  that <- list(...)
  class(that) <- "fields"
  that
}

as.data.frame.fields <- function(x, ...) {
  data.frame(
    `Field name` = fields_names(x),
    `Description` = fields_description(x),
    `Width` = fields_widths(x),
    `Type` = map_chr(fields_handlers(x), function(y) attr(y, "type")),
    row.names = seq_along(x),
    check.names = FALSE
  )
}

print.fields <- function(x, ...) {
  df <- as.data.frame(x)
  suppressWarnings(
    print(ascii(df, include.rownames = TRUE), type = "org")
  )
}

fields_names <- function(fields) {
  map_chr(fields, function(x) as.character(x))
}

fields_widths <- function(fields) {
  map_int(fields, function(x) as.integer(attr(x, "width")))
}

fields_description <- function(fields) {
  map_chr(fields, function(x) as.character(attr(x, "description")))
}

fields_handlers <- function(fields) {
  handlers <- lapply(fields, function(x) attr(x, "handler"))
  names(handlers) <- fields_names(fields)
  handlers
}

field <- function(name, description, ...) {
  if (missing(description)) {
    attr(name, "description") <- ""
    parms <- list(...)
  } else {
    if (is(description, "character")) {
      attr(name, "description") <- description
      parms <- list(...)
    } else {
      attr(name, "description") <- ""
      parms <- list(description, ...)
      warning(
        "description invalid type: ",
        paste(class(description), collapse = ", ")
      )
    }
  }

  classes <- lapply(parms, function(x) {
    if (is(x, "width")) {
      "width"
    } else if (is(x, "handler")) {
      "handler"
    } else {
      NULL
    }
  })

  if (any(classes == "width")) {
    attr(name, "width") <- parms[[which(classes == "width")[1]]]
  } else {
    attr(name, "width") <- 0
  }

  if (any(classes == "handler")) {
    attr(name, "handler") <- parms[[which(classes == "handler")[1]]]
  } else {
    attr(name, "handler") <- pass_thru_handler()
  }

  class(name) <- "field"
  name
}

print.parts <- function(x, ...) {
  nx <- names(x)
  for (ix in seq_along(nx)) {
    dx <- dim(x[[ix]])
    cat(sprintf(
      "Part %2d: %s [%d obs. of %d variables]", ix, nx[ix], dx[1],
      dx[2]
    ), "\n")
  }
}
