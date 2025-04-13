meta_new <- function(template, ..., extra_arg = NULL) {
  args <- list(...) |> lapply(format)
  checksum <- meta_checksum(template, ..., extra_arg = extra_arg)
  if (file.exists(.meta_file(checksum))) {
    cli::cli_abort("Meta {.strong {checksum}} already exists.", class = "error_meta_exists")
  }
  meta <- structure(list(
    template = template,
    download_checksum = checksum,
    download_args = jsonlite::toJSON(args, auto_unbox = TRUE),
    downloaded = list(),
    created = as.POSIXct(Sys.time(), tz = "UTC"),
    extra_arg = extra_arg
  ), class = "meta")
  meta_save(meta)
  meta
}

meta_load <- function(template, ..., extra_arg = NULL) {
  checksum <- meta_checksum(template, ..., extra_arg = extra_arg)
  filename <- .meta_file(checksum)
  if (file.exists(filename)) {
    meta <- structure(jsonlite::fromJSON(filename), class = "meta")
    meta$created <- as.POSIXct(meta$created, tz = "UTC")
    meta
  } else {
    l <- list(...)
    args <- paste(names(l), lapply(l, format), sep = " = ", collapse = ", ")
    cli::cli_abort("Can't find meta for given arguments: template = {template}, {args}",
      class = "error_meta_not_found"
    )
  }
}

meta_checksum <- function(template, ..., extra_arg = NULL) {
  l_ <- if (!is.null(extra_arg)) {
    c(id = template, list(...), extra_arg = extra_arg)
  } else {
    c(id = template, list(...))
  }
  x <- lapply(l_, format)
  names(x) <- names(l_)
  digest::digest(x)
}

meta_dest_file <- function(meta, checksum, ext = "gz") {
  reg <- rb3_registry$get_instance()
  file.path(reg[["raw_folder"]], str_glue("{checksum}.{ext}"))
}

.meta_file <- function(checksum) {
  reg <- rb3_registry$get_instance()
  file.path(reg$meta_folder, str_glue("{checksum}.json"))
}

meta_file <- function(meta) {
  .meta_file(meta$download_checksum)
}

meta_save <- function(meta) {
  writeLines(jsonlite::toJSON(meta |> unclass(), auto_unbox = TRUE), meta_file(meta))
}

meta_clean <- function(meta) {
  meta_file <- meta_file(meta)
  if (!file.exists(meta_file)) {
    cli::cli_abort("Meta file {.file {meta_file}} does not exist",
      class = "error_meta_not_found"
    )
  }
  cli::cli_alert_info("Cleaning meta {.strong {meta$download_checksum}}")
  if (length(meta$downloaded) > 0) {
    for (file in meta$downloaded) {
      cli::cli_alert_info("Removing raw file {.file {file}}")
      unlink(file)
    }
  }
  unlink(meta_file)
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
