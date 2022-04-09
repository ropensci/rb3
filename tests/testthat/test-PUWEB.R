context("Handle file: PUWEB.txt")

test_that("read file using filename to find template", {
  f <- system.file("extdata/PUWEB.TXT", package = "rb3")

  res <- read_marketdata(f)
  expect_is(res, "parts")
  expect_is(res[[1]], "data.frame")
})