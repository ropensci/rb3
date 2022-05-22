if (!covr::in_covr()) {
  skip_on_cran()
  skip_if_offline()
}

test_that("it should get index composition", {
  x <- index_comp_get("IBOV")
  expect_true(length(x) > 0)
})

test_that("it should get index weights", {
  x <- index_weights_get("IBOV")
  expect_s3_class(x, "data.frame")
  expect_true(ncol(x) == 3)
  expect_equal(colnames(x), c("symbol", "weight", "position"))
  expect_equal(as.integer(sum(x$weight)), 1L)
  expect_true(nrow(x) > 0)
})

test_that("it should get available indexes", {
  x <- indexes_get()
  expect_true(length(x) > 0)
})

test_that("it should get available indexes", {
  x <- indexes_last_update()
  expect_s3_class(x, "Date")
})

test_that("it should get index by segments", {
  x <- index_by_segment_get("IBOV")
  expect_s3_class(x, "data.frame")
  expect_true(ncol(x) == 6)
  expect_equal(as.integer(sum(x$weight)), 1L)
  expect_true(nrow(x) > 0)
})

test_that("it should get indexreport", {
  date <- preceding(Sys.Date() - 1, "Brazil/B3")
  x <- suppressWarnings(indexreport_get(date))
  expect_s3_class(x, "data.frame")
  expect_true(ncol(x) == 8)
  expect_true(nrow(x) > 0)
  date1 <- preceding(Sys.Date() - 5, "Brazil/B3")
  x <- suppressWarnings(indexreport_mget(date1, date))
  expect_s3_class(x, "data.frame")
  expect_true(ncol(x) == 8)
  expect_true(nrow(x) > 0)
})