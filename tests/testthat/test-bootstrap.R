test_that("it should check rb3 folders", {
  reg <- rb3_registry$get_instance()
  expect_true(dir.exists(reg[["rb3_folder"]]))
  expect_true(dir.exists(reg[["raw_folder"]]))
  expect_true(dir.exists(reg[["db_folder"]]))
})

test_that("it should check rb3 duckdb connection", {
  reg <- rb3_registry$get_instance()
  expect_true("duck_db_connection" %in% names(reg))
  
  con <- meta_db_connection()
  expect_true(duckdb::dbIsValid(con))
})
