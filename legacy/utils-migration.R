#' Migrate meta database from DuckDB to SQLite
#'
#' This function helps users migrate their existing meta database from DuckDB to SQLite.
#' It copies all data from the old DuckDB database to the new SQLite database.
#'
#' @param backup Logical, whether to create a backup of the old DuckDB database before migration
#'
#' @return Invisible NULL
#'
#' @examples
#' \dontrun{
#' migrate_meta_db_to_sqlite()
#' }
#'
#' @export
migrate_meta_db_to_sqlite <- function(backup = TRUE) {
  reg <- rb3_registry$get_instance()
  duckdb_path <- file.path(reg$rb3_folder, "meta.db")
  sqlite_path <- file.path(reg$rb3_folder, "meta.sqlite")
  
  if (!file.exists(duckdb_path)) {
    cli::cli_inform(c("i" = "No DuckDB database found. No migration needed."))
    return(invisible(NULL))
  }
  
  if (backup) {
    backup_path <- paste0(duckdb_path, ".backup_", format(Sys.time(), "%Y%m%d%H%M%S"))
    file.copy(duckdb_path, backup_path)
    cli::cli_inform(c("v" = "Created backup of DuckDB database at {backup_path}"))
  }
  
  # Connect to both databases
  duck_con <- duckdb::dbConnect(duckdb::duckdb(), duckdb_path)
  on.exit(duckdb::dbDisconnect(duck_con, shutdown = TRUE), add = TRUE)
  
  # Create new SQLite database and schema
  if (file.exists(sqlite_path)) {
    file.remove(sqlite_path)
  }
  
  # Initialize the SQLite database with schema
  .init_meta_db()
  
  # Get SQLite connection
  sqlite_con <- RSQLite::dbConnect(RSQLite::SQLite(), sqlite_path)
  on.exit(DBI::dbDisconnect(sqlite_con), add = TRUE)
  
  # Check if the meta table exists in DuckDB
  if (duckdb::dbExistsTable(duck_con, "meta")) {
    # Copy data
    data <- duckdb::dbGetQuery(duck_con, "SELECT * FROM meta")
    if (nrow(data) > 0) {
      DBI::dbWriteTable(sqlite_con, "meta", data, append = TRUE)
      cli::cli_inform(c("v" = "Migrated {nrow(data)} records from DuckDB to SQLite"))
    } else {
      cli::cli_inform(c("i" = "No data to migrate"))
    }
  } else {
    cli::cli_inform(c("i" = "No meta table found in DuckDB database"))
  }
  
  cli::cli_inform(c("v" = "Migration completed successfully"))
  invisible(NULL)
}
