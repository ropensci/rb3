test_that("it should read options_open_interest_read", {
  skip_on_cran()
  skip_if_offline()

  f <- system.file("extdata/big-files/OpcoesAcoesEmAberto.zip",
    package = "rb3"
  )
  f <- copy_file_to_temp(f)
  f <- unzip(f, exdir = tempdir())
  df <- read_marketdata(f, "OpcoesAcoesEmAberto")
  expect_s3_class(df, "data.frame")
  df <- read_marketdata(f, "OpcoesAcoesEmAberto", FALSE)
  expect_s3_class(df, "data.frame")
})

test_that("it should read stock_indexes_json_reader", {
  f <- system.file("extdata/GetStockIndex.json", package = "rb3")
  f <- copy_file_to_temp(f)
  df <- read_marketdata(f, "GetStockIndex")
  expect_s3_class(df, "parts")
  expect_equal(names(df), c("Header", "Results"))
  df <- read_marketdata(f, "GetStockIndex", FALSE)
  expect_s3_class(df, "parts")

  f <- system.file("extdata/GetTheoricalPortfolio.json", package = "rb3")
  f <- copy_file_to_temp(f)
  df <- read_marketdata(f, "GetTheoricalPortfolio")
  expect_s3_class(df, "parts")
  expect_equal(names(df), c("Header", "Results"))
  df <- read_marketdata(f, "GetTheoricalPortfolio", FALSE)
  expect_s3_class(df, "parts")
})

test_that("it should read csv_read_file", {
  f <- system.file("extdata/NegociosBalcao.csv", package = "rb3")
  f <- copy_file_to_temp(f)
  df <- suppressWarnings(read_marketdata(f, "NegociosBalcao"))
  expect_s3_class(df, "data.frame")
})

test_that("it should read company_listed_supplement_reader", {
  f <- system.file("extdata/GetListedSupplementCompany.json", package = "rb3")
  f <- copy_file_to_temp(f)
  df <- suppressWarnings(read_marketdata(f, "GetListedSupplementCompany"))
  expect_s3_class(df, "parts")
})

test_that("it should read company_details_reader", {
  f <- system.file("extdata/GetDetailsCompany.json", package = "rb3")
  f <- copy_file_to_temp(f)
  df <- suppressWarnings(read_marketdata(f, "GetDetailsCompany"))
  expect_s3_class(df, "parts")
})

test_that("it should read company_cash_dividends_reader", {
  f <- system.file("extdata/GetListedCashDividends.json", package = "rb3")
  f <- copy_file_to_temp(f)
  df <- suppressWarnings(read_marketdata(f, "GetListedCashDividends"))
  expect_s3_class(df, "data.frame")
})
