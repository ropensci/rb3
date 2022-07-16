
test_that("convert indic to csv", {
  f <- system.file("extdata/Indic.txt", package = "rb3")
  f <- copy_file_to_temp(f)

  res <- convert_to(f, template = "Indic", format = "csv", destdir = tempdir())
  expect_true(file.exists(res))
  unlink(res)
})

test_that("convert indic to json", {
  f <- system.file("extdata/Indic.txt", package = "rb3")
  f <- copy_file_to_temp(f)

  res <- convert_to(f, template = "Indic", format = "json", destdir = tempdir())
  expect_true(file.exists(res))
  unlink(res)
})