.onAttach <- function(libname, pkgname) {
  load_template_files()
  reg <- template_registry$get_instance()
  x <- length(registry_keys(reg))
  packageStartupMessage("rb3: ", x, " templates registered")
  load_builtin_calendars()
  rb3_bootstrap()
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
