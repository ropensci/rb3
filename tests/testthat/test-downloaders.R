
test_that("it should create a simple downloader using a template", {
  tpl <- .retrieve_template(NULL, "CDIIDI")
  dl <- downloaders_factory(tpl$downloader)
  expect_s3_class(dl, "simple")
  expect_s3_class(dl, "downloader")
  expect_true(!is.null(dl$url))
  expect_equal(dl$format, "json")
  expect_equal(dl$encoding, "utf8")
})

test_that("it should download a file with a simple downloader", {
  tpl <- .retrieve_template(NULL, "CDIIDI")
  dl <- downloaders_factory(tpl$downloader)
  dest <- tempfile()
  expect_true(download_file(dl, dest))
  expect_true(file.exists(dest))
})

test_that("it should create a datetime downloader using a template", {
  tpl <- .retrieve_template(NULL, "COTAHIST")
  dl <- downloaders_factory(tpl$downloader)
  expect_s3_class(dl, "datetime")
  expect_s3_class(dl, "downloader")
  expect_true(!is.null(dl$url))
  expect_equal(dl$format, "zip")
})

test_that("it should download a file with a datetime downloader", {
  tpl <- .retrieve_template(NULL, "COTAHIST")
  dl <- downloaders_factory(tpl$downloader)
  dest <- tempfile()
  expect_false(download_file(dl, dest))
  expect_false(file.exists(dest))
  expect_true(download_file(dl, dest, refdate = Sys.Date()))
  expect_true(file.exists(dest))
})

