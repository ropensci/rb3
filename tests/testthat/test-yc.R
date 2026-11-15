skip_on_cran()
skip_if_offline()

test_df <- function(df_in) {
  expect_true(nrow(df_in) > 0)
  expect_true(ncol(df_in) > 0)
  expect_true(tibble::is_tibble(df_in))

  invisible(TRUE)
}

.refdate <- bizdays::offset(Sys.Date(), -5, "Brazil/ANBIMA")
suppressMessages(fetch_marketdata("b3-futures-settlement-prices", refdate = .refdate))
suppressMessages(fetch_marketdata("b3-reference-rates", refdate = .refdate))

test_that("Test of yc_get function", {
  df_yc_1 <- yc_get()
  expect_true(is(df_yc_1, "arrow_dplyr_query") || is(df_yc_1, "ArrowObject"))
  df <- df_yc_1 |> collect()
  test_df(df)
  expect_true(all(c("DIC", "DOC", "PRE") %in% df$curve_name))
})

test_that("it should check if curve name is correct", {
  cn <- yc_brl_get() |>
    dplyr::distinct(curve_name) |>
    collect()
  expect_true(cn == "PRE")
})

test_that("Test of yc_brl_get function", {
  df_yc_1 <- yc_brl_get()
  expect_true(is(df_yc_1, "arrow_dplyr_query") || is(df_yc_1, "ArrowObject"))
  df <- df_yc_1 |> collect()
  test_df(df)
  expect_equal(df$refdate + df$cur_days, df$forward_date)
})

test_that("Test of yc_ipca_get function", {
  df_yc_2 <- yc_ipca_get()
  test_df(df_yc_2 |> collect())
})

test_that("Test of yc_usd_get function", {
  df_yc_2 <- yc_usd_get()
  test_df(df_yc_2 |> collect())
})

test_that("Test of yc_with_futures function", {
  df <- yc_brl_with_futures_get(.refdate)
  expect_true(exists("symbol", df))
  expect_true(nrow(df) > 0)
  expect_true(anyNA(df$symbol))
  
  df <- yc_usd_with_futures_get(.refdate)
  expect_true(exists("symbol", df))
  expect_true(nrow(df) > 0)
  expect_true(anyNA(df$symbol))
  
  df <- yc_ipca_with_futures_get(.refdate)
  expect_true(exists("symbol", df))
  expect_true(nrow(df) > 0)
  expect_true(anyNA(df$symbol))
})

test_that("yc_brl_curve_get returns a SpotRateCurve with 1-day and DI1 vertices", {
  skip_if_not_installed("fixedincome")
  df <- yc_brl_with_futures_get(.refdate)
  curve <- yc_brl_curve_get(.refdate)
  expect_s4_class(curve, "SpotRateCurve")
  expect_equal(curve@refdate, .refdate)
  terms <- as.numeric(curve@terms)
  expect_equal(terms[1], 1)
  expect_false(anyDuplicated(terms) > 0)
  expect_equal(length(curve), length(unique(c(1, df$biz_days[!is.na(df$symbol)]))))
})
