if (!covr::in_covr()) {
  skip_on_cran()
  skip_if_offline()
}

if (Sys.info()["sysname"] == "Linux") {
  httr::set_config(config(ssl_verifypeer = FALSE))
}

test_that("it should download cotahist file", {
  f <- download_marketdata("COTAHIST_YEARLY", refdate = as.Date(ISOdate(2000, 1, 1)))
  expect_true(file.exists(f))
  expect_true(file.size(f) > 1e6)
})

ch <- suppressWarnings(cotahist_get(ISOdate(2000, 1, 1)))
test_that("it should get cotahist data", {
  expect_s3_class(ch, "parts")
  expect_true(length(ch) == 3)
  expect_true(nrow(ch[["HistoricalPrices"]]) > 1000)
})

test_that("it should extract equity data from cotahist dataset", {
  df <- cotahist_equity_get(ch)
  expect_type(df$close, "double")
  expect_type(df$transactions_quantity, "integer")
})

test_that("it should extract options data from cotahist dataset", {
  df <- cotahist_equity_options_get(ch)
  expect_type(df$close, "double")
  expect_type(df$transactions_quantity, "integer")
  expect_s3_class(df$type, "factor")
  expect_s3_class(df$maturity_date, "Date")
  expect_type(df$strike, "double")
})