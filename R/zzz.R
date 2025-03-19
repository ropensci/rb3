.onAttach <- function(libname, pkgname) {
  load_template_files()
  reg <- template_registry$get_instance()
  msg <- cli::format_message("{cli::col_blue('\u2139')} {.pkg rb3}: {length(reg)} templates registered")
  packageStartupMessage(msg)

  load_builtin_calendars()

  suppressMessages(rb3_bootstrap())
  reg <- rb3_registry$get_instance()
  msg <- cli::format_message("{cli::col_blue('\u2139')} {.pkg rb3} cache folder: {.file {reg$rb3_folder}}")
  packageStartupMessage(msg)
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
