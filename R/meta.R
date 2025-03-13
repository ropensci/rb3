meta_load <- function(template, ...) {
  reg <- rb3_registry$get_instance()
  sc <- arrow::schema(
    template = arrow::string(),
    download_checksum = arrow::string(),
    download_args = arrow::string(),
    downloaded = arrow::list_of(arrow::string()),
    processed_files = arrow::list_of(arrow::string()),
    created = arrow::timestamp()
  )
  ds <- arrow::open_dataset(reg[["meta_folder"]], schema = sc, format = "json")
  code <- template_create_meta_code(template, ...)
  ds |>
    filter(download_checksum == code) |>
    collect() |>
    as.list()
}

meta_dest_file <- function(meta, checksum, ext = "gz") {
  reg <- rb3_registry$get_instance()
  file.path(reg[["raw_folder"]], str_glue("{checksum}.{ext}"))
}

meta_file <- function(meta) {
  reg <- rb3_registry$get_instance()
  file.path(reg[["meta_folder"]], str_glue("{meta$download_checksum}.json"))
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
  if (length(meta$processed_files) > 0) {
    for (file in meta$processed_files) {
      cli_alert_info("Removing DB file {.file {file}}")
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

`meta_add_processed_file<-` <- function(meta, value) {
  if (value %in% meta$processed_files) {
    return(meta)
  }
  meta$processed_files <- append(meta$processed_files, value)
  meta
}
