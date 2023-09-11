
skip_on_cran()
skip_if_offline()

test_that("it should get index composition", {
  x <- index_comp_get("IBOV")
  expect_true(length(x) > 0)
})

test_that("it should get index weights", {
  x <- index_weights_get("IBOV")
  expect_s3_class(x, "data.frame")
  expect_true(ncol(x) == 3)
  expect_equal(colnames(x), c("symbol", "weight", "position"))
  expect_equal(as.integer(round(sum(x$weight), 0)), 1L)
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
  date <- preceding(Sys.Date() - 1, "Brazil/ANBIMA")
  x <- suppressWarnings(indexreport_get(date, do_cache = FALSE))
  expect_s3_class(x, "data.frame")
  expect_true(ncol(x) == 8)
  expect_true(nrow(x) > 0)
  date1 <- preceding(Sys.Date() - 5, "Brazil/ANBIMA")
  x <- suppressWarnings(indexreport_mget(date1, date, do_cache = FALSE))
  expect_s3_class(x, "data.frame")
  expect_true(ncol(x) == 8)
  expect_true(nrow(x) > 0)
})

test_that("it should get index historical data", {
  index_name <- "IBOV"
  x <- index_get(index_name, as.Date("2020-01-01"))
  expect_s3_class(x, "data.frame")
  expect_true(ncol(x) == 3)
  expect_true(nrow(x) > 0)
  expect_equal(format(x$refdate[1], "%Y"), "2020")

  x <- index_get(index_name, as.Date("1997-01-01"))
  expect_s3_class(x, "data.frame")
  expect_true(ncol(x) == 3)
  expect_true(nrow(x) > 0)
  expect_equal(format(x$refdate[1], "%Y"), "1997")

  x <- index_get(index_name, as.Date("1997-01-01"), as.Date("1999-01-01"))
  expect_s3_class(x, "data.frame")
  expect_true(ncol(x) == 3)
  expect_true(nrow(x) > 0)
  expect_equal(format(x$refdate[1], "%Y"), "1997")
  expect_equal(format(x$refdate[nrow(x)], "%Y"), "1998")
})
