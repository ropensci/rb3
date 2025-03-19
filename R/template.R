new_template <- function() {
  obj <- list(description = "")

  obj[["has_reader"]] <- FALSE
  obj[["has_downloader"]] <- FALSE
  obj[["verifyssl"]] <- TRUE

  structure(obj, class = "template")
}

load_template_from_file <- function(fname) {
  tpl <- yaml.load_file(fname)
  obj <- new_template()
  for (n in names(tpl)) {
    if (n == "fields") {
      obj[["fields"]] <- do.call(fields, lapply(tpl$fields, new_field))
    } else if (n == "parts") {
      obj[["parts"]] <- lapply(tpl$parts, new_part)
    } else if (n == "reader") {
      obj[["has_reader"]] <- TRUE
      obj[["reader"]] <- tpl$reader
      func_name <- tpl$reader[["function"]]
      obj[["read_file"]] <- getFromNamespace(func_name, "rb3")
    } else if (n == "downloader") {
      obj[["has_downloader"]] <- TRUE
      obj[["downloader"]] <- tpl$downloader
      func_name <- tpl$downloader[["function"]]
      obj[["download_marketdata"]] <- getFromNamespace(func_name, "rb3")
    } else {
      obj[[n]] <- tpl[[n]]
    }
  }

  if (is.null(obj$reader)) {
    reader_name <- paste0(str_to_lower(obj$filetype), "_read_file")
    obj[["read_file"]] <- getFromNamespace(reader_name, "rb3")
    obj[["has_reader"]] <- TRUE
  }

  if (obj$filetype %in% c("MCSV", "MFWF", "MCUSTOM")) {
    for (idx in seq_along(obj$parts)) {
      obj$parts[[idx]]$colnames <- fields_names(obj$parts[[idx]]$fields)
      obj$parts[[idx]]$handlers <- fields_handlers(obj$parts[[idx]]$fields)
      obj$parts[[idx]]$widths <- fields_widths(obj$parts[[idx]]$fields)
    }
  } else {
    obj$colnames <- fields_names(obj$fields)
    obj$widths <- fields_widths(obj$fields)
    obj$handlers <- fields_handlers(obj$fields)
  }

  template_register(obj)
  obj
}

load_template_files <- function() {
  dir <- system.file("extdata/templates/",
    package = "rb3",
    mustWork = TRUE
  )
  files <- list.files(dir, full.names = TRUE)
  for (file in files) {
    load_template_from_file(file)
  }
}

#' @exportS3Method base::print
print.template <- function(x, ...) {
  cat("Template ID:", x$id, "\n")
  cat("Expected filename:", x$filename, "\n")
  cat("File type:", x$filetype, "\n")
  if (is(x$fields, "fields")) {
    cat("Fields: ")
    print.fields(x$fields)
  } else {
    parts_names <- names(x$parts)
    ix <- 0
    for (nx in parts_names) {
      ix <- ix + 1
      cat("\n")
      cat(sprintf("Part %d: %s\n", ix, nx))
      cat("Fields: ")
      print.fields(x$parts[[nx]]$fields)
    }
  }
  invisible(NULL)
}

template_registry <- create_registry()

template_register <- function(obj) {
  # if the class is super (i.e has "name") then add to index
  .reg <- template_registry$get_instance()
  .reg[[obj$id]] <- obj
}

template_retrieve <- function(key) {
  .reg <- template_registry$get_instance()
  .reg[[key]]
}

list_templates <- function() {
  .reg <- template_registry$get_instance()
  map_dfr(registry_keys(.reg), function(cls) {
    tpl_ <- .reg[[cls]]
    tibble(
      "Description" = tpl_$description,
      "Template" = tpl_$id,
      "Reader" = ifelse(tpl_$has_reader, "\U2705", "\U274C"),
      "Downloader" = ifelse(tpl_$has_downloader, "\U2705", "\U274C")
    )
  })
}

template_schema <- function(template) {
  arrow_types <- fields_arrow_types(template$fields)
  do.call(arrow::schema, arrow_types)
}

template_db_folder <- function(template) {
  reg <- rb3_registry$get_instance()
  db_folder <- file.path(reg[["db_folder"]], template$id)
  if (!dir.exists(db_folder)) {
    dir.create(db_folder, recursive = TRUE)
  }
  db_folder
}

template_dataset <- function(template) {
  schema <- template_schema(template)
  dir <- template_db_folder(template)
  arrow::open_dataset(dir, schema)
}

new_field <- function(x) {
  tag_ <- if (!is.null(x$tag)) tag(x$tag)
  width_ <- if (!is.null(x$width)) width(x$width)
  if (is.null(x$handler$type)) {
    handler_ <- pass_thru_handler()
    col_ <- readr::col_guess()
    arrow_type_ <- arrow::string()
  } else if (x$handler$type == "number") {
    handler_ <- to_numeric_handler(x$handler$dec, x$handler$sign)
    col_ <- readr::col_number()
    arrow_type_ <- arrow::float64()
  } else if (x$handler$type == "numeric") {
    handler_ <- to_numeric_handler(x$handler$dec, x$handler$sign)
    col_ <- readr::col_double()
    arrow_type_ <- arrow::float64()
  } else if (x$handler$type == "integer") {
    handler_ <- to_numeric_handler(0, "")
    col_ <- readr::col_integer()
    arrow_type_ <- arrow::int64()
  } else if (x$handler$type == "factor") {
    handler_ <- to_factor_handler(x$handler$levels, x$handler$labels)
    col_ <- readr::col_factor(x$handler$levels, x$handler$labels)
    arrow_type_ <- arrow::string()
  } else if (x$handler$type == "Date") {
    handler_ <- to_date_handler(x$handler$format)
    col_ <- readr::col_date(format = x$handler$format)
    arrow_type_ <- arrow::date32()
  } else if (x$handler$type == "POSIXct") {
    handler_ <- to_time_handler(x$handler$format)
    col_ <- readr::col_datetime(format = x$handler$format)
    arrow_type_ <- arrow::timestamp()
  } else if (x$handler$type == "strtime") {
    handler_ <- to_strtime_handler(x$handler$format)
    col_ <- readr::col_time(format = x$handler$format)
    arrow_type_ <- arrow::time64()
  } else if (x$handler$type == "character") {
    handler_ <- pass_thru_handler()
    col_ <- readr::col_character()
    arrow_type_ <- arrow::string()
  } else {
    handler_ <- pass_thru_handler()
    col_ <- readr::col_guess()
    arrow_type_ <- arrow::string()
  }
  field(x$name, x$description, width_, tag_, handler_, col_, arrow_type_)
}

new_part <- function(x) {
  part <- list()
  for (np in names(x)) {
    if (np == "fields") {
      part[["fields"]] <- do.call(fields, lapply(x[["fields"]], new_field))
    } else {
      part[[np]] <- x[[np]]
    }
  }
  part
}

template_meta_create <- function(template, ...) {
  meta <- try(meta_load(template$id, ...), silent = TRUE)
  if (!is(meta, "try-error")) {
    meta
  } else {
    meta_new(template$id, ...)
  }
}
