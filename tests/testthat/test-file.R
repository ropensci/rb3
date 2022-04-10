
test_that("handle filename", {
  fname <- Filename$new(name = "Indic.txt")
  expect_equal(fname$getExt(), ".txt")

  fname <- Filename$new(name = "../../inst/extdata/Indic.txt")
  expect_equal(fname$getExt(), ".txt")
  expect_equal(fname$changeExt("csv"), "../../inst/extdata/Indic.csv")
  expect_equal(fname$getBasename(), "../../inst/extdata/Indic")
})