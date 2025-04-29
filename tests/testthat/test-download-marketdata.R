skip_on_cran()
skip_if_offline()

# Helper function to check if meta exists in DuckDB
meta_exists_in_db <- function(checksum) {
  con <- meta_db_connection()
  result <- DBI::dbGetQuery(
    con,
    "SELECT COUNT(*) as count FROM meta WHERE download_checksum = ?",
    params = list(checksum)
  )
  return(result$count > 0)
}

test_that("it should access an URL that returns 500 error", {
  .meta <- download_marketdata("template-test-error")
  expect_true(is.null(.meta))
})

test_that("it should download an empty file", {
  .meta <- download_marketdata("template-test-small-file", size = 0)
  expect_true(is.null(.meta))
})

test_that("it should download an small file", {
  .meta <- download_marketdata("template-test-small-file", size = 2)
  expect_true(is.null(.meta))
})

test_that("it should download and read template-test", {
  .meta <- download_marketdata("template-test")
  .df <- read_marketdata(.meta)
  
  # Check meta exists in database
  expect_true(meta_exists_in_db(.meta$download_checksum))
  expect_true(length(.meta$downloaded) == 1)
  expect_true(file.exists(.meta$downloaded[[1]]))
  expect_s3_class(.df, "data.frame")
})

test_that("it should clean meta and its dependencies", {
  .meta <- download_marketdata("b3-futures-settlement-prices", refdate = as.Date("2023-01-02"))
  read_marketdata(.meta)
  
  # Check meta exists in database before cleaning
  expect_true(meta_exists_in_db(.meta$download_checksum))
  expect_true(length(.meta$downloaded) == 1)
  expect_true(file.exists(.meta$downloaded[[1]]))
  
  # Clean and check it's removed
  meta_clean(.meta)
  expect_false(meta_exists_in_db(.meta$download_checksum))
  expect_false(file.exists(.meta$downloaded[[1]]))
})

test_that("it should download again and identifies that the file has changed", {
  .meta <- download_marketdata("template-test-small-file", size = 1024)
  
  # Check first download
  expect_true(meta_exists_in_db(.meta$download_checksum))
  expect_true(length(.meta$downloaded) == 1)
  expect_true(file.exists(.meta$downloaded[[1]]))
  
  # Redownload with cache
  .meta2 <- download_marketdata("template-test-small-file", do_cache = TRUE, size = 1024)
  expect_true(file.exists(.meta2$downloaded[[1]]))
  expect_false(.meta2$downloaded[[1]] == .meta$downloaded[[1]])
  
  # Clean up
  meta_clean(.meta)
})

test_that("it should download again and identifies that the file is the same", {
  .meta <- download_marketdata("b3-cotahist-daily", refdate = as.Date("2018-01-02"))
  
  # Check first download
  expect_true(meta_exists_in_db(.meta$download_checksum))
  expect_true(length(.meta$downloaded) == 1)
  expect_true(file.exists(.meta$downloaded[[1]]))
  
  # Redownload with cache
  .meta2 <- download_marketdata("b3-cotahist-daily", do_cache = TRUE, refdate = as.Date("2018-01-02"))
  expect_true(file.exists(.meta2$downloaded[[1]]))
  expect_true(.meta2$downloaded[[1]] == .meta$downloaded[[1]])
  
  # Clean up
  meta_clean(.meta)
})

test_that("it should clean meta when reading invalid file", {
  .meta <- download_marketdata("b3-futures-settlement-prices", refdate = as.Date("2023-01-01"))
  
  # Check meta exists in database before reading
  expect_true(meta_exists_in_db(.meta$download_checksum))
  expect_true(file.exists(.meta$downloaded[[1]]))
  
  # Reading should clean if invalid
  read_marketdata(.meta)
  expect_false(meta_exists_in_db(.meta$download_checksum))
  expect_false(file.exists(.meta$downloaded[[1]]))
})

test_that("it should download and read b3-futures-settlement-prices", {
  .meta <- download_marketdata("b3-futures-settlement-prices", refdate = as.Date("2023-01-02"))
  .df <- read_marketdata(.meta)
  
  # Verify meta in DB and file exists
  expect_true(meta_exists_in_db(.meta$download_checksum))
  expect_true(length(.meta$downloaded) == 1)
  expect_true(file.exists(.meta$downloaded[[1]]))
  expect_s3_class(.df, "data.frame")
})

test_that("it should download and read b3-cotahist-daily", {
  .meta <- download_marketdata("b3-cotahist-daily", refdate = as.Date("2018-01-02"))
  .df <- read_marketdata(.meta)
  
  # Verify meta in DB and file exists
  expect_true(meta_exists_in_db(.meta$download_checksum))
  expect_true(length(.meta$downloaded) == 1)
  expect_true(file.exists(.meta$downloaded[[1]]))
  expect_s3_class(.df, "data.frame")
})

test_that("it should download and read b3-reference-rates", {
  .meta <- download_marketdata("b3-reference-rates", refdate = as.Date("2018-01-02"), curve_name = "PRE")
  .df <- read_marketdata(.meta)
  
  # Verify meta in DB and file exists
  expect_true(meta_exists_in_db(.meta$download_checksum))
  expect_true(length(.meta$downloaded) == 1)
  expect_true(file.exists(.meta$downloaded[[1]]))
  expect_s3_class(.df, "data.frame")
})

