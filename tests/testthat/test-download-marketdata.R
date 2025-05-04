skip_on_cran()
skip_if_offline()

# Helper function to check if meta exists in SQLite
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
  meta <- template_meta_create_or_load("template-test-error")
  meta <- download_marketdata(meta)
  expect_false(meta$is_downloaded)
})

test_that("it should download an empty file", {
  meta <- template_meta_create_or_load("template-test-small-file", size = 0)
  meta <- download_marketdata(meta)
  expect_true(meta$is_downloaded)
})

test_that("it should download an small file", {
  meta <- template_meta_create_or_load("template-test-small-file", size = 2)
  meta <- download_marketdata(meta)
  expect_true(meta$is_downloaded)
})

test_that("it should download and read template-test", {
  meta <- template_meta_create_or_load("template-test")
  meta <- download_marketdata(meta)
  meta <- read_marketdata(meta)

  # Check meta exists in database
  expect_true(meta_exists_in_db(meta$download_checksum))
  expect_true(meta$is_downloaded)
  expect_true(length(meta$downloaded) == 1)
  expect_true(file.exists(meta$downloaded[[1]]))
  expect_s3_class(meta, "meta")
})

test_that("it should download file and return meta", {
  # Create metadata first, then download
  meta <- template_meta_create_or_load("template-test-small-file", size = 1024)
  meta <- download_marketdata(meta)

  # Verify meta contains expected attributes
  expect_true(meta$is_downloaded)
  expect_true(meta_exists_in_db(meta$download_checksum))
  expect_true(length(meta$downloaded) == 1)
  expect_true(file.exists(meta$downloaded[[1]]))
  expect_s3_class(meta, "meta")
})

test_that("it should clean meta and its dependencies", {
  meta <- template_meta_create_or_load("b3-futures-settlement-prices", refdate = as.Date("2023-01-02"))
  meta <- download_marketdata(meta)
  meta <- read_marketdata(meta)

  # Check meta exists in database before cleaning
  expect_true(meta_exists_in_db(meta$download_checksum))
  expect_true(meta$is_downloaded)
  expect_true(length(meta$downloaded) == 1)
  expect_true(file.exists(meta$downloaded[[1]]))

  # Clean and check it's removed
  meta_clean(meta)
  expect_false(meta_exists_in_db(meta$download_checksum))
  expect_false(file.exists(meta$downloaded[[1]]))
})

test_that("it should download again and identifies that the file has changed", {
  meta <- template_meta_create_or_load("template-test-small-file", size = 1024)
  meta <- download_marketdata(meta)

  # Check first download
  expect_true(meta_exists_in_db(meta$download_checksum))
  expect_true(meta$is_downloaded)
  expect_true(length(meta$downloaded) == 1)
  expect_true(file.exists(meta$downloaded[[1]]))

  # Redownload with force_download
  meta2 <- template_meta_create_or_load("template-test-small-file", size = 1024)
  meta2 <- download_marketdata(meta2)
  expect_true(meta2$is_downloaded)
  expect_true(file.exists(meta2$downloaded[[1]]))
  expect_false(meta2$downloaded[[1]] == meta$downloaded[[1]])

  # Clean up
  meta_clean(meta)
})

test_that("it should download again and identifies that the file is the same", {
  meta <- template_meta_create_or_load("b3-cotahist-daily", refdate = as.Date("2018-01-02"))
  meta <- download_marketdata(meta)

  # Check first download
  expect_true(meta_exists_in_db(meta$download_checksum))
  expect_true(meta$is_downloaded)
  expect_true(length(meta$downloaded) == 1)
  expect_true(file.exists(meta$downloaded[[1]]))

  # Redownload
  meta2 <- template_meta_create_or_load("b3-cotahist-daily", refdate = as.Date("2018-01-02"))
  meta2 <- download_marketdata(meta2)
  expect_true(meta2$is_downloaded)
  expect_true(file.exists(meta2$downloaded[[1]]))
  expect_true(meta2$downloaded[[1]] == meta$downloaded[[1]])

  # Clean up
  meta_clean(meta)
})

