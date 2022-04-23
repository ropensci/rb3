
test_that("it should get futures data", {
  if (!covr::in_covr()) {
    skip_on_cran()
    skip_if_offline()
  }

  first_date <- Sys.Date() - 5
  last_date <- Sys.Date()

  df_yc_1 <- futures_get(first_date, last_date, do_cache = FALSE)

  expect_true(nrow(df_yc_1) > 0)
  expect_true(ncol(df_yc_1) > 0)
  expect_true(tibble::is_tibble(df_yc_1))

  df_yc_2 <- futures_get(first_date, last_date)

  expect_true(nrow(df_yc_2) > 0)
  expect_true(ncol(df_yc_2) > 0)
  expect_true(tibble::is_tibble(df_yc_2))

  expect_identical(df_yc_1, df_yc_2)
})