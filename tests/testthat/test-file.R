
test_that("handle filename", {
  fname <- Filename$new(name = "Indic.txt")
  expect_equal(fname$getExt(), ".txt")
  expect_equal(fname$changeExt(".csv"), "Indic.csv")
  expect_equal(fname$getFilenameSansExt(), "Indic")
  expect_equal(fname$getBasename(), "Indic.txt")
  expect_equal(fname$getDirname(), ".")
  expect_false(fname$exists())

  fname <- Filename$new(name = "/tmp/extdata/Indic.txt")
  expect_equal(fname$getExt(), ".txt")
  expect_equal(fname$changeExt(".csv"), "/tmp/extdata/Indic.csv")
  expect_equal(fname$getFilenameSansExt(), "/tmp/extdata/Indic")
  expect_equal(fname$getBasename(), "Indic.txt")
  expect_equal(fname$getDirname(), "/tmp/extdata")
  expect_false(fname$exists())

  fname <- Filename$new(name = "C:\\Temp\\extdata\\Indic.txt")
  expect_equal(fname$getExt(), ".txt")
  expect_equal(fname$changeExt(".csv"), "C:/Temp/extdata/Indic.csv")
  expect_equal(fname$getFilenameSansExt(), "C:/Temp/extdata/Indic")
  expect_equal(fname$getBasename(), "Indic.txt")
  expect_equal(fname$getDirname(), "C:/Temp/extdata")
  expect_false(fname$exists())

  expect_equal(
    fname$changeExt(".csv", "C:\\Temp\\inst\\extdata"),
    "C:/Temp/inst/extdata/Indic.csv"
  )
})
