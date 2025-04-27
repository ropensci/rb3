type <- function(name, ...) {
  # Check if the name is a valid type
  if (!name %in% c("date", "time", "datetime", "numeric", "factor", "number", "integer", "character", "logical")) {
    cli::cli_abort("Invalid type name: {.emph {name}}")
  }

  # Create a new type object
  # Create the base type object with just the name
  type_obj <- name
  # Set the default attributes for the type
  if (name == "date") {
    attr(type_obj, "format") <- "%Y-%m-%d"
  } else if (name == "time") {
    attr(type_obj, "format") <- "%H:%M:%S"
  } else if (name == "datetime") {
    attr(type_obj, "format") <- "%Y-%m-%d %H:%M:%S"
  } else if (name == "numeric") {
    attr(type_obj, "dec") <- 0
    attr(type_obj, "sign") <- "+"
  } else if (name == "number") {
    attr(type_obj, "dec") <- 0
    attr(type_obj, "sign") <- "+"
  } else if (name == "integer") {
    # No default attributes for integer
  } else if (name == "character") {
    # No default attributes for character
  } else if (name == "logical") {
    # No default attributes for logical
  }
  # Add the arguments from ... as attributes
  dots <- list(...)
  if (length(dots) > 0) {
    for (i in seq_along(dots)) {
      if (names(dots)[i] != "") {
        attr(type_obj, names(dots)[i]) <- dots[[i]]
      }
    }
  }

  # Assign the class to the object
  class(type_obj) <- c("type", name)

  return(type_obj)
}

# create get/set methods with $ for each type
#' @export
`$.type` <- function(x, name) {
  attr(x, name)
}
#' @export
`$<-.type` <- function(x, name, value) {
  attr(x, name) <- value
  x
}

type_parse <- function(x) {
  # create regex to match the type and its parameters
  regex <- "^(date|time|datetime|numeric|factor|number|integer|character|logical)\\s*(?:\\(([^)]*)\\))?$"
  # match the type and its parameters
  res <- stringr::str_match_all(x, regex)[[1]]
  # check if the type is valid
  if (dim(res)[1] == 0) {
    cli::cli_abort("Invalid type: {.emph {x}}")
  }
  name <- res[1, 2]
  param_str <- res[1, 3]
  # check if the parameter string is empty
  if (is.na(param_str)) {
    param_str <- ""
  }
  param_pairs <- stringr::str_split(param_str, ",\\s*")[[1]]
  param_regex <- "\\s*([^=,\\s]+)\\s*(?:=\\s*([^,]+))?\\s*(?:,|$)"
  param_list <- lapply(param_pairs, function(p) {
    kv <- stringr::str_match_all(p, param_regex)[[1]]
    if (dim(kv)[1] == 0) {
      return(NULL)
    }
    k <- kv[1, 2]
    v <- stringr::str_replace_all(kv[1, 3], "^['\"]|['\"]$", "")
    v <- readr::parse_guess(v)
    list(name = k, value = v)
  })

  params <- stats::setNames(
    lapply(param_list, function(x) x$value),
    sapply(param_list, function(x) x$name)
  )

  # Create and return a new type object
  rlang::exec(type, name, !!!params)
}

# x <- c(
#   "date",
#   "date('%Y-%m-%d')",
#   "integer",
#   "numeric(dec=2)",
#   "number",
#   "number()",
#   "numeric(dec = 2, sign = '+')"
# )
# regex <- "^(date|time|datetime|numeric|factor|number|integer|character|logical)\\s*(?:\\(([^)]*)\\))?$"
# stringr::str_match_all("date", regex)
# stringr::str_match_all("date(format = '%Y')", regex)
# stringr::str_match_all("numeric(dec = 2, sign = '+')", regex)
# stringr::str_match_all(x, regex)
# stringr::str_match_all("xxx", regex)

# "date|time|datetime|numeric|factor|number|integer|character|logical"

# stringr::str_match_all("xxx", "^(\\s)$")[[1]] |> dim()
# stringr::str_detect("xxx", "^(\\s)$")

# regex <- "\\s*([^=,\\s]+)\\s*(?:=\\s*([^,]+))?\\s*(?:,|$)"
# stringr::str_match_all("format = '%Y'", regex)
# stringr::str_match_all("'%Y'", regex)
