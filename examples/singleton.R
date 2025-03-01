# Singleton implementation using S3 objects
create_singleton <- function() {
  # Private instance variable
  instance <- NULL

  # Constructor function
  create <- function() {
    # Create a new object if no instance exists
    if (is.null(instance)) {
      new_instance <- list(
        data = list(),
        created_at = Sys.time()
      )
      # Set class for S3 dispatch
      class(new_instance) <- "Singleton"
      # Store instance in enclosing environment
      instance <<- new_instance
      message("New Singleton instance created")
    } else {
      message("Returning existing Singleton instance")
    }
    instance
  }

  # Return the constructor
  list(get_instance = create)
}

# S3 methods for the Singleton class
print.Singleton <- function(x, ...) {
  cat("Singleton instance created at:", format(x$created_at), "\n")
  cat("Data:", if (is.null(x$data)) "NULL" else as.character(x$data), "\n")
}

get_data <- function(x, ...) {
  UseMethod("get_data")
}

get_data.Singleton <- function(x, ...) {
  x$data
}

set_data <- function(x, value, ...) {
  UseMethod("set_data")
}

set_data.Singleton <- function(x, key, value, ...) {
  x$data[[key]] <- value
  # Since we're modifying the original object by reference,
  # we don't need to return it but we do so for chaining
  invisible(x)
}

# Usage example
singleton <- create_singleton()
instance1 <- singleton$get_instance()
set_data(instance1, "name", "Hello, world!")
print(instance1)

# Get another reference - should be the same instance
instance2 <- singleton$get_instance()
print(instance2) # Should show the same data