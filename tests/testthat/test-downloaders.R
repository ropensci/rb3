
skip_on_cran()

test_that("it should download a file with a simple downloader", {
  tpl <- .retrieve_template(NULL, "CDIIDI")
  dest <- tempfile()
  expect_true(tpl$download_data(dest))
  expect_true(file.exists(dest))
})

test_that("it should download a file with a datetime downloader", {
  tpl <- .retrieve_template(NULL, "COTAHIST_YEARLY")
  dest <- tempfile()
  expect_false(tpl$download_data(dest))
  expect_false(file.exists(dest))
  skip_on_os("linux")
  expect_true(tpl$download_data(dest, refdate = Sys.Date()))
  expect_true(file.exists(dest))
  info <- file.info(dest)
  expect_true(info$size > 1000000)
})