test_that("it should clean meta when reading invalid file", {
  meta <- template_meta_create_or_load("b3-futures-settlement-prices", refdate = as.Date("2023-01-01"))
  meta <- download_marketdata(meta)

  # Check meta exists in database before reading
  expect_true(meta_exists_in_db(meta$download_checksum))
  expect_true(meta$is_downloaded)
  expect_true(file.exists(meta$downloaded[[1]]))

  meta <- read_marketdata(meta)
  expect_true(meta_exists_in_db(meta$download_checksum))
  expect_true(meta$is_processed)
  expect_false(meta$is_valid)
  expect_true(file.exists(meta$downloaded[[1]]))
})

test_that("it should download and read b3-futures-settlement-prices", {
  meta <- template_meta_create_or_load("b3-futures-settlement-prices", refdate = as.Date("2023-01-02"))
  meta <- download_marketdata(meta)
  meta <- read_marketdata(meta)

  # Verify meta in DB and file exists
  expect_true(meta_exists_in_db(meta$download_checksum))
  expect_true(meta$is_downloaded)
  expect_true(meta$is_processed)
  expect_true(meta$is_valid)
  expect_true(length(meta$downloaded) == 1)
  expect_true(file.exists(meta$downloaded[[1]]))
  expect_s3_class(meta, "meta")
})

test_that("it should download and read b3-cotahist-daily", {
  meta <- template_meta_create_or_load("b3-cotahist-daily", refdate = as.Date("2018-01-02"))
  meta <- download_marketdata(meta)
  meta <- read_marketdata(meta)

  # Verify meta in DB and file exists
  expect_true(meta_exists_in_db(meta$download_checksum))
  expect_true(meta$is_downloaded)
  expect_true(meta$is_processed)
  expect_true(meta$is_valid)
  expect_true(length(meta$downloaded) == 1)
  expect_true(file.exists(meta$downloaded[[1]]))
  expect_s3_class(meta, "meta")
})

test_that("it should download and read b3-reference-rates", {
  meta <- template_meta_create_or_load("b3-reference-rates", refdate = as.Date("2018-01-02"), curve_name = "PRE")
  meta <- download_marketdata(meta)
  meta <- read_marketdata(meta)

  # Verify meta in DB and file exists
  expect_true(meta_exists_in_db(meta$download_checksum))
  expect_true(meta$is_downloaded)
  expect_true(meta$is_processed)
  expect_true(meta$is_valid)
  expect_true(length(meta$downloaded) == 1)
  expect_true(file.exists(meta$downloaded[[1]]))
  expect_s3_class(meta, "meta")
})

test_that("it should download and read b3-reference-rates for an invalid date", {
  meta <- template_meta_create_or_load("b3-reference-rates", refdate = as.Date("2025-03-15"), curve_name = "PRE")
  meta <- download_marketdata(meta)
  meta <- read_marketdata(meta)

  expect_true(meta$is_downloaded)
  expect_true(meta$is_processed)
  expect_false(meta$is_valid)
  expect_true(meta_exists_in_db(meta$download_checksum))
  expect_true(file.exists(meta$downloaded[[1]]))
})

test_that("it should fail to create meta for b3-reference-rates with no curve name", {
  expect_error(template_meta_create_or_load("b3-reference-rates", refdate = as.Date("2025-03-15")))
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
  # download fail because of missing argument curve_name
  expect_error(fetch_marketdata("b3-reference-rates", refdate = as.Date("2025-03-12")))

  # read fail
  suppressMessages(fetch_marketdata("b3-reference-rates", refdate = as.Date("2025-03-15"), curve_name = "PRE"))
  expect_no_error(meta_load("b3-reference-rates", refdate = as.Date("2025-03-15"), curve_name = "PRE"))
})

test_that("it should download and read b3-bvbg-086", {
  # it has multiple files but it picks only one
  meta <- template_meta_create_or_load("b3-bvbg-086", refdate = as.Date("2018-01-02"))
  meta <- download_marketdata(meta)
  meta <- read_marketdata(meta)

  # Verify meta in DB and file exists
  expect_true(meta_exists_in_db(meta$download_checksum))
  expect_true(meta$is_downloaded)
  expect_true(meta$is_processed)
  expect_true(meta$is_valid)
  expect_true(length(meta$downloaded) == 1)
  expect_true(file.exists(meta$downloaded[[1]]))
})

