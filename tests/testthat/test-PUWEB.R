
test_that("read PUWEB file with template", {
  f <- system.file("extdata/PUWEB.TXT", package = "rb3")
  f <- copy_file_to_temp(f)

  res <- read_marketdata(f, template = "PUWEB")
  expect_s3_class(res, "parts")
  expect_s3_class(res[[1]], "data.frame")
})