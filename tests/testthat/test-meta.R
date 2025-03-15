test_that("it should create a new meta object", {
  template <- template_retrieve("template-test")
  meta <- template_meta_create(template, var1 = 1, var2 = 2)

  expect_equal(meta$template, "template-test")
  args <- list(var1 = 1, var2 = 2) |>
    lapply(format) |>
    toJSON(auto_unbox = TRUE)
  expect_equal(meta$download_args, args)
  checksum <- c(id = "template-test", list(var1 = 1, var2 = 2)) |>
    lapply(format) |>
    digest()
  expect_equal(meta$download_checksum, checksum)
  expect_true(length(meta$downloaded) == 0)
  expect_true(length(meta$processed_files) == 0)
})

test_that("it should save meta", {
  template <- template_retrieve("template-test")
  meta <- template_meta_create(template, var1 = 1, var2 = 2)
  meta_save(meta)
  meta_file <- meta_file(meta)
  expect_true(file.exists(meta_file))
})

test_that("it should load existing meta", {
  template <- template_retrieve("template-test")
  meta0 <- template_meta_create(template, var1 = 1, var2 = 2)
  meta_save(meta0)

  meta1 <- meta_load(template$id, var1 = 1, var2 = 2)
  expect_equal(meta0$created, meta1$created)
})

test_that("it should clean meta", {
  template <- template_retrieve("template-test")
  meta <- template_meta_create(template, var1 = 1, var2 = 2)
  meta_file <- meta_file(meta)
  meta_clean(meta)
  expect_false(file.exists(meta_file))
})
