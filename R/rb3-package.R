#' @title `rb3.cachedir` Option
#'
#' @description
#' The `rb3.cachedir` option is used to specify the directory where cached data 
#' will be stored when using the `rb3` package. This option allows users to 
#' define a custom directory for caching, which can improve performance by 
#' avoiding repeated downloads or computations.
#'
#' @details
#' 
#' ### Setting the `rb3.cachedir` Option
#'
#' To set the `rb3.cachedir` option, use the `options()` function and provide 
#' the desired directory path as a string. For example:
#'
#' ```r
#' # Set the cache directory to a custom path
#' options(rb3.cachedir = "/path/to/your/cache/directory")
#' ```
#'
#' Replace `"/path/to/your/cache/directory"` with the actual path where you want 
#' the cached data to be stored.
#'
#' ### Viewing the Current Value of `rb3.cachedir`
#'
#' To check the current value of the `rb3.cachedir` option, use the `getOption()` 
#' function:
#'
#' ```r
#' # View the current cache directory
#' getOption("rb3.cachedir")
#' ```
#'
#' This will return the path to the directory currently set for caching, or 
#' `NULL` if the option has not been set.
#'
#' ### Notes
#'
#' - Ensure that the specified directory exists and is writable.
#' - If the `rb3.cachedir` option is not set, the package use a temporary directory (`base::tempdir()`).
#' 
#' @examples
#' # Set the cache directory
#' options(rb3.cachedir = "~/rb3_cache")
#'
#' # Verify the cache directory
#' cache_dir <- getOption("rb3.cachedir")
#' print(cache_dir)
#'
#' # In this example, the cache directory is set to `~/rb3_cache`, and the value 
#' # is then retrieved and printed to confirm the setting.
#'
#' @name rb3.cachedir
NULL

#' @title Access and Process B3 Data
#'
#' @description
#' The `rb3` package provides tools for accessing, processing, and analyzing 
#' public files from B3, the Brazilian Stock Exchange. It facilitates the 
#' handling of various datasets published by B3, including financial market 
#' data, metadata, and auxiliary files.
#' 
#' The package supports efficient data 
#' storage and querying through Arrow datasets and offers utilities 
#' for managing datasets to optimize workflows. With `rb3`, users can 
#' streamline the process of transforming raw B3 data into actionable insights 
#' for analysis and reporting.
#' 
#' @importFrom bizdays following preceding load_builtin_calendars
#' @importFrom bizdays add.bizdays bizdayse bizseq getdate
#' @importFrom dplyr mutate select filter collect
#' @importFrom rlang .data
#' @importFrom stringr str_replace_all str_starts str_match str_sub str_split str_ends str_replace str_c
#' @importFrom stringr str_to_lower str_detect str_pad str_replace str_trim str_glue str_length
#' @keywords internal
"_PACKAGE"

rb3_registry <- create_registry()

#' Initialize the rb3 package cache folders
#' 
#' This function sets up the necessary directory structure for caching rb3 data.
#' It creates a main cache folder and three subfolders: 'raw', 'meta', and 'db'.
#' The folder paths are stored in the rb3 registry for later use.
#' 
#' @details
#' The function first checks if the 'rb3.cachedir' option is set. If not, it uses
#' a subfolder in the temporary directory. It creates the main cache folder and 
#' the three subfolders if they don't already exist, then stores their paths in 
#' the rb3 registry.
#' 
#' The cache structure includes:
#' \itemize{
#'   \item raw folder - for storing raw downloaded data
#'   \item meta folder - for storing metadata
#'   \item db folder - for database files
#' }
#' 
#' @examples
#' \dontrun{
#' options(rb3.cachedir = "~/rb3-cache")
#' rb3_bootstrap()
#' }
#' 
#' @export
rb3_bootstrap <- function() {
  cache_folder <- getOption("rb3.cachedir")
  cache_folder <- if (is.null(cache_folder)) {
    cli::cli_alert_info("Option rb3.cachedir not set using {.fn tempdir}")
    file.path(tempdir(), "rb3-cache")
  } else {
    cache_folder
  }
  cli::cli_alert_info("rb3 cache folder: {.file {cache_folder}}")
  
  if (!dir.exists(cache_folder)) {
    dir.create(cache_folder, recursive = TRUE)
  }

  raw_folder <- file.path(cache_folder, "raw")
  if (!dir.exists(raw_folder)) {
    dir.create(raw_folder, recursive = TRUE)
  }

  db_folder <- file.path(cache_folder, "db")
  if (!dir.exists(db_folder)) {
    dir.create(db_folder, recursive = TRUE)
  }

  .reg <- rb3_registry$get_instance()
  .reg[["rb3_folder"]] <- cache_folder
  .reg[["raw_folder"]] <- raw_folder
  .reg[["db_folder"]] <- db_folder
  .init_meta_db()
  invisible(NULL)
}

#' Returns a DuckDB Database Connection for the RB3 Package
#'
#' This function provides a consistent way to connect to the DuckDB database used by the RB3 package.
#' It returns an existing connection if one is already established and valid, or creates a new
#' connection if needed.
#'
#' @return A DuckDB connection object
#'
#' @examples
#' # Get a connection to the RB3 database
#' con <- rb3_duckdb_connection()
#'
#' @details
#' The function first checks if a valid connection already exists in the package registry.
#' If not, it establishes a new connection to a DuckDB database located in the configured
#' database folder and stores this connection in the package registry.
#'
#' @export
rb3_duckdb_connection <- function() {
  reg <- rb3_registry$get_instance()
  if ("duck_db_connection" %in% names(reg) && duckdb::dbIsValid(reg$duck_db_connection)) {
    reg$duck_db_connection
  } else {
    con <- duckdb::dbConnect(duckdb::duckdb(), file.path(reg$db_folder, "duckdb.db"))
    reg$duck_db_connection <- con
    con
  }
}
