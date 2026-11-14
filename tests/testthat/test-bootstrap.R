test_that("it should check rb3 folders", {
  reg <- rb3_registry$get_instance()
  expect_true(dir.exists(reg[["rb3_folder"]]))
  expect_true(dir.exists(reg[["raw_folder"]]))
  expect_true(dir.exists(reg[["db_folder"]]))
})

test_that("it should check rb3 sqlite connection", {
  reg <- rb3_registry$get_instance()
  expect_true("sqlite_db_connection" %in% names(reg))
  
  con <- meta_db_connection()
  expect_true(DBI::dbIsValid(con))
})

test_that("rb3_bootstrap switches the meta db when rb3.cachedir changes", {
  old_dir <- getOption("rb3.cachedir")
  new_dir <- file.path(tempdir(), "rb3-cache-new")
  withr::defer({
    options(rb3.cachedir = old_dir)
    suppressMessages(rb3_bootstrap())
    unlink(new_dir, recursive = TRUE)
  })

  meta_db_connection() # keep a live connection to the old db
  options(rb3.cachedir = new_dir)
  suppressMessages(rb3_bootstrap())

  con <- meta_db_connection()
  expect_equal(normalizePath(con@dbname), normalizePath(file.path(new_dir, "meta.sqlite")))
  expect_true(DBI::dbExistsTable(con, "meta"))
})
