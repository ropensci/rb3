test_that("it should read options_open_interest_read", {
  f <- download_data("OpcoesAcoesEmAberto", refdate = as.Date("2022-05-10"))
  df <- read_marketdata(f, "OpcoesAcoesEmAberto")
  expect_s3_class(df, "data.frame")
  df <- read_marketdata(f, "OpcoesAcoesEmAberto", FALSE)
  expect_s3_class(df, "data.frame")
})

test_that("it should read stock_indexes_composition_reader", {
  f <- download_data("GetStockIndex")
  df <- read_marketdata(f, "GetStockIndex")
  expect_s3_class(df, "data.frame")
  df <- read_marketdata(f, "GetStockIndex", FALSE)
  expect_s3_class(df, "data.frame")
})