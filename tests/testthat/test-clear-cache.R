test_that("rb3_clear_cache removes raw files, datasets and meta rows", {
  old_dir <- getOption("rb3.cachedir")
  new_dir <- file.path(tempdir(), "rb3-cache-clear")
  withr::defer({
    options(rb3.cachedir = old_dir)
    suppressMessages(rb3_bootstrap())
    unlink(new_dir, recursive = TRUE)
  })
  options(rb3.cachedir = new_dir)
  suppressMessages(rb3_bootstrap())

  reg <- rb3_registry$get_instance()
  writeLines("x", file.path(reg$raw_folder, "abc.gz"))
  dir.create(file.path(reg$db_folder, "input", "tpl"), recursive = TRUE)
  writeLines("x", file.path(reg$db_folder, "input", "tpl", "part-0.parquet"))
  con <- meta_db_connection()
  DBI::dbExecute(con, "INSERT INTO meta (download_checksum, template) VALUES ('abc', 'tpl')")

  expect_true(rb3_clear_cache(ask = FALSE))

  expect_length(list.files(reg$raw_folder, recursive = TRUE), 0)
  expect_length(list.files(reg$db_folder, recursive = TRUE), 0)
  expect_true(dir.exists(reg$raw_folder))
  expect_true(dir.exists(reg$db_folder))
  con <- meta_db_connection()
  expect_equal(DBI::dbGetQuery(con, "SELECT COUNT(*) AS n FROM meta")$n, 0)
})

test_that("rb3_clear_cache keeps the cache when the user says no", {
  local_mocked_bindings(askYesNo = function(...) FALSE, .package = "utils")
  f <- file.path(rb3_registry$get_instance()$raw_folder, "keep.gz")
  writeLines("x", f)
  withr::defer(unlink(f))
  expect_false(rb3_clear_cache(ask = TRUE))
  expect_true(file.exists(f))
})
