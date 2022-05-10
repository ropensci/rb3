
test_df <- function(df_in) {
  expect_true(nrow(df_in) > 0)
  expect_true(ncol(df_in) > 0)
  expect_true(tibble::is_tibble(df_in))

  return(invisible(TRUE))
}

test_that("Test of yc_mget function", {
  if (!covr::in_covr()) {
    skip_on_cran()
    skip_if_offline()
  }

  first_date <- Sys.Date() - 50
  last_date <- Sys.Date()

  # first call (no cache)
  df_yc_1 <- yc_mget(first_date,
    last_date,
    by = 5,
    do_cache = FALSE
  )

  test_df(df_yc_1)

  # first call (with cache)
  df_yc_2 <- yc_mget(first_date,
    last_date,
    by = 5
  )

  test_df(df_yc_2)

  expect_identical(df_yc_1, df_yc_2)
})

test_that("Test of yc_get function", {
  if (!covr::in_covr()) {
    skip_on_cran()
    skip_if_offline()
  }

  refdate <- bizdays::offset(Sys.Date(), -30, "Brazil/ANBIMA")

  # first call (no cache)
  df_yc_1 <- yc_get(refdate, do_cache = FALSE)

  test_df(df_yc_1)

  # first call (with cache)
  df_yc_2 <- yc_get(refdate)

  test_df(df_yc_2)

  expect_identical(df_yc_1, df_yc_2)
})

