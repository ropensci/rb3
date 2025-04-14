local_cachedir <- file.path(tempdir(), "rb3-cache")
withr::defer(unlink(local_cachedir, recursive = TRUE), teardown_env())

op <- options(
  rb3.cachedir = local_cachedir,
  rb3.silent = TRUE,
  cli.default_handler = function(...) { }
)

suppressMessages(rb3_bootstrap())

files <- list.files(test_path("testdata"), full.names = TRUE, pattern = "\\.yaml")
for (file in files) {
  load_template_from_file(file)
}
reg <- template_registry$get_instance()
msg <- cli::format_message("{cli::col_blue('\u2139')} {.pkg rb3}-tests: {length(reg)} templates registered")
message(msg)

withr::defer(
  {
    options(op)
    suppressMessages(rb3_bootstrap())
  },
  teardown_env()
)
