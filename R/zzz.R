
new_field <- function(x) {
  width_ <- if (!is.null(x$width)) width(x$width)
  if (is.null(x$handler$type)) {
    handler_ <- pass_thru_handler()
  } else if (x$handler$type == "numeric") {
    handler_ <- to_numeric_handler(x$handler$dec, x$handler$sign)
  } else if (x$handler$type == "factor") {
    handler_ <- to_factor_handler(x$handler$levels, x$handler$labels)
  } else if (x$handler$type == "Date") {
    handler_ <- to_date_handler(x$handler$format)
  } else if (x$handler$type == "POSIXct") {
    handler_ <- to_time_handler(x$handler$format)
  } else {
    handler_ <- pass_thru_handler()
  }
  field(x$name, x$description, width_, handler_)
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

.multipart_init <- function(.) {
  for (idx in seq_along(.$parts)) {
    .$parts[[idx]]$colnames <- fields_names(.$parts[[idx]]$fields)
    .$parts[[idx]]$handlers <- fields_handlers(.$parts[[idx]]$fields)
    .$parts[[idx]]$widths <- fields_widths(.$parts[[idx]]$fields)
  }
}

new_template <- function(tpl) {
  obj <- MarketData$proto()
  obj[["has_reader"]] <- FALSE
  obj[["has_downloader"]] <- FALSE
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

  if (is(try(obj$reader, TRUE), "try-error")) {
    reader_name <- paste0(str_to_lower(obj$filetype), "_read_file")
    obj[["read_file"]] <- getFromNamespace(reader_name, "rb3")
    obj[["has_reader"]] <- TRUE
  }

  if (obj$filetype %in% c("MCSV", "MFWF", "MCUSTOM")) {
    obj[["init"]] <- .multipart_init
  }

  MarketData$register(obj)
  obj
}

load_templates <- function() {
  dir <- system.file("extdata/templates/",
    package = "rb3",
    mustWork = TRUE
  )
  files <- list.files(dir, full.names = TRUE)
  for (file in files) {
    tpl <- yaml.load_file(file)
    new_template(tpl)
  }
}

.onAttach <- function(libname, pkgname) {
  load_templates()
  load_builtin_calendars()
}