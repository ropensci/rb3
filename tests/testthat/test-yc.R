skip_on_cran()
skip_if_offline()

test_df <- function(df_in) {
  expect_true(nrow(df_in) > 0)
  expect_true(ncol(df_in) > 0)
  expect_true(tibble::is_tibble(df_in))

  invisible(TRUE)
}

refdate <- bizdays::offset(Sys.Date(), -1, "Brazil/ANBIMA")
.meta <- download_marketdata("b3-futures-settlement-prices", refdate = refdate)
read_marketdata(.meta)
.meta <- download_marketdata("b3-reference-rates", refdate = refdate, curve_name = "PRE")
read_marketdata(.meta)
.meta <- download_marketdata("b3-reference-rates", refdate = refdate, curve_name = "DOC")
read_marketdata(.meta)
.meta <- download_marketdata("b3-reference-rates", refdate = refdate, curve_name = "DIC")
read_marketdata(.meta)

test_that("Test of yc_get function", {
  df_yc_1 <- yc_get(refdate)
  test_df(df_yc_1)
})

test_that("Test of yc_ipca_get function", {
  df_yc_2 <- yc_ipca_get(refdate)
  test_df(df_yc_2)
})

test_that("Test of yc_usd_get function", {
  df_yc_2 <- yc_usd_get(refdate)
  test_df(df_yc_2)
})

test_that("Test of yc_superset function", {
  fut <- futures_get(refdate)
  yc <- yc_get(refdate)
  df <- yc_superset(yc, fut)
  expect_true(exists("symbol", df))
  expect_true(anyNA(df$symbol))
  yc <- yc_usd_get(refdate)
  df <- yc_usd_superset(yc, fut)
  expect_true(exists("symbol", df))
  expect_true(anyNA(df$symbol))
  yc <- yc_ipca_get(refdate)
  df <- yc_ipca_superset(yc, fut)
  expect_true(exists("symbol", df))
  expect_true(anyNA(df$symbol))
})
