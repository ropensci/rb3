# Initialize SQLite connection and create meta table
.init_meta_db <- function() {
  con <- meta_db_connection()
  if (!DBI::dbExistsTable(con, "meta")) {
    DBI::dbExecute(con, "
      CREATE TABLE meta (
        download_checksum VARCHAR PRIMARY KEY,
        template VARCHAR,
        download_args VARCHAR,
        download_args_json VARCHAR,
        downloaded VARCHAR,
        created VARCHAR,
        extra_arg VARCHAR,
        is_valid INTEGER CHECK (is_valid IN (0, 1)),
        is_processed INTEGER CHECK (is_processed IN (0, 1)),
        is_downloaded INTEGER CHECK (is_downloaded IN (0, 1))
      )
    ")
  }
  DBI::dbDisconnect(con)
}

# Close SQLite connection on package unload
.onUnload <- function(libpath) {
  tryCatch(
    {
      reg <- rb3_registry$get_instance()
      if ("sqlite_db_connection" %in% names(reg) && DBI::dbIsValid(reg$sqlite_db_connection)) {
        cli::cli_inform(c("v" = "Closing SQLite connection"))
        DBI::dbDisconnect(reg$sqlite_db_connection)
      }
    },
    error = function(e) {
      cli::cli_inform(c("x" = "Error closing SQLite connection: {e$message}"))
    }
  )
}

meta_new <- function(template, ..., extra_arg = NULL) {
  args <- list(...)
  checksum <- meta_checksum(template, ..., extra_arg = extra_arg)
  
  # Check if meta already exists in DB
  con <- meta_db_connection()
  exists_query <- DBI::dbGetQuery(
    con,
    "SELECT COUNT(*) as count FROM meta WHERE download_checksum = ?",
    params = list(checksum)
  )

  if (exists_query$count > 0) {
    cli::cli_abort("Meta {.strong {checksum}} already exists.", class = "error_meta_exists")
  }
  
  # Convert download args to JSON
  args_json <- jsonlite::toJSON(args, auto_unbox = TRUE)
  
  meta <- structure(list(
    template = template,
    download_checksum = checksum,
    download_args = args,
    download_args_json = args_json,
    downloaded = list(),
    created = as.POSIXct(Sys.time(), tz = "UTC"),
    extra_arg = extra_arg,
    is_valid = FALSE,
    is_processed = FALSE,
    is_downloaded = FALSE
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
  con <- meta_db_connection()
  query <- DBI::dbGetQuery(
    con,
    "SELECT * FROM meta WHERE download_checksum = ?",
    params = list(checksum)
  )

  if (nrow(query) == 0) {
    cli::cli_abort("Can't load meta for checksum {.strong {checksum}}", class = "error_meta_not_found")
  }
  
  meta <- structure(list(
    template = query$template,
    download_checksum = query$download_checksum,
    download_args = .meta_deserialize_obj(query$download_args),
    download_args_json = query$download_args_json,
    downloaded = .meta_deserialize_obj(query$downloaded),
    created = .meta_deserialize_obj(query$created),
    extra_arg = .meta_deserialize_obj(query$extra_arg),
    is_valid = as.logical(query$is_valid),
    is_processed = as.logical(query$is_processed),
    is_downloaded = as.logical(query$is_downloaded)
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
  x <- paste(utils::capture.output(dput(obj)), collapse = "\n")
  stopifnot(length(x) > 0)
  x
}

.meta_deserialize_obj <- function(x) {
  if (is.null(x) || length(x) == 0 || is.na(x)) {
    return(NULL)
  }
  dget(textConnection(x))
}

meta_save <- function(meta) {
  con <- meta_db_connection()
  
  serialized_args <- .meta_serialize_obj(meta$download_args)
  serialized_downloaded <- .meta_serialize_obj(meta$downloaded)
  serialized_created <- .meta_serialize_obj(meta$created)
  serialized_extra_arg <- .meta_serialize_obj(meta$extra_arg)
  
  # Ensure download_args_json is updated
  if (is.null(meta$download_args_json)) {
    meta$download_args_json <- jsonlite::toJSON(meta$download_args, auto_unbox = TRUE)
  }

  # Check if record exists
  exists_query <- DBI::dbGetQuery(
    con,
    "SELECT COUNT(*) as count FROM meta WHERE download_checksum = ?",
    params = list(meta$download_checksum)
  )
  
  if (length(exists_query$count) == 1 && exists_query$count > 0) {
    # Update existing record
    DBI::dbExecute(
      con,
      "UPDATE meta SET 
       template = ?, 
       download_args = ?, 
       download_args_json = ?,
       downloaded = ?, 
       created = ?, 
       extra_arg = ?,
       is_valid = ?,
       is_processed = ?,
       is_downloaded = ?
       WHERE download_checksum = ?",
      params = list(
        meta$template,
        serialized_args,
        meta$download_args_json,
        serialized_downloaded,
        serialized_created,
        serialized_extra_arg,
        meta$is_valid,
        meta$is_processed,
        meta$is_downloaded,
        meta$download_checksum
      )
    )
  } else {
    # Insert new record
    DBI::dbExecute(
      con,
      "INSERT INTO meta (download_checksum, template, download_args, download_args_json, downloaded, created, extra_arg, is_valid, is_processed, is_downloaded)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)",
      params = list(
        meta$download_checksum,
        meta$template,
        serialized_args,
        meta$download_args_json,
        serialized_downloaded,
        serialized_created,
        serialized_extra_arg,
        meta$is_valid,
        meta$is_processed,
        meta$is_downloaded
      )
    )
  }

  meta
}

meta_clean <- function(meta) {
  # Check if meta exists in DB
  con <- meta_db_connection()
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
  DBI::dbExecute(
    con,
    "DELETE FROM meta WHERE download_checksum = ?",
    params = list(meta$download_checksum)
  )
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

`meta_set_valid<-` <- function(meta, value) {
  meta$is_valid <- value
  meta_save(meta)
  meta
}

`meta_set_processed<-` <- function(meta, value) {
  meta$is_processed <- value
  meta_save(meta)
  meta
}

`meta_set_downloaded<-` <- function(meta, value) {
  meta$is_downloaded <- value
  meta_save(meta)
  meta
}

meta_query_status <- function(valid = NULL, processed = NULL) {
  con <- meta_db_connection()
  
  # Build the query conditions
  conditions <- c()
  params <- list()
  
  if (!is.null(valid)) {
    conditions <- c(conditions, "is_valid = ?")
    params <- c(params, list(valid))
  }
  
  if (!is.null(processed)) {
    conditions <- c(conditions, "is_processed = ?")
    params <- c(params, list(processed))
  }
  
  # Construct the query
  query <- "SELECT download_checksum, template, download_args_json, created, is_valid, is_processed FROM meta"
  if (length(conditions) > 0) {
    query <- paste(query, "WHERE", paste(conditions, collapse = " AND "))
  }
  
  # Execute the query
  result <- do.call(DBI::dbGetQuery, list(conn = con, statement = query, params = params))
  
  # Parse JSON in the result
  if (nrow(result) > 0 && "download_args_json" %in% names(result)) {
    result$download_args <- lapply(result$download_args_json, function(json) {
      if (!is.na(json)) jsonlite::fromJSON(json) else list()
    })
  }
  
  result
}

#' @exportS3Method base::print
print.meta <- function(x, ...) {
  cli::cli_inform("<meta {x$download_checksum}>\n")
  x
}