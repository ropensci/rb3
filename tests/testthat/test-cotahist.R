skip_on_cran()

test_that("it should download cotahist file", {
  f <- download_data("COTAHIST", refdate = as.Date(ISOdate(2000, 1, 1)))
  expect_true(file.exists(f))
  expect_true(file.size(f) > 1e6)
})

test_that("it should get cotahist data", {
  ch <- suppressWarnings(cotahist_get(2000))
  expect_s3_class(ch, "parts")
  expect_true(length(ch) == 3)
  expect_true(nrow(ch[["HistoricalPrices"]]) > 1000)
})