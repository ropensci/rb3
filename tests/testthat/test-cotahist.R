skip_on_cran()
skip_if_offline()

if (Sys.info()["sysname"] == "Linux") {
  httr::set_config(httr::config(ssl_verifypeer = FALSE))
}

test_that("it should download cotahist file", {
  meta <- download_marketdata("b3-cotahist-yearly", year = 2000)
  expect_true(file.exists(meta$downloaded[[1]]))
  expect_true(file.size(meta$downloaded[[1]]) > 1e6)
})

test_that("it should fail the download for cotahist file", {
  expect_true(is.null(meta <- download_marketdata("b3-cotahist-yearly", year = 1900)))
  expect_true(is.null(meta <- download_marketdata("b3-cotahist-daily", refdate = as.Date("2000-01-01"))))
})

.date <- preceding(Sys.Date() - 1, "Brazil/ANBIMA")
fetch_marketdata("b3-cotahist-daily", refdate = .date)
ch_df <- cotahist_get("daily") |>
  filter(refdate == .date) |>
  head(1000) |>
  collect()

test_that("it should get cotahist data", {
  expect_s3_class(ch_df, "data.frame")
  expect_true(nrow(ch_df) == 1000)
  template <- template_retrieve("b3-cotahist-daily")
  names <- fields_names(template$writers$staging$fields)
  expect_equal(sort(colnames(ch_df)), sort(names))
  expect_equal(ncol(ch_df), length(names))
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

  df <- cotahist_filter_equity(ch)
  expect_s3_class(df, "arrow_dplyr_query")
  df <- collect(df)
  expect_type(df$close, "double")
  expect_type(df$trade_quantity, "integer")
  expect_type(df$traded_contracts, "integer")
  expect_true("PETR4" %in% df$symbol)
  expect_false("AAPL34" %in% df$symbol)
  expect_true("TAEE11" %in% df$symbol)
  expect_true(nrow(df) < n)

  df <- cotahist_filter_bdr(ch)
  expect_s3_class(df, "arrow_dplyr_query")
  df <- collect(df)
  expect_type(df$close, "double")
  expect_type(df$trade_quantity, "integer")
  expect_false("PETR4" %in% df$symbol)
  expect_true("AAPL34" %in% df$symbol)
  expect_false("TAEE11" %in% df$symbol)
  expect_true(nrow(df) < n)

  df <- cotahist_filter_unit(ch)
  expect_s3_class(df, "arrow_dplyr_query")
  df <- collect(df)
  expect_type(df$close, "double")
  expect_type(df$trade_quantity, "integer")
  expect_false("PETR4" %in% df$symbol)
  expect_false("AAPL34" %in% df$symbol)
  expect_true("TAEE11" %in% df$symbol)
  expect_true(nrow(df) < n)
})

test_that("it should extract indexes data from cotahist dataset", {
  ch <- cotahist_get("daily")

  df <- cotahist_filter_index(ch) |> collect()
  if (nrow(df) > 0) {
    expect_false("PETR4" %in% df$symbol)
    expect_false("AAPL34" %in% df$symbol)
    expect_false("TAEE11" %in% df$symbol)
    expect_true("IBOV11" %in% df$symbol)
  }
})

test_that("it should extract funds data from cotahist dataset", {
  ch <- cotahist_get("daily")
  df <- cotahist_filter_etf(ch) |> collect()
  expect_true(nrow(df) > 0)

  df <- cotahist_filter_fii(ch) |> collect()
  expect_true(nrow(df) > 0)

  df <- cotahist_filter_fidc(ch) |> collect()
  expect_true(nrow(df) >= 0)

  df <- cotahist_filter_fiagro(ch) |> collect()
  expect_true(nrow(df) >= 0)
})

test_that("it should extract options data from cotahist dataset", {
  symbols <- c("PETR3", "PETR4")
  df <- cotahist_options_by_symbols_get(symbols) |> collect()
  expect_type(df$type, "character")
  expect_s3_class(df$maturity_date, "Date")
  expect_type(df$strike_price, "double")

  ch <- cotahist_get("daily")
  df <- cotahist_filter_equity_options(ch) |> collect()
  expect_true(nrow(df) > 0)
  df <- cotahist_filter_fund_options(ch) |> collect()
  expect_true(nrow(df) > 0)
  df <- cotahist_filter_index_options(ch) |> collect()
  expect_true(nrow(df) > 0)
})
