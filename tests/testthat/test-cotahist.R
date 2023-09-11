skip_on_cran()
skip_if_offline()

if (Sys.info()["sysname"] == "Linux") {
  httr::set_config(httr::config(ssl_verifypeer = FALSE))
}

test_that("it should download cotahist file", {
  f <- download_marketdata("COTAHIST_YEARLY",
    refdate = as.Date(ISOdate(2000, 1, 1))
  )
  expect_true(file.exists(f))
  expect_true(file.size(f) > 1e6)
})

test_that("it should fail the download for cotahist file", {
  expect_true(is.null(cotahist_get("2022-05-15", "daily")))
})

date <- preceding(Sys.Date() - 1, "Brazil/ANBIMA")
ch <- cotahist_get(date, "daily")
test_that("it should get cotahist data", {
  expect_s3_class(ch, "parts")
  expect_true(length(ch) == 3)
  expect_true(nrow(ch[["HistoricalPrices"]]) > 1000)
})

test_that("it should extract equity data from cotahist dataset", {
  df <- cotahist_equity_get(ch)
  expect_type(df$close, "double")
  expect_type(df$transactions_quantity, "integer")
  expect_type(df$traded_contracts, "double")
  df <- cotahist_bdrs_get(ch)
  expect_type(df$close, "double")
  expect_type(df$transactions_quantity, "integer")
  df <- cotahist_units_get(ch)
  expect_type(df$close, "double")
  expect_type(df$transactions_quantity, "integer")
})

test_that("it should extract indexes data from cotahist dataset", {
  df <- cotahist_indexes_get(ch)
  expect_type(df$close, "double")
  expect_type(df$transactions_quantity, "integer")
})

test_that("it should extract funds data from cotahist dataset", {
  df <- cotahist_etfs_get(ch)
  expect_type(df$close, "double")
  expect_type(df$transactions_quantity, "integer")
  expect_true(nrow(df) > 0)
  df <- cotahist_fiis_get(ch)
  expect_type(df$close, "double")
  expect_type(df$transactions_quantity, "integer")
  expect_true(nrow(df) > 0)
  # df <- cotahist_fidcs_get(ch)
  # expect_type(df$close, "double")
  # expect_type(df$transactions_quantity, "integer")
  # expect_true(nrow(df) > 0)
  df <- cotahist_fiagros_get(ch)
  expect_type(df$close, "double")
  expect_type(df$transactions_quantity, "integer")
  expect_true(nrow(df) > 0)
})

test_that("it should extract options data from cotahist dataset", {
  df <- cotahist_equity_options_get(ch)
  expect_type(df$close, "double")
  expect_type(df$transactions_quantity, "integer")
  expect_s3_class(df$type, "factor")
  expect_s3_class(df$maturity_date, "Date")
  expect_type(df$strike, "double")
  df <- cotahist_funds_options_get(ch)
  expect_true(nrow(df) > 0)
  df <- cotahist_index_options_get(ch)
  expect_true(nrow(df) > 0)
})

test_that("it should extract specific symbols from cotahist dataset", {
  symbols <- c("PETR3", "PETR4")
  df <- cotahist_get_symbols(ch, symbols)
  expect_equal(length(symbols), nrow(df))
})

test_that("it should use cotahist_equity_options_superset", {
  yc <- yc_get(date)
  df <- cotahist_equity_options_superset(ch, yc)
  expect_true(!anyNA(df))
  df <- cotahist_options_by_symbol_superset("PETR4", ch, yc)
  expect_true(!anyNA(df))
})
