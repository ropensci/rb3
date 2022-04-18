skip_on_cran()

test_that("it should download cdi/idi file", {
  f <- download_data("CDIIDI")
  expect_true(file.exists(f))
})

test_that("it should read cdi/idi file", {
  f <- download_data("CDIIDI")
  df <- read_marketdata(f, template = "CDIIDI")
  expect_true(is(df$taxa, "numeric"))
  expect_true(is(df$indice, "numeric"))
  expect_s3_class(df$dataTaxa, "Date")
  expect_s3_class(df$dataIndice, "Date")
})