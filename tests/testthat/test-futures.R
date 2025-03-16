test_that("it should get futures data with futures_get", {
  skip_on_cran()
  skip_if_offline()

  .refdate <- bizdays::offset(Sys.Date(), -1, "Brazil/ANBIMA")
  .meta <- download_marketdata("b3-futures-settlement-prices", refdate = .refdate)
  read_marketdata(.meta)
  
  df <- futures_get() |> filter(refdate == .refdate)
  expect_true(is(df, "arrow_dplyr_query"))
  
  df <- df |> collect()

  expect_true(nrow(df) > 0)
  expect_true(ncol(df) > 0)
  expect_true(tibble::is_tibble(df))

  expect_s3_class(df$refdate, "Date")
  expect_type(df$symbol, "character")
  expect_type(df$commodity, "character")
  expect_type(df$maturity_code, "character")
  expect_type(df$previous_price, "double")
  expect_type(df$price, "double")
  expect_type(df$price_change, "double")
  expect_type(df$settlement_value, "double")
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
  expect_equal(maturity2date("AGO2", "15th day", refdate = as.Date("2002-01-01")), as.Date("2012-08-15"))
  expect_equal(
    maturity2date(c("F22", "AGO2")),
    c(as.Date("2022-01-01"), as.Date("2002-08-01"))
  )
})
