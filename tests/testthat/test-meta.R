test_that("it should create a new meta object", {
  meta <- meta_new("template-test", var1 = 1, var2 = 2)

  expect_equal(meta$template, "template-test")
  args <- list(var1 = 1, var2 = 2) |>
    lapply(format) |>
    jsonlite::toJSON(auto_unbox = TRUE)
  expect_equal(meta$download_args, args)
  checksum <- c(id = "template-test", list(var1 = 1, var2 = 2)) |>
    lapply(format) |>
    digest::digest()
  expect_equal(meta$download_checksum, checksum)
  expect_true(length(meta$downloaded) == 0)
  meta_clean(meta)
})

test_that("it should save meta", {
  meta <- meta_new("template-test", var1 = 1, var2 = 2)
  meta_save(meta)
  meta_file <- meta_file(meta)
  expect_true(file.exists(meta_file))
  meta_clean(meta)
})

test_that("it should load existing meta", {
  meta0 <- meta_new("template-test", var1 = 1, var2 = 2)
  meta_save(meta0)

  meta1 <- meta_load("template-test", var1 = 1, var2 = 2)
  expect_equal(meta0$created, meta1$created)
  meta_clean(meta1)
})

test_that("it should clean meta", {
  meta <- meta_new("template-test", var1 = 1, var2 = 2)
  meta_file <- meta_file(meta)
  meta_clean(meta)
  expect_false(file.exists(meta_file))
})

test_that("it should add download to meta", {
  meta <- meta_new("template-test", var1 = 1, var2 = 2)
  filename <- tempfile()
  meta_add_download(meta) <- filename
  expect_equal(meta$downloaded[[1]], filename)
  filename <- tempfile()
  meta_add_download(meta) <- filename
  expect_equal(meta$downloaded[[2]], filename)
  meta_add_download(meta) <- filename
  expect_true(length(meta$downloaded) == 2)
  meta_clean(meta)
})
