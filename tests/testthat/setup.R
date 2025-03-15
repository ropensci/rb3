local_cachedir <- file.path(tempdir(), "rb3-cache")
withr::defer(unlink(local_cachedir, recursive = TRUE), teardown_env())

op <- options(
  rb3.cachedir = local_cachedir,
  rb3.silent = TRUE,
  cli.default_handler = function(...) { }
)

suppressMessages(rb3_bootstrap())

withr::defer(
  {
    options(op)
    suppressMessages(rb3_bootstrap())
  },
  teardown_env()
)
