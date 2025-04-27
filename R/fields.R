fields <- function(...) {
  that <- list(...)
  class(that) <- "fields"
  that
}

new_field <- function(x) {
  tag_ <- if (!is.null(x$tag)) tag(x$tag)
  width_ <- if (!is.null(x$width)) width(x$width)
  type_ <- if (!is.null(x$type)) type_parse(x$type) else NULL
  x$description <- if (is.null(x$description)) "" else x$description
  if (is.null(type_)) {
    col_ <- readr::col_character()
    arrow_type_ <- arrow::string()
  } else if (type_ == "number") {
    col_ <- readr::col_number()
    arrow_type_ <- arrow::float64()
  } else if (type_ == "numeric") {
    col_ <- readr::col_double()
    arrow_type_ <- arrow::float64()
  } else if (type_ == "integer") {
    col_ <- readr::col_integer()
    arrow_type_ <- arrow::int64()
  # } else if (type_ == "factor") {
  #   col_ <- readr::col_factor(x$handler$levels, x$handler$labels)
  #   arrow_type_ <- arrow::string()
  } else if (type_ == "date") {
    col_ <- readr::col_date(format = type_$format)
    arrow_type_ <- arrow::date32()
  } else if (type_ == "datetime") {
    col_ <- readr::col_datetime(format = type_$format)
    arrow_type_ <- arrow::timestamp()
  } else if (type_ == "time") {
    col_ <- readr::col_time(format = type_$format)
    arrow_type_ <- arrow::time64()
  } else if (type_ == "character") {
    col_ <- readr::col_character()
    arrow_type_ <- arrow::string()
  } else {
    col_ <- readr::col_character()
    arrow_type_ <- arrow::string()
  }
  field(x$name, x$description, width_, tag_, col_, arrow_type_, type_)
}


#' @exportS3Method base::as.data.frame
as.data.frame.fields <- function(x, ...) {
  data.frame(
    `Field name` = fields_names(x),
    `Description` = fields_description(x),
    `Width` = fields_widths(x),
    `Type` = vapply(fields_types(x), function(y) as.character(y), character(1)),
    row.names = seq_along(x),
    check.names = FALSE
  )
}

#' @exportS3Method base::print
print.fields <- function(x, ...) {
  ulid <- cli::cli_ul()
  names <- fields_names(x)
  types <- vapply(fields_types(x), function(y) as.character(y), character(1))
  desc <- fields_description(x)
  for (ix in seq_along(names)) {
    cli::cli_li("{.strong {names[ix]}} ({types[ix]}): {desc[ix]}")
  }
  cli::cli_end(ulid)
  invisible(x)
}

# Extract field attribute with proper type conversion
extract_field_attr <- function(fields, attr_name, convert_fn = NULL) {
  if (is.null(convert_fn)) {
    convert_fn <- as.character
  }
  
  result <- vapply(
    fields, 
    function(x) {
      if (attr_name == "self") {
        convert_fn(x)
      } else {
        convert_fn(attr(x, attr_name))
      }
    },
    convert_fn(NA)
  )
  
  return(result)
}

fields_names <- function(fields) {
  extract_field_attr(fields, "self", as.character)
}

fields_widths <- function(fields) {
  extract_field_attr(fields, "width", as.integer)
}

fields_description <- function(fields) {
  extract_field_attr(fields, "description", as.character)
}

fields_types <- function(fields) {
  extract_field_attr(fields, "type", as.character)
}

# Generic function to extract field attributes and name them
extract_named_attributes <- function(fields, attr_name) {
  handlers <- lapply(fields, function(x) attr(x, attr_name))
  names(handlers) <- fields_names(fields)
  handlers
}

fields_handlers <- function(fields) {
  extract_named_attributes(fields, "handler")
}

fields_cols <- function(fields) {
  extract_named_attributes(fields, "col")
}

fields_arrow_types <- function(fields) {
  extract_named_attributes(fields, "arrow")
}

fields_tags <- function(fields) {
  extract_named_attributes(fields, "tag")
}

field <- function(name, description, ...) {
  # Handle description parameter
  if (missing(description)) {
    attr(name, "description") <- ""
    parms <- list(...)
  } else {
    if (inherits(description, "character")) {
      attr(name, "description") <- description
      parms <- list(...)
    } else {
      attr(name, "description") <- ""
      parms <- list(description, ...)
      cli::cli_warn("description invalid type: {paste(class(description), collapse = ', ')}")
    }
  }

  # Identify parameter classes
  classes <- lapply(parms, function(x) {
    if (inherits(x, "width")) {
      "width"
    } else if (inherits(x, "tag")) {
      "tag"
    } else if (inherits(x, "type")) {
      "type"
    } else if (inherits(x, "collector")) {
      "col"
    } else if (inherits(x, "DataType") && inherits(x, "ArrowObject")) {
      "arrow"
    } else {
      NULL
    }
  })

  # Set attributes based on parameter classes
  attributes_to_set <- list(
    width = list(default = 0, class = "width"),
    tag = list(default = NULL, class = "tag"),
    type = list(default = type("character"), class = "type"),
    col = list(default = readr::col_character(), class = "col"),
    arrow = list(default = arrow::string(), class = "arrow")
  )
  
  for (attr_name in names(attributes_to_set)) {
    attr_config <- attributes_to_set[[attr_name]]
    attr_class <- attr_config$class
    
    if (any(classes == attr_class)) {
      attr(name, attr_name) <- parms[[which(classes == attr_class)[1]]]
    } else if (!is.null(attr_config$default)) {
      attr(name, attr_name) <- attr_config$default
    }
  }

  class(name) <- "field"
  name
}

#' @exportS3Method base::print
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
