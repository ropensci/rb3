test_that("it should read options_open_interest_read", {
  if (!covr::in_covr()) {
    skip_on_cran()
    skip_if_offline()
  }

  f <- system.file("extdata/big-files/OpcoesAcoesEmAberto.zip",
    package = "rb3"
  )
  f <- unzip(f, exdir = tempdir())
  df <- read_marketdata(f, "OpcoesAcoesEmAberto")
  expect_s3_class(df, "data.frame")
  df <- read_marketdata(f, "OpcoesAcoesEmAberto", FALSE)
  expect_s3_class(df, "data.frame")
})

test_that("it should read stock_indexes_composition_reader", {
  f <- system.file("extdata/GetStockIndex.json", package = "rb3")
  df <- read_marketdata(f, "GetStockIndex")
  expect_s3_class(df, "parts")
  expect_equal(names(df), c("Header", "Results"))
  df <- read_marketdata(f, "GetStockIndex", FALSE)
  expect_s3_class(df, "parts")
})