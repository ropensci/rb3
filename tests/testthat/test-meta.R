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
  con <- meta_db_connection()
  result <- DBI::dbGetQuery(
    con,
    "SELECT * FROM meta WHERE download_checksum = ?",
    params = list(checksum)
  )
  expect_equal(nrow(result), 1)
  expect_equal(result$template, "template-test")
  
  meta_clean(meta)
})

test_that("it should save meta to sqlite", {
  meta <- meta_new("template-test", var1 = 1, var2 = 2)
  
  # Modify and save
  meta$extra_data <- "new value"
  meta_save(meta)
  
  # Check if saved in DB
  con <- meta_db_connection()
  result <- DBI::dbGetQuery(
    con,
    "SELECT * FROM meta WHERE download_checksum = ?",
    params = list(meta$download_checksum)
  )
  expect_equal(nrow(result), 1)
  
  meta_clean(meta)
})

test_that("it should load existing meta from sqlite", {
  meta0 <- meta_new("template-test", var1 = 1, var2 = 2)
  
  meta1 <- meta_load("template-test", var1 = 1, var2 = 2)
  expect_equal(meta0$created, meta1$created)
  expect_equal(meta0$download_checksum, meta1$download_checksum)
  
  meta_clean(meta1)
})

test_that("it should clean meta from sqlite", {
  meta <- meta_new("template-test", var1 = 1, var2 = 2)
  checksum <- meta$download_checksum
  
  # Verify it exists
  con <- meta_db_connection()
  before <- DBI::dbGetQuery(
    con,
    "SELECT COUNT(*) as count FROM meta WHERE download_checksum = ?",
    params = list(checksum)
  )
  expect_equal(before$count, 1)
  
  # Clean it
  meta_clean(meta)
  
  # Verify it's gone
  con <- meta_db_connection()
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
  con <- meta_db_connection()
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

test_that("it should handle new metadata fields", {
  meta <- meta_new("template-test", var1 = 1, var2 = 2)
  
  # Check initial values
  expect_false(meta$is_valid)
  expect_false(meta$is_processed)
  expect_true(is.character(meta$download_args_json))
  
  # Set validity status
  meta_set_valid(meta) <- TRUE
  expect_true(meta$is_valid)
  
  # Set processing status
  meta_set_processed(meta) <- TRUE
  expect_true(meta$is_processed)
  
  # Reload from DB and check if values persisted
  reloaded <- meta_load("template-test", var1 = 1, var2 = 2)
  expect_true(reloaded$is_valid)
  expect_true(reloaded$is_processed)
  
  # Test query by status
  result <- meta_query_status(valid = TRUE, processed = TRUE)
  expect_true(nrow(result) >= 1)
  expect_true(meta$download_checksum %in% result$download_checksum)
  
  # Clean up
  meta_clean(meta)
})

test_that("JSON args are correctly stored and retrieved", {
  # Create a meta with complex arguments
  meta <- meta_new("template-test", 
                   simple_arg = "value",
                   list_arg = list(a = 1, b = 2),
                   numeric_arg = 123.45)
  
  # Parse the JSON and verify
  args_from_json <- jsonlite::fromJSON(meta$download_args_json)
  expect_equal(args_from_json$simple_arg, "value")
  expect_equal(args_from_json$numeric_arg, 123.45)
  expect_equal(args_from_json$list_arg$a, 1)
  expect_equal(args_from_json$list_arg$b, 2)
  
  # Clean up
  meta_clean(meta)
})
