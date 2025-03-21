skip_on_cran()
skip_if_offline()

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

test_that("it should clean meta and its dependencies", {
  .meta <- download_marketdata("b3-futures-settlement-prices", refdate = as.Date("2023-01-02"))
  read_marketdata(.meta)
  expect_true(file.exists(meta_file(.meta)))
  expect_true(length(.meta$downloaded) == 1)
  expect_true(file.exists(.meta$downloaded[[1]]))
  meta_clean(.meta)
  expect_false(file.exists(meta_file(.meta)))
  expect_false(file.exists(.meta$downloaded[[1]]))
})

test_that("it should download again and identifies that the file has changed", {
  .meta <- download_marketdata("template-test-small-file", size = 1024)
  expect_true(file.exists(meta_file(.meta)))
  expect_true(length(.meta$downloaded) == 1)
  expect_true(file.exists(.meta$downloaded[[1]]))
  .meta2 <- download_marketdata("template-test-small-file", do_cache = TRUE, size = 1024)
  expect_true(file.exists(.meta2$downloaded[[1]]))
  expect_false(.meta2$downloaded[[1]] == .meta$downloaded[[1]])
  meta_clean(.meta)
  meta_clean(.meta2)
})

test_that("it should download again and identifies that the file is the same", {
  .meta <- download_marketdata("b3-cotahist-daily", refdate = as.Date("2018-01-02"))
  expect_true(file.exists(meta_file(.meta)))
  expect_true(length(.meta$downloaded) == 1)
  expect_true(file.exists(.meta$downloaded[[1]]))
  .meta2 <- download_marketdata("b3-cotahist-daily", do_cache = TRUE, refdate = as.Date("2018-01-02"))
  expect_true(file.exists(.meta2$downloaded[[1]]))
  expect_true(.meta2$downloaded[[1]] == .meta$downloaded[[1]])
  meta_clean(.meta)
  meta_clean(.meta2)
})

test_that("it should clean meta when reading invalid file", {
  .meta <- download_marketdata("b3-futures-settlement-prices", refdate = as.Date("2023-01-01"))
  expect_true(file.exists(meta_file(.meta)))
  expect_true(file.exists(.meta$downloaded[[1]]))
  read_marketdata(.meta)
  expect_false(file.exists(meta_file(.meta)))
  expect_false(file.exists(.meta$downloaded[[1]]))
})

test_that("it should download and read b3-futures-settlement-prices", {
  .meta <- download_marketdata("b3-futures-settlement-prices", refdate = as.Date("2023-01-02"))
  .df <- read_marketdata(.meta)
  expect_true(file.exists(meta_file(.meta)))
  expect_true(length(.meta$downloaded) == 1)
  expect_true(file.exists(.meta$downloaded[[1]]))
  expect_s3_class(.df, "data.frame")
})

test_that("it should download and read b3-cotahist-daily", {
  .meta <- download_marketdata("b3-cotahist-daily", refdate = as.Date("2018-01-02"))
  .df <- read_marketdata(.meta)
  expect_true(file.exists(meta_file(.meta)))
  expect_true(length(.meta$downloaded) == 1)
  expect_true(file.exists(.meta$downloaded[[1]]))
  expect_s3_class(.df, "data.frame")
})

test_that("it should download and read b3-reference-rates", {
  .meta <- download_marketdata("b3-reference-rates", refdate = as.Date("2018-01-02"), curve_name = "PRE")
  .df <- read_marketdata(.meta)
  expect_true(file.exists(meta_file(.meta)))
  expect_true(length(.meta$downloaded) == 1)
  expect_true(file.exists(.meta$downloaded[[1]]))
  expect_s3_class(.df, "data.frame")
})

test_that("it should download and read b3-reference-rates for an invalid date", {
  .meta <- download_marketdata("b3-reference-rates", refdate = as.Date("2025-03-15"), curve_name = "PRE")
  .df <- read_marketdata(.meta)
  expect_true(is.null(.df))
  expect_false(file.exists(meta_file(.meta)))
  expect_false(file.exists(.meta$downloaded[[1]]))
})

test_that("it should fail to download b3-reference-rates with no curve name", {
  .meta <- download_marketdata("b3-reference-rates", refdate = as.Date("2025-03-15"))
  expect_true(is.null(.meta))
})

test_that("it should fetch b3-reference-rates", {
  fetch_marketdata("b3-reference-rates",
    refdate = c(as.Date("2025-03-12"), as.Date("2025-03-13")),
    curve_name = c("PRE", "DIC")
  )
  expect_no_error(meta_load("b3-reference-rates", refdate = as.Date("2025-03-12"), curve_name = "PRE"))
  expect_no_error(meta_load("b3-reference-rates", refdate = as.Date("2025-03-13"), curve_name = "PRE"))
  expect_no_error(meta_load("b3-reference-rates", refdate = as.Date("2025-03-12"), curve_name = "DIC"))
  expect_no_error(meta_load("b3-reference-rates", refdate = as.Date("2025-03-13"), curve_name = "DIC"))
})

test_that("it should fetch b3-reference-rates with fails", {
  # download fail
  fetch_marketdata("b3-reference-rates", refdate = as.Date("2025-03-12"))
  expect_error(meta_load("b3-reference-rates", refdate = as.Date("2025-03-12")))
  # read fail
  fetch_marketdata("b3-reference-rates", refdate = as.Date("2025-03-15"), curve_name = "PRE")
  expect_error(meta_load("b3-reference-rates", , refdate = as.Date("2025-03-15"), curve_name = "PRE"))
})

test_that("it should download and read b3-bvbg-086", {
  # it has multiple files but it picks only one
  .meta <- download_marketdata("b3-bvbg-086", refdate = as.Date("2018-01-02"))
  .df <- read_marketdata(.meta)
  expect_true(file.exists(meta_file(.meta)))
  expect_true(length(.meta$downloaded) == 1)
  expect_true(file.exists(.meta$downloaded[[1]]))
})
