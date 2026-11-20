# No network: download_marketdata() is mocked and raw files are fake.

this_year <- as.integer(format(Sys.Date(), "%Y"))

fake_downloaded_meta <- function(template, mtime, ...) {
  meta <- template_meta_create_or_load(template, ...)
  f <- tempfile(fileext = ".gz")
  writeLines("x", f)
  Sys.setFileTime(f, mtime)
  meta_add_download(meta) <- f
  meta_set_downloaded(meta) <- TRUE
  meta
}

test_that("current year's file is outdated only when downloaded on an earlier day", {
  old <- fake_downloaded_meta("b3-cotahist-yearly", Sys.time() - 2 * 86400, year = this_year)
  withr::defer(meta_clean(old))
  expect_true(meta_is_outdated(old))

  Sys.setFileTime(old$downloaded[[1]], Sys.time())
  expect_false(meta_is_outdated(old))
})

test_that("past years and templates without refresh-current-year are never outdated", {
  past <- fake_downloaded_meta("b3-cotahist-yearly", Sys.time() - 2 * 86400, year = this_year - 1)
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
  old <- fake_downloaded_meta("b3-indexes-historical-data", Sys.time() - 2 * 86400, index = "IBOV", year = this_year)
  withr::defer(meta_clean(old))
  past <- fake_downloaded_meta("b3-cotahist-yearly", Sys.time() - 2 * 86400, year = this_year - 1)
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

# A file read without usable data: is_processed = TRUE, is_valid = FALSE
fake_invalid_meta <- function(refdate, downloaded_on) {
  meta <- fake_downloaded_meta("b3-futures-settlement-prices", as.POSIXct(downloaded_on) + 12 * 3600,
    refdate = as.Date(refdate)
  )
  meta_set_processed(meta) <- TRUE
  meta_set_valid(meta) <- FALSE
  meta
}

test_that("an invalid file downloaded soon after its refdate is downloaded again", {
  same_day <- fake_invalid_meta("2026-09-14", "2026-09-14")
  withr::defer(meta_clean(same_day))
  expect_true(meta_is_outdated(same_day))

  six_days <- fake_invalid_meta("2026-09-15", "2026-09-21")
  withr::defer(meta_clean(six_days))
  expect_true(meta_is_outdated(six_days))
})

test_that("an invalid file downloaded long after its refdate is final", {
  late <- fake_invalid_meta("2026-09-16", "2026-09-23")
  withr::defer(meta_clean(late))
  expect_false(meta_is_outdated(late))

  # a retry with the same content touches the file: the meta stops being retried
  Sys.setFileTime(late$downloaded[[1]], Sys.time())
  expect_false(meta_is_outdated(late))
})

test_that("valid files and files not yet read are not downloaded again", {
  valid <- fake_invalid_meta("2026-09-17", "2026-09-17")
  withr::defer(meta_clean(valid))
  meta_set_valid(valid) <- TRUE
  expect_false(meta_is_outdated(valid))

  unread <- fake_invalid_meta("2026-09-18", "2026-09-18")
  withr::defer(meta_clean(unread))
  meta_set_processed(unread) <- FALSE
  expect_false(meta_is_outdated(unread))
})

test_that("download_single_file downloads a recent invalid file again", {
  calls <- 0
  local_mocked_bindings(download_marketdata = function(meta) {
    calls <<- calls + 1
    meta
  })
  recent <- fake_invalid_meta("2026-09-21", "2026-09-21")
  withr::defer(meta_clean(recent))
  old <- fake_invalid_meta("2026-09-22", "2026-10-30")
  withr::defer(meta_clean(old))

  pb <- cli::cli_progress_bar(total = 2) # download_single_file() updates a progress bar
  download_single_file(recent, pb = pb)
  expect_equal(calls, 1)
  download_single_file(old, pb = pb)
  expect_equal(calls, 1)
})
