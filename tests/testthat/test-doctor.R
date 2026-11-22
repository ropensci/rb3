# No network: records and datasets are created by hand in the temp cache of setup.R.

raw_file <- function(name = basename(tempfile(fileext = ".gz"))) {
  f <- file.path(rb3_registry$get_instance()$raw_folder, name)
  writeLines("x", f)
  f
}

fake_download <- function(meta, file) {
  meta_add_download(meta) <- file
  meta_set_downloaded(meta) <- TRUE
  meta
}

test_that("doctor_health on a clean cache returns zero rows with the right columns", {
  withr::local_options(rb3.cachedir = tempfile("rb3-doctor-"))
  suppressMessages(rb3_bootstrap())
  withr::defer(suppressMessages(rb3_bootstrap()))
  res <- doctor_health()
  expect_named(res, c("template", "layer", "check", "refdate", "reason", "detail"))
  expect_equal(nrow(res), 0)
})

test_that("doctor_health finds stale records", {
  stale <- meta_new("template-test-small-file", size = 1, foo = 2)
  withr::defer(meta_clean(stale))
  ok <- template_meta_create_or_load("template-test-small-file", size = 1)
  withr::defer(meta_clean(ok))

  res <- doctor_health("template-test-small-file")
  expect_equal(nrow(res), 1)
  expect_equal(res$check, "stale_meta")
  expect_equal(res$template, "template-test-small-file")
  expect_match(res$detail, "foo")
})

test_that("doctor_health finds records whose raw file is missing", {
  f <- raw_file()
  m <- fake_download(template_meta_create_or_load("template-test-small-file", size = 2), f)
  withr::defer(meta_clean(m))
  unlink(f)

  res <- doctor_health("template-test-small-file")
  expect_equal(res$check, "missing_raw")
  expect_match(res$detail, basename(f), fixed = TRUE)
})

test_that("doctor_health finds raw files without records, and shared files are not orphans", {
  orphan <- raw_file("x.gz")
  withr::defer(unlink(orphan))
  shared <- raw_file()
  m1 <- fake_download(template_meta_create_or_load("template-test-small-file", size = 3), shared)
  m2 <- fake_download(template_meta_create_or_load("template-test-small-file", size = 4), shared)
  withr::defer({
    meta_clean(m1)
    meta_clean(m2)
  })

  res <- doctor_health()
  orphans <- res[res$check == "orphan_raw", ]
  expect_equal(orphans$detail, "x.gz")
  expect_true(is.na(orphans$template))
  expect_false(any(res$check == "orphan_raw" & res$detail == basename(shared)))
  expect_false(any(doctor_health("template-test-small-file")$check == "orphan_raw"))
})
