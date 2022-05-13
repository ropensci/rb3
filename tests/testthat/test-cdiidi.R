if (!covr::in_covr()) {
  skip_on_cran()
}

test_that("it should download cdi/idi file", {
  f <- download_marketdata("CDIIDI")
  expect_true(file.exists(f))
})

test_that("it should read cdi/idi file", {
  f <- download_marketdata("CDIIDI")
  df <- read_marketdata(f, template = "CDIIDI")
  expect_true(is(df$taxa, "numeric"))
  expect_true(is(df$indice, "numeric"))
  expect_s3_class(df$dataTaxa, "Date")
  expect_s3_class(df$dataIndice, "Date")
})

test_that("it should get cdi rates", {
  df <- cdi_get()
  expect_s3_class(df$refdate, "Date")
  expect_true(is(df$CDI, "numeric"))
})

test_that("it should get idi index", {
  df <- idi_get()
  expect_s3_class(df$refdate, "Date")
  expect_true(is(df$IDI, "numeric"))
})