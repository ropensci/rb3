registry_new <- function() {
  new.env()
}

registry_put <- function(obj, key, value) {
  if (!is.null(key)) {
    obj[[key]] <- value
  }
  invisible(NULL)
}

registry_get <- function(obj, key) {
  val <- try(base::get(key, obj), TRUE)
  if (is(val, "try-error")) NULL else val
}

registry_keys <- function(obj) {
  names(obj)
}