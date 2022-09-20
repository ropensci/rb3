
test_that("read file by template name", {
  f <- system.file("extdata/Indic.txt", package = "rb3")
  f <- copy_file_to_temp(f)
  res <- read_marketdata(f, template = "Indic")

  classes <- c(
    "character", "character", "character", "Date", "character",
    "character", "numeric", "numeric", "character"
  )
  expect_s3_class(res, "data.frame")
})
