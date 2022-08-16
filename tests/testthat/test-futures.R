
test_that("it should get futures data with futures_mget", {
  skip_on_cran()
  skip_if_offline()

  first_date <- Sys.Date() - 5
  last_date <- Sys.Date()

  df_yc_1 <- futures_mget(first_date, last_date, do_cache = FALSE)

  expect_true(nrow(df_yc_1) > 0)
  expect_true(ncol(df_yc_1) > 0)
  expect_true(tibble::is_tibble(df_yc_1))

  df_yc_2 <- futures_mget(first_date, last_date)

  expect_true(nrow(df_yc_2) > 0)
  expect_true(ncol(df_yc_2) > 0)
  expect_true(tibble::is_tibble(df_yc_2))

  expect_identical(df_yc_1, df_yc_2)
})

test_that("it should get futures data with futures_get", {
  skip_on_cran()
  skip_if_offline()

  refdate <- bizdays::offset(Sys.Date(), -1, "Brazil/ANBIMA")

  df_yc_1 <- futures_get(refdate, do_cache = FALSE)

  expect_true(nrow(df_yc_1) > 0)
  expect_true(ncol(df_yc_1) > 0)
  expect_true(tibble::is_tibble(df_yc_1))

  df_yc_2 <- futures_get(refdate)

  expect_true(nrow(df_yc_2) > 0)
  expect_true(ncol(df_yc_2) > 0)
  expect_true(tibble::is_tibble(df_yc_2))

  expect_identical(df_yc_1, df_yc_2)
})

test_that("it should test code2month", {
  months <- code2month("F")
  expect_equal(months, 1)
  codes <- c("F", "G", "H", "J", "K", "M", "N", "Q", "U", "V", "X", "Z")
  months <- code2month(codes)
  expect_equal(months, 1:12)
  expect_true(is.na(code2month("A")))

  # old codes
  months <- code2month("JAN")
  expect_equal(months, 1)
  codes <- c(
    "JAN", "FEV", "MAR", "ABR", "MAI", "JUN",
    "JUL", "AGO", "SET", "OUT", "NOV", "DEZ"
  )
  months <- code2month(codes)
  expect_equal(months, 1:12)
  expect_true(is.na(code2month("ZZZ")))

  # mix
  months <- code2month(c("F", "MAR"))
  expect_equal(months, c(1, 3))
})

test_that("it should test maturity2date", {
  expect_equal(maturity2date("F22"), as.Date("2022-01-01"))
  expect_equal(maturity2date("F22", "15th day"), as.Date("2022-01-15"))
  expect_equal(maturity2date("AGO2"), as.Date("2002-08-01"))
  expect_equal(maturity2date("AGO2", "15th day"), as.Date("2002-08-15"))
  expect_equal(
    maturity2date(c("F22", "AGO2")),
    c(as.Date("2022-01-01"), as.Date("2002-08-01"))
  )
})
