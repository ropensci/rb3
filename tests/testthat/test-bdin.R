
context("Handle file: BDIN")

test_that("read file using filename to find template", {
  f <- system.file("extdata/BDIN", package = "rb3")

  res <- read_marketdata(f)
  expect_is(res, "parts")
  expect_is(res[[1]], "data.frame")
})