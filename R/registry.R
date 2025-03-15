create_registry <- function() {
  # Private instance variable
  instance <- NULL

  # Constructor function
  create <- function() {
    # Create a new object if no instance exists
    if (is.null(instance)) {
      new_instance <- list(
        data = list(),
        created_at = Sys.time(),
        .p = environment(create)
      )
      # Set class for S3 dispatch
      class(new_instance) <- "registry"
      # Store instance in enclosing environment
      instance <<- new_instance
    }
    instance
  }

  # Return the constructor
  list(get_instance = create)
}

#' @exportS3Method base::print
print.registry <- function(x, ...) {
  cat("registry instance created at:", format(x$created_at), "\n")
  cat("# elements", length(x$data), "\n")
  invisible(x)
}

registry_get <- function(x, key, ...) {
  if (exists(key, x$data)) {
    x$data[[key]]
  } else {
    stop(key, " not found in registry")
  }
}

registry_put <- function(x, key, value, ...) {
  x$data[[key]] <- value
  x$.p[["instance"]] <- x
  invisible(x)
}

#' @export
`[[.registry` <- function(x, key, ...) {
  registry_get(x, key)
}

#' @export
`[[<-.registry` <- function(x, key, value, ...) {
  registry_put(x, key, value)
}

#' @exportS3Method base::names
names.registry <- function(x, ...) {
  registry_keys(x)
}

registry_keys <- function(x, ...) {
  if (length(x$data) == 0) {
    character(0)
  } else {
    names(x$data)
  }
}
