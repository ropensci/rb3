# No network: download_marketdata() is mocked and raw files are fake.

this_year <- as.integer(format(Sys.Date(), "%Y"))

fake_downloaded_meta <- function(template, year, mtime, ...) {
  meta <- template_meta_create_or_load(template, ..., year = year)
  f <- tempfile(fileext = ".gz")
  writeLines("x", f)
  Sys.setFileTime(f, mtime)
  meta_add_download(meta) <- f
  meta_set_downloaded(meta) <- TRUE
  meta
}

test_that("current year's file is outdated only when downloaded on an earlier day", {
  old <- fake_downloaded_meta("b3-cotahist-yearly", this_year, Sys.time() - 2 * 86400)
  withr::defer(meta_clean(old))
  expect_true(meta_is_outdated(old))

  Sys.setFileTime(old$downloaded[[1]], Sys.time())
  expect_false(meta_is_outdated(old))
})

test_that("past years and templates without refresh-current-year are never outdated", {
  past <- fake_downloaded_meta("b3-cotahist-yearly", this_year - 1, Sys.time() - 2 * 86400)
  withr::defer(meta_clean(past))
  expect_false(meta_is_outdated(past))

  daily <- template_meta_create_or_load("template-test-small-file", size = 7)
  withr::defer(meta_clean(daily))
  expect_false(meta_is_outdated(daily))
})

test_that("download_single_file downloads an outdated current-year file again", {
  calls <- 0
  local_mocked_bindings(download_marketdata = function(meta) {
    calls <<- calls + 1
    meta
  })
  old <- fake_downloaded_meta("b3-indexes-historical-data", this_year, Sys.time() - 2 * 86400, index = "IBOV")
  withr::defer(meta_clean(old))
  past <- fake_downloaded_meta("b3-cotahist-yearly", this_year - 1, Sys.time() - 2 * 86400)
  withr::defer(meta_clean(past))

  pb <- cli::cli_progress_bar(total = 2) # download_single_file() updates a progress bar
  download_single_file(old, pb = pb)
  expect_equal(calls, 1)
  download_single_file(past, pb = pb)
  expect_equal(calls, 1)
})

test_that("a download with the same content marks the cached file as fresh", {
  tpl <- template_retrieve("b3-cotahist-yearly")
  meta <- template_meta_create_or_load(tpl$id, year = 1900)
  withr::defer(meta_clean(meta))
  f <- tempfile(fileext = ".txt")
  writeLines("same content", f)
  meta <- process_downloaded_file(f, tpl, meta)
  Sys.setFileTime(meta$downloaded[[1]], Sys.time() - 2 * 86400)

  writeLines("same content", f) # the first call moved f into the cache
  expect_error(process_downloaded_file(f, tpl, meta), class = "error_download_file_exists")
  expect_equal(as.Date(file.mtime(meta$downloaded[[1]])), Sys.Date())
})
