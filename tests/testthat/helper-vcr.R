# vcr is only suggested: tests that need cassettes call skip_if_not_installed("vcr")
if (requireNamespace("vcr", quietly = TRUE)) {
  library("vcr") # *Required* as vcr is set up on loading
  invisible(vcr::vcr_configure(
    dir = vcr::vcr_test_path("fixtures")
  ))
}
