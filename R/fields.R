# ============================================================================
# Field Creation and Management
# ============================================================================

#' Create a collection of fields
#'
#' @param ... Field objects to group together
#' @return A list of fields with class "fields"
fields <- function(...) {
  that <- list(...)
  class(that) <- "fields"
  that
}

#' Create a new field from specifications
#'
#' @param x A list containing field specifications
#' @return A field object with appropriate attributes
new_field <- function(x) {
  tag_ <- if (!is.null(x$tag)) tag(x$tag)
  width_ <- if (!is.null(x$width)) width(x$width)
  type_ <- if (!is.null(x$type)) type_parse(x$type) else NULL
  x$description <- if (is.null(x$description)) "" else x$description
  field(x$name, x$description, width_, tag_, type_)
}

#' Create a field object with attributes
#'
#' @param name Name of the field
#' @param description Description of the field
#' @param ... Additional parameters (width, tag, type, col, arrow)
#' @return A field object
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
      "collector"
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
    type = list(default = type("character"), class = "type")
  )
  
  for (attr_name in names(attributes_to_set)) {
    attr_config <- attributes_to_set[[attr_name]]
    attr_class <- attr_config$class
    
    match_idx <- which(classes == attr_class)
    if (length(match_idx) > 0) {
      attr(name, attr_name) <- parms[[match_idx[1]]]
    } else if (!is.null(attr_config$default)) {
      attr(name, attr_name) <- attr_config$default
    }
  }

  attr(name, "collector") <- type_collector(attr(name, "type"))
  attr(name, "arrow") <- type_arrow_scalar(attr(name, "type"))

  class(name) <- "field"
  name
}

# ============================================================================
# Field Attribute Extraction
# ============================================================================

#' Extract field attribute with proper type conversion
#' 
#' @param fields A fields object
#' @param attr_name Attribute name to extract
#' @param convert_fn Function to convert the attribute value
#' @return Vector of attribute values
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

#' Extract field names
fields_names <- function(fields) {
  extract_field_attr(fields, "self", as.character)
}

#' Extract field widths
fields_widths <- function(fields) {
  extract_field_attr(fields, "width", as.integer)
}

#' Extract field descriptions
fields_description <- function(fields) {
  extract_field_attr(fields, "description", as.character)
}

#' Extract field types
fields_types <- function(fields) {
  extract_field_attr(fields, "type", as.character)
}

#' Generic function to extract field attributes and name them
#' 
#' @param fields A fields object
#' @param attr_name Attribute name to extract
#' @return Named list of attribute values
extract_named_attributes <- function(fields, attr_name) {
  handlers <- lapply(fields, function(x) attr(x, attr_name))
  names(handlers) <- fields_names(fields)
  handlers
}

#' Extract field handlers
fields_handlers <- function(fields) {
  extract_named_attributes(fields, "handler")
}

#' Extract field column specifications
fields_collectors <- function(fields) {
  extract_named_attributes(fields, "collector")
}

#' Extract field arrow types
fields_arrow_types <- function(fields) {
  extract_named_attributes(fields, "arrow")
}

#' Extract field tags
fields_tags <- function(fields) {
  extract_named_attributes(fields, "tag")
}

# ============================================================================
# Display Methods
# ============================================================================

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
