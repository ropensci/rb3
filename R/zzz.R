.onAttach <- function(libname, pkgname) {
  load_template_files()
  reg <- get_template_registry()
  message("rb3: ", length(registry_keys(reg)), " templates registered")
  load_builtin_calendars()
}

.onLoad <- function(libname, pkgname) {
  op <- options()
  op_rb3 <- list(
    rb3.cachedir = NULL
  )
  toset <- !(names(op_rb3) %in% names(op))
  if (any(toset)) options(op_rb3[toset])

  invisible()
}
