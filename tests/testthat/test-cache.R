test_that("cache fcts", {
  this_cachedir <- cachedir()
  expect_true(class(this_cachedir) == "character")
  expect_true(dir.exists(this_cachedir))

  clearcache()
  expect_false(dir.exists(this_cachedir))
})
