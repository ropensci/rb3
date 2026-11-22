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

# --- gap check ---

write_layer <- function(tpl_id, dates) {
  tpl <- template_retrieve(tpl_id)
  folder <- template_db_folder(tpl, "input")
  unlink(list.files(folder, full.names = TRUE), recursive = TRUE)
  if (length(dates) > 0) {
    arrow::write_dataset(data.frame(refdate = as.Date(dates), value = 1), folder, partitioning = "refdate")
  }
  withr::defer(unlink(list.files(folder, full.names = TRUE), recursive = TRUE), envir = parent.frame())
}

# status: "ok", "download_failed", "not_read", "no_data"
record <- function(tpl_id, status, ...) {
  m <- template_meta_create_or_load(tpl_id, ...)
  if (status != "download_failed") meta_set_downloaded(m) <- TRUE
  if (status %in% c("ok", "no_data")) meta_set_processed(m) <- TRUE
  if (status == "ok") meta_set_valid(m) <- TRUE
  withr::defer(meta_clean(m), envir = parent.frame())
  m
}

test_that("each missing date gets its reason", {
  write_layer("template-test-doctor-daily", "2024-01-08")
  record("template-test-doctor-daily", "ok", refdate = as.Date("2024-01-08"))
  record("template-test-doctor-daily", "download_failed", refdate = as.Date("2024-01-09"))
  record("template-test-doctor-daily", "not_read", refdate = as.Date("2024-01-10"))
  record("template-test-doctor-daily", "no_data", refdate = as.Date("2024-01-11"))
  record("template-test-doctor-daily", "ok", refdate = as.Date("2024-01-12"))

  res <- doctor_gaps("template-test-doctor-daily", from = "2024-01-08", to = "2024-01-15")
  expect_equal(res$refdate, as.Date(c("2024-01-09", "2024-01-10", "2024-01-11", "2024-01-12", "2024-01-15")))
  expect_equal(res$reason, c("download_failed", "not_read", "no_data", "not_in_layer", "never_fetched"))
  expect_true(all(res$check == "gap" & res$layer == "input" & res$template == "template-test-doctor-daily"))
})

test_that("refdate args stored as strings still match", {
  write_layer("template-test-doctor-daily", "2024-01-08")
  record("template-test-doctor-daily", "no_data", refdate = "2024-01-09")
  res <- doctor_gaps("template-test-doctor-daily", from = "2024-01-08", to = "2024-01-09")
  expect_equal(res$reason, "no_data")
})

test_that("yearly templates map dates to the year record and take the best status over other args", {
  write_layer("template-test-doctor-yearly", "2024-01-08")
  record("template-test-doctor-yearly", "no_data", year = 2024, index = "A")
  res <- doctor_gaps("template-test-doctor-yearly", from = "2024-01-08", to = "2024-01-09", calendar = "Brazil/BMF")
  expect_equal(res$reason, "no_data")

  record("template-test-doctor-yearly", "ok", year = 2024, index = "B")
  res <- doctor_gaps("template-test-doctor-yearly", from = "2024-01-08", to = "2024-01-09", calendar = "Brazil/BMF")
  expect_equal(res$refdate, as.Date("2024-01-09"))
  expect_equal(res$reason, "not_in_layer")
})

test_that("from and to default to the first and last date in the layer", {
  write_layer("template-test-doctor-daily", c("2024-01-08", "2024-01-10"))
  res <- doctor_gaps("template-test-doctor-daily")
  expect_equal(res$refdate, as.Date("2024-01-09"))
  expect_equal(res$reason, "never_fetched")
  expect_equal(attr(res, "period")$n_days, 3)
  expect_equal(attr(res, "period")$n_with_data, 2)
})

test_that("calendar comes from the template, the argument overrides it, and is required otherwise", {
  write_layer("template-test-doctor-yearly", "2024-01-08")
  expect_error(doctor_gaps("template-test-doctor-yearly"), class = "error_doctor_calendar_missing")

  write_layer("template-test-doctor-daily", c("2024-12-23", "2024-12-26"))
  expect_equal(doctor_gaps("template-test-doctor-daily")$refdate, as.Date("2024-12-24")) # Brazil/BMF
  expect_equal(nrow(doctor_gaps("template-test-doctor-daily", calendar = "Brazil/B3")), 0)
})

test_that("a period past the calendar's end is a clear error", {
  skip_if(bizdays::calendars()[["Brazil/B3"]]$end.date >= as.Date("2026-06-01"))
  write_layer("template-test-doctor-daily", "2024-01-08")
  expect_error(
    doctor_gaps("template-test-doctor-daily", to = "2026-06-01", calendar = "Brazil/B3"),
    "2025-12-31",
    class = "error_doctor_calendar"
  )
})

test_that("snapshot templates skip the gap check", {
  res <- doctor_gaps("b3-indexes-composition")
  expect_equal(nrow(res), 0)
})

test_that("bad layers are errors", {
  expect_error(doctor_gaps("template-test-doctor-daily", layer = "staging"), class = "error_doctor_layer")
  expect_error(
    doctor_gaps("b3-indexes-historical-data", calendar = "Brazil/B3"),
    "staging",
    class = "error_doctor_layer"
  )
})

# --- rb3_doctor ---

test_that("rb3_doctor without template runs only the health checks", {
  expect_invisible(res <- suppressMessages(rb3_doctor()))
  expect_false(any(res$check == "gap"))
})

test_that("rb3_doctor prints the period, gap runs and health lines", {
  write_layer("template-test-doctor-daily", c("2024-01-08", "2024-01-12", "2024-01-16"))
  record("template-test-doctor-daily", "no_data", refdate = as.Date("2024-01-15"))
  msgs <- capture_messages(res <- rb3_doctor("template-test-doctor-daily"))
  out <- paste(msgs, collapse = "\n")
  expect_match(out, "Cache doctor: template-test-doctor-daily \\(input\\)")
  expect_match(out, "2024-01-08 to 2024-01-16, 7 business days, 3 with data")
  expect_match(out, "2024-01-09 to 2024-01-11 \\(3 days\\): never fetched")
  expect_match(out, "2024-01-15 \\(1 day\\): no data")
  expect_match(out, "No stale records")
  expect_equal(res$refdate[res$check == "gap"], as.Date(c("2024-01-09", "2024-01-10", "2024-01-11", "2024-01-15")))
})

test_that("rb3_doctor reports health problems with counts", {
  stale <- meta_new("template-test-doctor-daily", refdate = as.Date("2024-01-08"), foo = 1)
  withr::defer(meta_clean(stale))
  write_layer("template-test-doctor-daily", "2024-01-08")
  msgs <- capture_messages(res <- rb3_doctor("template-test-doctor-daily"))
  expect_match(paste(msgs, collapse = "\n"), "1 stale record")
  expect_equal(sum(res$check == "stale_meta"), 1)
})

test_that("empty layer without from/to is an error", {
  write_layer("template-test-doctor-daily", character())
  expect_error(suppressMessages(rb3_doctor("template-test-doctor-daily")), class = "error_doctor_layer")
})

test_that("rb3_doctor does not create a missing layer folder", {
  tpl <- template_retrieve("template-test-doctor-daily")
  folder <- file.path(rb3_registry$get_instance()$db_folder, tpl$writers$input$layer, tpl$id)
  unlink(folder, recursive = TRUE)
  expect_error(suppressMessages(rb3_doctor("template-test-doctor-daily")), class = "error_doctor_layer")
  expect_false(dir.exists(folder))
})
