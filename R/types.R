#' Type system for data fields
#' 
#' Defines and manages data types with their attributes for parsing and validating data

# Define valid types with their default attributes
VALID_TYPES <- list(
  date = list(format = "%Y-%m-%d"),
  time = list(format = "%H:%M:%S"),
  datetime = list(format = "%Y-%m-%d %H:%M:%S"),
  numeric = list(dec = 0, sign = "+"),
  number = list(dec = 0, sign = "+"),
  integer = list(),
  character = list(),
  logical = list()
)

#' Create a new type object
#'
#' @param name The type name
#' @param ... Additional attributes for the type
#' 
#' @return A type object with specified attributes
type <- function(name, ...) {
  if (!name %in% names(VALID_TYPES)) {
    cli::cli_abort("Invalid type name: {.emph {name}}")
  }
  
  # Create the base type object
  type_obj <- name
  
  # Apply default attributes
  defaults <- VALID_TYPES[[name]]
  for (attr_name in names(defaults)) {
    attr(type_obj, attr_name) <- defaults[[attr_name]]
  }
  
  # Apply custom attributes from ...
  dots <- list(...)
  for (attr_name in names(dots)) {
    attr(type_obj, attr_name) <- dots[[attr_name]]
  }
  
  # Set the class
  class(type_obj) <- c("type", name)
  
  return(type_obj)
}

#' Access type attributes
#' @export
`$.type` <- function(x, name) {
  attr(x, name)
}

#' Set type attributes
#' @export
`$<-.type` <- function(x, name, value) {
  attr(x, name) <- value
  x
}

#' Parse a type string into a type object
#'
#' @param x A string describing a type, e.g., "date", "numeric(dec=2)"
#' @return A type object
type_parse <- function(x) {
  # Match the type name and optional parameters
  result <- parse_type_string(x)
  
  # Extract type name and parameters
  type_name <- result$name
  params <- result$params
  
  # Create and return the type object
  do.call(type, c(list(type_name), params))
}

#' Helper function to parse a type string
#'
#' @param type_str A string describing a type
#' @return A list with name and params components
parse_type_string <- function(type_str) {
  # Define the regex pattern for type matching
  type_pattern <- paste0(
    "^(", paste(names(VALID_TYPES), collapse = "|"), ")",
    "\\s*(?:\\(([^)]*)\\))?$"
  )

  # Match the type and its parameters
  matches <- stringr::str_match(type_str, type_pattern)

  if (is.na(matches[1])) {
    cli::cli_abort("Invalid type string: {.emph {type_str}}")
  }

  # Extract type name and parameter string
  type_name <- matches[2]
  param_str <- matches[3]

  # Parse parameters if present
  params <- list()
  if (!is.na(param_str) && nchar(param_str) > 0) {
    params <- parse_type_params(param_str)
  }

  return(list(name = type_name, params = params))
}

#' Create a collector based on the type
#'
#' @param type A type object
#'
#' @return A collector function for the specified type
type_collector <- function(type) {
  # Get the type name
  type_name <- class(type)[2]

  # Create a collector based on the type
  switch(type_name,
    date = readr::col_date(format = attr(type, "format")),
    time = readr::col_time(format = attr(type, "format")),
    datetime = readr::col_datetime(format = attr(type, "format")),
    numeric = readr::col_double(),
    number = readr::col_number(),
    integer = readr::col_integer(),
    character = readr::col_character(),
    logical = readr::col_logical(),
    cli::cli_abort("Unsupported type: {.emph {type_name}}")
  )
}

# create a function that return an arrow scalar according to the type object
#' @param type A type object
#' @return An arrow scalar for the specified type
type_arrow_scalar <- function(type) {
  # Get the type name
  type_name <- class(type)[2]

  # Create an arrow scalar based on the type
  switch(type_name,
    date = arrow::date32(),
    time = arrow::time64(),
    datetime = arrow::timestamp(),
    numeric = arrow::float64(),
    number = arrow::float64(),
    integer = arrow::int64(),
    character = arrow::string(),
    logical = arrow::boolean(),
    cli::cli_abort("Unsupported type: {.emph {type_name}}")
  )
}

#' Create a post parse handler based on the type
#'
#' @param type A type object
#'
#' @return A function that executes the post parse handling
type_post_parse_handler <- function(type) {
  # Get the type name
  type_name <- class(type)[2]

  # Create a collector based on the type
  switch(type_name,
    date = pass_thru_handler(type),
    time = pass_thru_handler(type),
    datetime = pass_thru_handler(type),
    numeric = numeric_handler(type),
    number = pass_thru_handler(type),
    integer = pass_thru_handler(type),
    character = pass_thru_handler(type),
    logical = pass_thru_handler(type),
    cli::cli_abort("Unsupported type: {.emph {type_name}}")
  )
}

numeric_handler <- function(type) {
  sign <- if (type$sign == "-") -1 else 1
  dec <- type$dec
  function(x) {
    x <- paste0(sign, x)
    sign * x / (10^dec)
  }
}

pass_thru_handler <- function(type) {
  identity
}

#' Helper function to parse type parameters
#'
#' @param param_str A string containing parameters
#' @return A named list of parameter values
parse_type_params <- function(param_str) {
  # Split the parameter string by commas
  param_pairs <- stringr::str_split(param_str, ",\\s*")[[1]]
  
  # Parse each parameter pair
  param_pattern <- "\\s*([^=,\\s]+)\\s*(?:=\\s*([^,]+))?\\s*"
  
  params <- list()
  for (pair in param_pairs) {
    if (nchar(trimws(pair)) == 0) next
    
    # Match parameter name and value
    kv_match <- stringr::str_match(pair, param_pattern)
    
    if (!is.na(kv_match[1])) {
      param_name <- kv_match[2]
      param_value <- kv_match[3]
      
      # Clean up the value (remove quotes)
      if (!is.na(param_value)) {
        param_value <- stringr::str_replace_all(param_value, "^['\"]|['\"]$", "")
        param_value <- readr::parse_guess(param_value)
      }
      
      params[[param_name]] <- param_value
    }
  }
  
  return(params)
}

#' Validate if a string is a valid type
#'
#' @param type_str A string to check
#' @return TRUE if valid, FALSE otherwise
#' @export
is_valid_type <- function(type_str) {
  tryCatch({
    type_parse(type_str)
    TRUE
  }, error = function(e) {
    FALSE
  })
}
