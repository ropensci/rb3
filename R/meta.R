meta_new <- function(template, ..., extra_arg = NULL) {
  args <- list(...) |> lapply(format)
  structure(list(
    template = template,
    download_checksum = meta_checksum(template, ..., extra_arg = extra_arg),
    download_args = toJSON(args, auto_unbox = TRUE),
    downloaded = list(),
    created = as.POSIXct(Sys.time(), tz = "UTC"),
    extra_arg = extra_arg
  ), class = "meta")
}

meta_load <- function(template, ..., extra_arg = NULL) {
  checksum <- meta_checksum(template, ..., extra_arg = extra_arg)
  filename <- .meta_file(checksum)
  if (file.exists(filename)) {
    meta <- structure(fromJSON(filename), class = "meta")
    meta$created <- as.POSIXct(meta$created, tz = "UTC")
    meta
  } else {
    l <- list(...)
    args <- paste(names(l), lapply(l, format), sep = " = ", collapse = ", ")
    stop(str_glue("Can't find meta for given arguments: template = {template}, {args}"))
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
  digest(x)
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
  writeLines(toJSON(meta |> unclass(), auto_unbox = TRUE), meta_file(meta))
}

meta_clean <- function(meta) {
  cli_alert_info("Cleaning meta {.strong {meta$download_checksum}}")
  if (length(meta$downloaded) > 0) {
    for (file in meta$downloaded) {
      cli_alert_info("Removing raw file {.file {file}}")
      unlink(file)
    }
  }
  meta_file <- meta_file(meta)
  unlink(meta_file)
}

`meta_add_download<-` <- function(meta, value) {
  if (value %in% meta$downloaded) {
    return(meta)
  }
  meta$downloaded <- append(meta$downloaded, value)
  meta
}
