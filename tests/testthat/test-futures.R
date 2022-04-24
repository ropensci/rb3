
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

test_that("it should test code2month", {
  codes <- c("F", "G", "H", "J", "K", "M", "N", "Q", "U", "V", "X", "Z")
  months <- code2month(codes)
  expect_equal(months, 1:12)
  expect_true(is.na(code2month("A")))
})

test_that("it should test maturity2date", {
  expect_equal(maturity2date("F22"), as.Date("2022-01-01"))
  expect_equal(maturity2date("F22", "15th day"), as.Date("2022-01-15"))
})