
test_that("read file using filename to find template", {
  f <- system.file("extdata/Indic.txt", package = "rb3")
  res <- read_marketdata(f)
  expect_s3_class(res, "data.frame")
})

test_that("read file by template name", {
  f <- system.file("extdata/Indic.txt", package = "rb3")
  res <- read_marketdata(f, template = "Indic")

  classes <- c(
    "character", "character", "character", "Date", "character",
    "character", "numeric", "numeric", "character"
  )
  expect_s3_class(res, "data.frame")
})