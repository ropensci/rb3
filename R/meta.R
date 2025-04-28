# Initialize DuckDB connection and create meta table
.init_meta_db <- function() {
  con <- rb3_duckdb_connection()
  if (!duckdb::dbExistsTable(con, "meta")) {
    DBI::dbExecute(con, "
      CREATE TABLE meta (
        download_checksum VARCHAR PRIMARY KEY,
        template VARCHAR,
        download_args VARCHAR,
        downloaded VARCHAR,
        created VARCHAR,
        extra_arg VARCHAR
      )
    ")
  }
  duckdb::dbDisconnect(con, shutdown = TRUE)
}

# Close DuckDB connection on package unload
.onUnload <- function(libpath) {
  tryCatch({
    reg <- rb3_registry$get_instance()
    if ("duck_db_connection" %in% names(reg) && duckdb::dbIsValid(reg$duck_db_connection)) {
      duckdb::dbDisconnect(reg$duck_db_connection, shutdown = TRUE)
    }
  }, error = function(e) {
    message("Error closing DuckDB connection: ", e$message)
  })
}

meta_new <- function(template, ..., extra_arg = NULL) {
  args <- list(...)
  checksum <- meta_checksum(template, ..., extra_arg = extra_arg)
  
  # Check if meta already exists in DB
  con <- rb3_duckdb_connection()
  exists_query <- DBI::dbGetQuery(
    con,
    "SELECT COUNT(*) as count FROM meta WHERE download_checksum = ?",
    params = list(checksum)
  )
  duckdb::dbDisconnect(con, shutdown = TRUE)

  if (exists_query$count > 0) {
    cli::cli_abort("Meta {.strong {checksum}} already exists.", class = "error_meta_exists")
  }
  
  meta <- structure(list(
    template = template,
    download_checksum = checksum,
    download_args = args,
    downloaded = list(),
    created = as.POSIXct(Sys.time(), tz = "UTC"),
    extra_arg = extra_arg
  ), class = "meta")
  
  meta_save(meta)
  meta
}

meta_load <- function(template, ..., extra_arg = NULL) {
  checksum <- meta_checksum(template, ..., extra_arg = extra_arg)
  tryCatch(meta_get(checksum), error = function(e) {
    l <- list(...)
    args <- paste(names(l), lapply(l, format), sep = " = ", collapse = ", ")
    cli::cli_abort("Can't find meta for given arguments: template = {template}, {args}",
      class = "error_meta_not_found", parent = e
    )
  })
}

meta_get <- function(checksum) {
  con <- rb3_duckdb_connection()
  query <- DBI::dbGetQuery(
    con,
    "SELECT * FROM meta WHERE download_checksum = ?",
    params = list(checksum)
  )
  duckdb::dbDisconnect(con, shutdown = TRUE)
  if (nrow(query) == 0) {
    cli::cli_abort("Can't load meta for checksum {.strong {checksum}}", class = "error_meta_not_found")
  }
  
  meta <- structure(list(
    template = query$template,
    download_checksum = query$download_checksum,
    download_args = .meta_deserialize_obj(query$download_args),
    downloaded = .meta_deserialize_obj(query$downloaded),
    created = .meta_deserialize_obj(query$created),
    extra_arg = .meta_deserialize_obj(query$extra_arg)
  ), class = "meta")
  
  meta
}

meta_checksum <- function(template, ..., extra_arg = NULL) {
  l_ <- if (!is.null(extra_arg)) {
    list(template = template, download_args = list(...), extra_arg = extra_arg)
  } else {
    list(template = template, download_args = list(...))
  }
  x <- lapply(l_, format)
  names(x) <- names(l_)
  digest::digest(x)
}

meta_dest_file <- function(meta, checksum, ext = "gz") {
  reg <- rb3_registry$get_instance()
  file.path(reg[["raw_folder"]], str_glue("{checksum}.{ext}"))
}

.meta_serialize_obj <- function(obj) {
  utils::capture.output(dput(obj))
}

.meta_deserialize_obj <- function(x) {
  if (is.null(x) || length(x) == 0 || is.na(x)) {
    return(NULL)
  }
  dget(textConnection(x))
}

meta_save <- function(meta) {
  con <- rb3_duckdb_connection()
  
  serialized_args <- .meta_serialize_obj(meta$download_args)
  serialized_downloaded <- .meta_serialize_obj(meta$downloaded)
  serialized_created <- .meta_serialize_obj(meta$created)
  serialized_extra_arg <- .meta_serialize_obj(meta$extra_arg)
  
  # Check if record exists
  exists_query <- DBI::dbGetQuery(
    con,
    "SELECT COUNT(*) as count FROM meta WHERE download_checksum = ?",
    params = list(meta$download_checksum)
  )
  
  if (exists_query$count > 0) {
    # Update existing record
    DBI::dbExecute(
      con,
      "UPDATE meta SET 
       template = ?, 
       download_args = ?, 
       downloaded = ?, 
       created = ?, 
       extra_arg = ? 
       WHERE download_checksum = ?",
      params = list(
        meta$template,
        serialized_args,
        serialized_downloaded,
        serialized_created,
        serialized_extra_arg,
        meta$download_checksum
      )
    )
  } else {
    # Insert new record
    DBI::dbExecute(
      con,
      "INSERT INTO meta (download_checksum, template, download_args, downloaded, created, extra_arg)
       VALUES (?, ?, ?, ?, ?, ?)",
      params = list(
        meta$download_checksum,
        meta$template,
        serialized_args,
        serialized_downloaded,
        serialized_created,
        serialized_extra_arg
      )
    )
  }
  duckdb::dbDisconnect(con, shutdown = TRUE)
  meta
}

meta_clean <- function(meta) {
  # Check if meta exists in DB
  con <- rb3_duckdb_connection()
  exists_query <- DBI::dbGetQuery(
    con,
    "SELECT COUNT(*) as count FROM meta WHERE download_checksum = ?",
    params = list(meta$download_checksum)
  )
  
  if (exists_query$count == 0) {
    cli::cli_abort("Meta record for checksum {.strong {meta$download_checksum}} does not exist",
      class = "error_meta_not_found"
    )
  }
  
  cli::cli_alert_info("Cleaning meta {.strong {meta$download_checksum}}")
  
  # Clean downloaded files
  if (length(meta$downloaded) > 0) {
    for (file in meta$downloaded) {
      cli::cli_alert_info("Removing raw file {.file {file}}")
      unlink(file)
    }
  }
  
  # Delete meta record
  con <- rb3_duckdb_connection()
  DBI::dbExecute(
    con,
    "DELETE FROM meta WHERE download_checksum = ?",
    params = list(meta$download_checksum)
  )
  duckdb::dbDisconnect(con, shutdown = TRUE)
}

`meta_add_download<-` <- function(meta, value) {
  if (is.null(value)) {
    meta$downloaded <- list()
  } else if (value %in% meta$downloaded) {
    return(meta)
  } else {
    meta$downloaded <- append(meta$downloaded, value)
  }
  meta_save(meta)
  meta
}
