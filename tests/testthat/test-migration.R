test_that("it should initialize a new SQLite database", {
  # Create a temporary folder for testing
  temp_dir <- tempdir()
  temp_file <- file.path(temp_dir, "test_meta.sqlite")
  
  # Clean up before test
  if (file.exists(temp_file)) {
    file.remove(temp_file)
  }
  
  # Mock the registry to use our test directory
  mockery::stub(meta_db_connection, "rb3_registry$get_instance", list(rb3_folder = temp_dir, sqlite_db_connection = NULL))
  
  # Get connection and check it's valid
  con <- meta_db_connection()
  expect_true(DBI::dbIsValid(con))
  
  # Initialize the database
  mockery::stub(.init_meta_db, "meta_db_connection", con)
  .init_meta_db()
  
  # Verify the meta table was created
  expect_true(DBI::dbExistsTable(con, "meta"))
  
  # Clean up
  DBI::dbDisconnect(con)
})

test_that("migration utility handles cases with no existing DuckDB", {
  # Create a temporary folder for testing
  temp_dir <- tempdir()
  duckdb_path <- file.path(temp_dir, "meta.db")
  
  # Clean up before test
  if (file.exists(duckdb_path)) {
    file.remove(duckdb_path)
  }
  
  # Mock the registry to use our test directory
  mockery::stub(migrate_meta_db_to_sqlite, "rb3_registry$get_instance", list(rb3_folder = temp_dir))
  
  # Should run without error even when no DuckDB exists
  expect_no_error(migrate_meta_db_to_sqlite(backup = FALSE))
})