test_that("it should download and read b3-indexes-composition", {
  meta <- template_meta_create_or_load("b3-indexes-composition")
  meta <- download_marketdata(meta)
  meta <- read_marketdata(meta)

  # Verify meta in DB and file exists
  expect_true(meta_exists_in_db(meta$download_checksum))
  expect_true(meta$is_downloaded)
  expect_true(meta$is_processed)
  expect_true(meta$is_valid)
  expect_true(length(meta$downloaded) == 1)
  expect_true(file.exists(meta$downloaded[[1]]))
})

test_that("it should download and read b3-indexes-historical-data", {
  meta <- template_meta_create_or_load("b3-indexes-historical-data", index = "IBOV", year = 2022)
  meta <- download_marketdata(meta)
  meta <- read_marketdata(meta)

  # Verify meta in DB and file exists
  expect_true(meta_exists_in_db(meta$download_checksum))
  expect_true(meta$is_downloaded)
  expect_true(meta$is_processed)
  expect_true(meta$is_valid)
  expect_true(length(meta$downloaded) == 1)
  expect_true(file.exists(meta$downloaded[[1]]))
})

test_that("it should download and read b3-indexes-historical-data for an invalid year", {
  meta <- template_meta_create_or_load("b3-indexes-historical-data", index = "IDIV", year = 1960)
  meta <- download_marketdata(meta)
  meta <- read_marketdata(meta)

  expect_true(meta$is_downloaded)
  expect_true(meta$is_processed)
  expect_false(meta$is_valid)
  expect_true(meta_exists_in_db(meta$download_checksum))
})

test_that("it should download and read b3-indexes-historical-data for an invalid index", {
  meta <- template_meta_create_or_load("b3-indexes-historical-data", index = "XXXX", year = 1960)
  meta <- download_marketdata(meta)
  meta <- read_marketdata(meta)

  expect_true(meta$is_downloaded)
  expect_true(meta$is_processed)
  expect_false(meta$is_valid)
  expect_true(meta_exists_in_db(meta$download_checksum))
})

test_that("it should download and read b3-indexes-current-portfolio", {
  meta <- template_meta_create_or_load("b3-indexes-current-portfolio", index = "IBOV")
  meta <- download_marketdata(meta)
  meta <- read_marketdata(meta)

  # Verify meta in DB and file exists
  expect_true(meta_exists_in_db(meta$download_checksum))
  expect_true(meta$is_downloaded)
  expect_true(meta$is_processed)
  expect_true(meta$is_valid)
  expect_true(length(meta$downloaded) == 1)
  expect_true(file.exists(meta$downloaded[[1]]))
})

test_that("it should download and read b3-indexes-theoretical-portfolio", {
  meta <- template_meta_create_or_load("b3-indexes-theoretical-portfolio", index = "IBOV")
  meta <- download_marketdata(meta)
  meta <- read_marketdata(meta)

  # Verify meta in DB and file exists
  expect_true(meta_exists_in_db(meta$download_checksum))
  expect_true(meta$is_downloaded)
  expect_true(meta$is_processed)
  expect_true(meta$is_valid)
  expect_true(length(meta$downloaded) == 1)
  expect_true(file.exists(meta$downloaded[[1]]))
})

test_that("it should download and read b3-indexes-current-portfolio for an invalid index", {
  meta <- template_meta_create_or_load("b3-indexes-current-portfolio", index = "XXXX")
  meta <- download_marketdata(meta)
  meta <- read_marketdata(meta)

  # Verify meta in DB and file exists
  expect_true(meta_exists_in_db(meta$download_checksum))
  expect_true(meta$is_downloaded)
  expect_true(meta$is_processed)
  expect_false(meta$is_valid)
  expect_true(length(meta$downloaded) == 1)
  expect_true(file.exists(meta$downloaded[[1]]))
})

test_that("it should download and read b3-indexes-theoretical-portfolio for an invalid index", {
  meta <- template_meta_create_or_load("b3-indexes-theoretical-portfolio", index = "XXXX")
  meta <- download_marketdata(meta)
  meta <- read_marketdata(meta)

  # Verify meta in DB and file exists
  expect_true(meta_exists_in_db(meta$download_checksum))
  expect_true(meta$is_downloaded)
  expect_true(meta$is_processed)
  expect_false(meta$is_valid)
  expect_true(length(meta$downloaded) == 1)
  expect_true(file.exists(meta$downloaded[[1]]))
})
