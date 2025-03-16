skip_on_cran()
skip_if_offline()

test_that("it should access an URL that returns 500 error", {
  .meta <- download_marketdata("template-test")
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
  .meta <- read_marketdata(.meta)
  expect_true(file.exists(meta_file(.meta)))
  expect_true(length(.meta$downloaded) == 1)
  expect_true(file.exists(.meta$downloaded[[1]]))
  expect_true(length(.meta$processed_files) == 1)
  expect_true(file.exists(.meta$processed_files[[1]]))
  meta_clean(.meta)
  expect_false(file.exists(meta_file(.meta)))
  expect_false(file.exists(.meta$downloaded[[1]]))
  expect_false(file.exists(.meta$processed_files[[1]]))
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

test_that("it should fail downloading invalid file", {
  .meta <- download_marketdata("b3-futures-settlement-prices", refdate = as.Date("2023-01-01"))
  expect_true(file.exists(meta_file(.meta)))
  expect_true(file.exists(.meta$downloaded[[1]]))
  expect_true(length(.meta$processed_files) == 0)
  read_marketdata(.meta)
  expect_false(file.exists(meta_file(.meta)))
  expect_false(file.exists(.meta$downloaded[[1]]))
})

test_that("it should download file with multiple files but it picks only one", {
  .meta <- download_marketdata("b3-bvbg-086", refdate = as.Date("2018-01-02"))
  expect_true(file.exists(meta_file(.meta)))
  expect_true(file.exists(.meta$downloaded[[1]]))
  expect_true(length(.meta$processed_files) == 0)
  meta_clean(.meta)
})

test_that("it should download and read b3-futures-settlement-prices", {
  .meta <- download_marketdata("b3-futures-settlement-prices", refdate = as.Date("2023-01-02"))
  .meta <- read_marketdata(.meta)
  expect_true(file.exists(meta_file(.meta)))
  expect_true(length(.meta$downloaded) == 1)
  expect_true(file.exists(.meta$downloaded[[1]]))
  expect_true(length(.meta$processed_files) == 1)
  expect_true(file.exists(.meta$processed_files[[1]]))
})

test_that("it should download and read b3-cotahist-daily", {
  .meta <- download_marketdata("b3-cotahist-daily", refdate = as.Date("2018-01-02"))
  .meta <- read_marketdata(.meta)
  expect_true(file.exists(meta_file(.meta)))
  expect_true(length(.meta$downloaded) == 1)
  expect_true(file.exists(.meta$downloaded[[1]]))
  expect_true(length(.meta$processed_files) == 1)
  expect_true(file.exists(.meta$processed_files[[1]]))
})

test_that("it should download and read b3-reference-rates", {
  .meta <- download_marketdata("b3-reference-rates", refdate = as.Date("2018-01-02"), curve_name = "PRE")
  .meta <- read_marketdata(.meta)
  expect_true(file.exists(meta_file(.meta)))
  expect_true(length(.meta$downloaded) == 1)
  expect_true(file.exists(.meta$downloaded[[1]]))
  expect_true(length(.meta$processed_files) == 1)
  expect_true(file.exists(.meta$processed_files[[1]]))
  .meta <- download_marketdata("b3-reference-rates", refdate = as.Date("2025-03-15"))
  .meta <- read_marketdata(.meta)
  expect_true(is.null(.meta))
})

# This test takes too long
# test_that("it should download and read b3-bvbg-086", {
#   .meta <- download_marketdata("b3-bvbg-086", refdate = as.Date("2018-01-02"))
#   .meta <- read_marketdata(.meta)
#   expect_true(file.exists(meta_file(.meta)))
#   expect_true(length(.meta$downloaded) == 1)
#   expect_true(file.exists(.meta$downloaded[[1]]))
#   expect_true(length(.meta$processed_files) == 1)
#   expect_true(file.exists(.meta$processed_files[[1]]))
# })
