test_that("it should create a new meta object", {
  meta <- meta_new("template-test", var1 = 1, var2 = 2)

  expect_equal(meta$template, "template-test")
  args <- list(var1 = 1, var2 = 2)
  expect_equal(meta$download_args, args)
  checksum <- list(template = "template-test", download_args = list(var1 = 1, var2 = 2)) |>
    lapply(format) |>
    digest::digest()
  expect_equal(meta$download_checksum, checksum)
  expect_true(length(meta$downloaded) == 0)
  
  # Verify it's in the database
  con <- rb3_duckdb_connection()
  result <- DBI::dbGetQuery(
    con,
    "SELECT * FROM meta WHERE download_checksum = ?",
    params = list(checksum)
  )
  expect_equal(nrow(result), 1)
  expect_equal(result$template, "template-test")
  
  meta_clean(meta)
})

test_that("it should save meta to duckdb", {
  meta <- meta_new("template-test", var1 = 1, var2 = 2)
  
  # Modify and save
  meta$extra_data <- "new value"
  meta_save(meta)
  
  # Check if saved in DB
  con <- rb3_duckdb_connection()
  result <- DBI::dbGetQuery(
    con,
    "SELECT * FROM meta WHERE download_checksum = ?",
    params = list(meta$download_checksum)
  )
  expect_equal(nrow(result), 1)
  
  meta_clean(meta)
})

test_that("it should load existing meta from duckdb", {
  meta0 <- meta_new("template-test", var1 = 1, var2 = 2)
  
  meta1 <- meta_load("template-test", var1 = 1, var2 = 2)
  expect_equal(meta0$created, meta1$created)
  expect_equal(meta0$download_checksum, meta1$download_checksum)
  
  meta_clean(meta1)
})

test_that("it should clean meta from duckdb", {
  meta <- meta_new("template-test", var1 = 1, var2 = 2)
  checksum <- meta$download_checksum
  
  # Verify it exists
  con <- rb3_duckdb_connection()
  before <- DBI::dbGetQuery(
    con,
    "SELECT COUNT(*) as count FROM meta WHERE download_checksum = ?",
    params = list(checksum)
  )
  expect_equal(before$count, 1)
  
  # Clean it
  meta_clean(meta)
  
  # Verify it's gone
  con <- rb3_duckdb_connection()
  after <- DBI::dbGetQuery(
    con,
    "SELECT COUNT(*) as count FROM meta WHERE download_checksum = ?",
    params = list(checksum)
  )
  expect_equal(after$count, 0)
})

test_that("it should add download to meta", {
  meta <- meta_new("template-test", var1 = 1, var2 = 2)
  filename <- tempfile()
  meta_add_download(meta) <- filename
  
  # Check in object
  expect_equal(meta$downloaded[[1]], filename)
  
  # Check in database
  con <- rb3_duckdb_connection()
  result <- DBI::dbGetQuery(
    con,
    "SELECT * FROM meta WHERE download_checksum = ?",
    params = list(meta$download_checksum)
  )
  loaded_meta <- meta_get(meta$download_checksum)
  expect_equal(loaded_meta$downloaded[[1]], filename)
  
  # Add another file
  filename2 <- tempfile()
  meta_add_download(meta) <- filename2
  expect_equal(meta$downloaded[[2]], filename2)
  
  # Check not adding duplicates
  meta_add_download(meta) <- filename2
  expect_equal(length(meta$downloaded), 2)
  
  meta_clean(meta)
})

test_that("it handles errors gracefully", {
  # Non-existent meta
  fake_checksum <- "fake_checksum_that_doesnt_exist"
  expect_error(meta_get(fake_checksum), class = "error_meta_not_found")
  
  # Cleaning non-existent meta
  fake_meta <- structure(list(download_checksum = fake_checksum), class = "meta")
  expect_error(meta_clean(fake_meta), class = "error_meta_not_found")
})
