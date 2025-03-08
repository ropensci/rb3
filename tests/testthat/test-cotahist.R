skip_on_cran()
skip_if_offline()

if (Sys.info()["sysname"] == "Linux") {
  httr::set_config(httr::config(ssl_verifypeer = FALSE))
}

test_that("it should download cotahist file", {
  meta <- download_marketdata("b3-cotahist-yearly", year = 2000)
  expect_true(file.exists(meta$downloaded))
  expect_true(file.size(meta$downloaded) > 1e6)
})

test_that("it should fail the download for cotahist file", {
  expect_true(is.null(meta <- download_marketdata("b3-cotahist-yearly", year = 1900)))
  expect_true(is.null(meta <- download_marketdata("b3-cotahist-daily", refdate = as.Date("2000-01-01"))))
})

.date <- preceding(Sys.Date() - 1, "Brazil/ANBIMA")
.meta <- download_marketdata("b3-cotahist-daily", refdate = .date)
read_marketdata(.meta)
ch_df <- cotahist_get("daily") |>
  filter(refdate == .date) |>
  head(1000) |>
  collect()

test_that("it should get cotahist data", {
  expect_s3_class(ch_df, "data.frame")
  expect_true(nrow(ch_df) == 1000)
  template <- template_retrieve("b3-cotahist-daily")
  expect_true(all(colnames(ch_df) == template$colnames))
  expect_true(ncol(ch_df) == length(template$colnames))
  expect_true(ch_df$refdate[1] == .date)
})

test_that("it should get cotahist dataset", {
  ch <- cotahist_get("daily")
  expect_s3_class(ch, "Dataset")
  expect_s3_class(ch, "ArrowObject")
})

test_that("it should extract equity data from cotahist dataset", {
  ch <- cotahist_get("daily")
  n <- ch |>
    dplyr::count() |>
    collect() |>
    dplyr::pull()
  nc <- ch |>
    head(10) |>
    collect() |>
    ncol()

  df <- cotahist_equity_get(ch)
  expect_type(df$close, "double")
  expect_type(df$trade_quantity, "integer")
  expect_type(df$traded_contracts, "integer")
  expect_true("PETR4" %in% df$symbol)
  expect_false("AAPL34" %in% df$symbol)
  expect_true("TAEE11" %in% df$symbol)
  expect_true(nrow(df) < n)
  expect_true(ncol(df) == 11)
  expect_true(ncol(df) < nc)

  df <- cotahist_bdrs_get(ch)
  expect_type(df$close, "double")
  expect_type(df$trade_quantity, "integer")
  expect_false("PETR4" %in% df$symbol)
  expect_true("AAPL34" %in% df$symbol)
  expect_false("TAEE11" %in% df$symbol)
  expect_true(nrow(df) < n)
  expect_true(ncol(df) == 11)
  expect_true(ncol(df) < nc)

  df <- cotahist_units_get(ch)
  expect_type(df$close, "double")
  expect_type(df$trade_quantity, "integer")
  expect_false("PETR4" %in% df$symbol)
  expect_false("AAPL34" %in% df$symbol)
  expect_true("TAEE11" %in% df$symbol)
  expect_true(nrow(df) < n)
  expect_true(ncol(df) == 11)
  expect_true(ncol(df) < nc)
})

test_that("it should extract indexes data from cotahist dataset", {
  ch <- cotahist_get("daily")

  df <- cotahist_indexes_get(ch)
  if (nrow(df) > 0) {
    expect_false("PETR4" %in% df$symbol)
    expect_false("AAPL34" %in% df$symbol)
    expect_false("TAEE11" %in% df$symbol)
    expect_true("IBOV11" %in% df$symbol)
  }
})

test_that("it should extract funds data from cotahist dataset", {
  ch <- cotahist_get("daily")
  df <- cotahist_etfs_get(ch)
  expect_true(nrow(df) > 0)

  df <- cotahist_fiis_get(ch)
  expect_true(nrow(df) > 0)

  df <- cotahist_fidcs_get(ch)
  expect_true(nrow(df) >= 0)

  df <- cotahist_fiagros_get(ch)
  expect_true(nrow(df) >= 0)
})

test_that("it should extract specific symbols from cotahist dataset", {
  symbols <- c("PETR3", "PETR4")
  ch <- cotahist_get("daily")
  nc <- ch |>
    head(10) |>
    collect() |>
    ncol()

  df <- cotahist_get_symbols(ch, symbols)
  expect_true(length(symbols) == nrow(df))
  expect_true(nc == ncol(df))
})

test_that("it should extract options data from cotahist dataset", {
  ch <- cotahist_get("daily")
  
  df <- cotahist_equity_options_get(ch)
  expect_s3_class(df$type, "factor")
  expect_s3_class(df$maturity_date, "Date")
  expect_type(df$strike_price, "double")
  
  df <- cotahist_funds_options_get(ch)
  expect_true(nrow(df) > 0)
  df <- cotahist_index_options_get(ch)
  expect_true(nrow(df) > 0)
})

test_that("it should use cotahist_equity_options_superset", {
  .meta <- download_marketdata("b3-reference-rates", refdate = .date, curve_name = "PRE")
  read_marketdata(.meta)

  yc <- yc_get(.date)
  ch <- cotahist_get("daily")

  df <- cotahist_equity_options_superset(ch, yc)
  expect_true(!anyNA(df))
  df <- cotahist_options_by_symbol_superset("PETR4", ch, yc)
  expect_true(!anyNA(df))
})
