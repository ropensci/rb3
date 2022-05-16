test_that("it should get index composition", {
  x <- index_comp_get("IBOV")
  expect_true(length(x) > 0)
})

test_that("it should get available indexes", {
  x <- indexes_get()
  expect_true(length(x) > 0)
})

test_that("it should get available indexes", {
  x <- indexes_last_update()
  expect_s3_class(x, "Date")
})