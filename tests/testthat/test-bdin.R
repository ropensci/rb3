
test_that("read file using filename to find template", {
  skip_on_cran()

  f <- system.file("extdata/big-files/BDIN", package = "rb3")

  res <- read_marketdata(f)
  expect_s3_class(res, "parts")
  expect_s3_class(res[[1]], "data.frame")
})