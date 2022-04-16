
test_that("it should read cdi/idi file", {
  f <- system.file("extdata/CDIIDI.json", package = "rb3")
  df <- read_marketdata(f, template = "CDIIDI")
  expect_true(is(df$taxa, "numeric"))
  expect_true(is(df$indice, "numeric"))
  expect_s3_class(df$dataTaxa, "Date")
  expect_s3_class(df$dataIndice, "Date")
})
