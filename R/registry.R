create_registry <- function() {
  # Private instance variable
  instance <- NULL

  # Constructor function
  create <- function() {
    # Create a new object if no instance exists
    if (is.null(instance)) {
      new_instance <- list()
      attr(new_instance, "created_at") <- Sys.time()
      attr(new_instance, "data") <- list()
      attr(new_instance, "envir") <- environment(create)
      # Set class for S3 dispatch
      class(new_instance) <- "registry"
      # Store instance in enclosing environment
      instance <<- new_instance
    }
    instance
  }

  # Return the constructor
  structure(list(get_instance = create), class = "registry_class")
}

#' @exportS3Method base::print
print.registry_class <- function(x, ...) {
  x <- x$get_instance()
  print(x)
}

#' @exportS3Method base::print
print.registry <- function(x, ...) {
  .created <- attr(x, "created_at")
  cat("registry instance created at:", format(.created), "\n")
  .data <- attr(x, "data")
  cat("# elements", length(.data), "\n")
  invisible(x)
}

registry_get <- function(x, key, ...) {
  .data <- attr(x, "data")
  if (key %in% names(.data)) {
    .data[[key]]
  } else {
    stop(key, " not found in registry")
  }
}

registry_put <- function(x, key, value, ...) {
  .data <- attr(x, "data")
  .data[[key]] <- value
  attr(x, "data") <- .data
  attr(x, "envir")[["instance"]] <- x
  invisible(x)
}

registry_keys <- function(x, ...) {
  .data <- attr(x, "data")
  if (length(.data) == 0) {
    character(0)
  } else {
    names(.data)
  }
}

#' @export
`$.registry` <- function(x, name) {
  registry_get(x, name)
}

#' @export
`$<-.registry` <- function(x, name, value) {
  registry_put(x, name, value)
}

#' @export
`[[.registry` <- function(x, name) {
  registry_get(x, name)
}

#' @export
`[[<-.registry` <- function(x, name, value) {
  registry_put(x, name, value)
}

#' @exportS3Method base::names
names.registry <- function(x) {
  registry_keys(x)
}

#' @exportS3Method base::length
length.registry <- function(x) {
  length(attr(x, "data"))
}
