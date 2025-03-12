test_that("it should check rb3 folders", {
  reg <- rb3_registry$get_instance()
  expect_true(dir.exists(registry_get(reg, "rb3_folder")))
  expect_true(dir.exists(registry_get(reg, "raw_folder")))
  expect_true(dir.exists(registry_get(reg, "meta_folder")))
  expect_true(dir.exists(registry_get(reg, "db_folder")))
})