test_that("it should download and read b3-reference-rates for an invalid date", {
  .meta <- download_marketdata("b3-reference-rates", refdate = as.Date("2025-03-15"), curve_name = "PRE")
  .df <- read_marketdata(.meta)
  
  # Should be cleaned up if invalid
  expect_true(is.null(.df))
  expect_false(meta_exists_in_db(.meta$download_checksum))
  expect_false(file.exists(.meta$downloaded[[1]]))
})

test_that("it should fail to download b3-reference-rates with no curve name", {
  .meta <- download_marketdata("b3-reference-rates", refdate = as.Date("2025-03-15"))
  expect_true(is.null(.meta))
})

test_that("it should fetch b3-reference-rates", {
  suppressMessages({
    fetch_marketdata("b3-reference-rates",
      refdate = c(as.Date("2025-03-12"), as.Date("2025-03-13")),
      curve_name = c("PRE", "DIC")
    )
  })
  # Should be able to load the meta for each combination
  expect_no_error(meta_load("b3-reference-rates", refdate = as.Date("2025-03-12"), curve_name = "PRE"))
  expect_no_error(meta_load("b3-reference-rates", refdate = as.Date("2025-03-13"), curve_name = "PRE"))
  expect_no_error(meta_load("b3-reference-rates", refdate = as.Date("2025-03-12"), curve_name = "DIC"))
  expect_no_error(meta_load("b3-reference-rates", refdate = as.Date("2025-03-13"), curve_name = "DIC"))
})

test_that("it should fetch b3-reference-rates with fails", {
  # download fail
  suppressMessages(fetch_marketdata("b3-reference-rates", refdate = as.Date("2025-03-12")))
  expect_error(meta_load("b3-reference-rates", refdate = as.Date("2025-03-12")))
  
  # read fail
  suppressMessages(fetch_marketdata("b3-reference-rates", refdate = as.Date("2025-03-15"), curve_name = "PRE"))
  expect_error(meta_load("b3-reference-rates", refdate = as.Date("2025-03-15"), curve_name = "PRE"))
})

test_that("it should download and read b3-bvbg-086", {
  # it has multiple files but it picks only one
  .meta <- download_marketdata("b3-bvbg-086", refdate = as.Date("2018-01-02"))
  .df <- read_marketdata(.meta)
  
  # Verify meta in DB and file exists
  expect_true(meta_exists_in_db(.meta$download_checksum))
  expect_true(length(.meta$downloaded) == 1)
  expect_true(file.exists(.meta$downloaded[[1]]))
})

test_that("it should download and read b3-indexes-composition", {
  .meta <- download_marketdata("b3-indexes-composition")
  .df <- read_marketdata(.meta)
  
  # Verify meta in DB and file exists
  expect_true(meta_exists_in_db(.meta$download_checksum))
  expect_true(length(.meta$downloaded) == 1)
  expect_true(file.exists(.meta$downloaded[[1]]))
})

test_that("it should download and read b3-indexes-historical-data", {
  .meta <- download_marketdata("b3-indexes-historical-data", index = "IBOV", year = 2022)
  .df <- read_marketdata(.meta)
  
  # Verify meta in DB and file exists
  expect_true(meta_exists_in_db(.meta$download_checksum))
  expect_true(length(.meta$downloaded) == 1)
  expect_true(file.exists(.meta$downloaded[[1]]))
})

test_that("it should download and read b3-indexes-historical-data for an invalid year", {
  .meta <- download_marketdata("b3-indexes-historical-data", index = "IDIV", year = 1960)
  .df <- read_marketdata(.meta)
  
  # Should be cleaned up if invalid
  expect_false(meta_exists_in_db(.meta$download_checksum))
})

test_that("it should download and read b3-indexes-historical-data for an invalid index", {
  .meta <- download_marketdata("b3-indexes-historical-data", index = "XXXX", year = 1960)
  .df <- read_marketdata(.meta)
  
  # Should be cleaned up if invalid
  expect_false(meta_exists_in_db(.meta$download_checksum))
})

test_that("it should download and read b3-indexes-current-portfolio", {
  .meta <- download_marketdata("b3-indexes-current-portfolio", index = "IBOV")
  .df <- read_marketdata(.meta)
  
  # Verify meta in DB and file exists
  expect_true(meta_exists_in_db(.meta$download_checksum))
  expect_true(length(.meta$downloaded) == 1)
  expect_true(file.exists(.meta$downloaded[[1]]))
})

test_that("it should download and read b3-indexes-theoretical-portfolio", {
  .meta <- download_marketdata("b3-indexes-theoretical-portfolio", index = "IBOV")
  .df <- read_marketdata(.meta)
  
  # Verify meta in DB and file exists
  expect_true(meta_exists_in_db(.meta$download_checksum))
  expect_true(length(.meta$downloaded) == 1)
  expect_true(file.exists(.meta$downloaded[[1]]))
})
