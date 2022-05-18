test_that("it should get index composition", {
  x <- index_comp_get("IBOV")
  expect_true(length(x) > 0)
})

test_that("it should get index weights", {
  x <- index_weights_get("IBOV")
  expect_s3_class(x, "data.frame")
  expect_true(ncol(x) == 3)
  expect_equal(colnames(x), c("symbols", "weights", "position"))
  expect_equal(as.integer(sum(x$weights)), 1L)
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