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

.registry <- registry_new()

get_template_registry <- function() {
  .registry
}

template_register <- function(obj) {
  # if the class is super (i.e has "name") then add to index
  .reg <- get_template_registry()
  if (!exists(obj$id, envir = .reg)) {
    registry_put(.reg, obj$id, obj)
  }
}

template_retrieve <- function(key) {
  .reg <- get_template_registry()
  registry_get(.reg, key)
}

template_parser <- function(obj) {
  parser_generic <- transmuter(
    match_regex("^(-|\\+)?\\d{1,8}$", to_int(), priority = 1, apply_to = "all"),
    match_regex("^(-|\\+)?\\d{1,8}$", to_int()),
    match_regex("^\\+|-$", function(text, match) {
      idx <- text == "-"
      x <- rep(1, length(text))
      x[idx] <- -1
      x
    }, apply_to = "all"),
    match_regex("^(S|N)$", function(text, match) {
      text == "S"
    }, apply_to = "all")
  )

  parsers <- list(
    generic = parser_generic,
    en = transmuter(
      match_regex("^(-|\\+)?(\\d+,)*\\d+(\\.\\d+)?$",
        to_dbl(dec = ".", thousands = ","),
        apply_to = "all", priority = 2
      ),
      match_regex(
        "^(-|\\+)?(\\d+,)*\\d+(\\.\\d+)?$",
        to_dbl(dec = ".", thousands = ",")
      ), parser_generic
    ),
    pt = transmuter(
      match_regex("^(-|\\+)?(\\d+\\.)*\\d+(,\\d+)?$",
        to_dbl(dec = ",", thousands = "."),
        apply_to = "all", priority = 2
      ),
      match_regex(
        "^(-|\\+)?(\\d+\\.)*\\d+(,\\d+)?$",
        to_dbl(dec = ",", thousands = ".")
      ), parser_generic
    )
  )

  locale <- try(base::get("locale", obj), TRUE)
  if (is(locale, "try-error") || !is(locale, "character")) {
    parsers[["generic"]]
  } else {
    parsers[[locale]]
  }
}

template_separator <- function(obj, .part = NULL) {
  if (is.null(.part)) {
    obj$separator
  } else {
    sep <- try(base::get("separator", .part), TRUE)
    if (is(sep, "try-error") || is.null(sep)) {
      obj$separator
    } else {
      sep
    }
  }
}

template_detect_lines <- function(obj, .part, lines) {
  if (!is.null(.part$pattern)) {
    str_detect(lines, .part$pattern)
  } else if (!is.null(.part$index)) {
    .part$index
  } else {
    stop("MultiPart file with no index defined")
  }
}

list_templates <- function() {
  .reg <- get_template_registry()
  map_dfr(registry_keys(.reg), function(cls) {
    tpl_ <- registry_get(.reg, cls)
    tibble(
      "Description" = tpl_$description,
      "Template" = tpl_$id,
      "Reader" = ifelse(tpl_$has_reader, "\U2705", "\U274C"),
      "Downloader" = ifelse(tpl_$has_downloader, "\U2705", "\U274C")
    )
  })
}

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
  } else if (x$handler$type == "strtime") {
    handler_ <- to_strtime_handler(x$handler$format)
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

# MarketData <- proto(expr = {
#   description <- ""

#   ..registry.id <- registry$proto()
#   ..registry.filename <- registry$proto()

#   register <- function(., .class) {
#     .class$init()

#     # if the class is super (i.e has "name") then add to index
#     if (any(.class$ls() == "id")) {
#       .$..registry.id$put(.class$id, .class)
#     }

#     filename <- try(.class$filename)
#     if (!is(filename, "try-error")) {
#       .$..registry.filename$put(filename, .class)
#     }
#   }

#   retrieve_template <- function(., key) {
#     .$..registry.id$get(key)
#   }

#   show_templates <- function(.) {
#     map_dfr(.$..registry.id$keys(), function(cls) {
#       tpl_ <- .$..registry.id$get(cls)
#       tibble(
#         "Description" = tpl_$description,
#         "Template" = tpl_$id,
#         "Reader" = ifelse(tpl_$has_reader, "\U2705", "\U274C"),
#         "Downloader" = ifelse(tpl_$has_downloader, "\U2705", "\U274C")
#       )
#     })
#   }

#   transform <- function(., df) identity(df)

#   print <- function(.) {
#     cat("Template ID:", .$id, "\n")
#     cat("Expected filename:", .$filename, "\n")
#     cat("File type:", .$filetype, "\n")
#     if (is(.$fields, "fields")) {
#       cat("\n")
#       print.fields(.$fields)
#     } else {
#       parts_names <- names(.$parts)
#       ix <- 0
#       for (nx in parts_names) {
#         ix <- ix + 1
#         cat("\n")
#         cat(sprintf("Part %d: %s\n", ix, nx))
#         cat("\n")
#         print.fields(.$parts[[nx]]$fields)
#       }
#     }
#     invisible(NULL)
#   }

#   .parser <- function(.) {
#     locale <- try(.$locale, TRUE)
#     if (is(locale, "try-error") || !is(locale, "character")) {
#       parsers[["generic"]]
#     } else {
#       parsers[[locale]]
#     }
#   }

#   .separator <- function(., .part = NULL) {
#     if (is.null(.part)) {
#       .$separator
#     } else {
#       sep <- try(.part$separator, TRUE)
#       if (is(sep, "try-error") || is.null(sep)) {
#         .$separator
#       } else {
#         sep
#       }
#     }
#   }

#   .detect_lines <- function(., .part, lines) {
#     if (!is.null(.part$pattern)) {
#       str_detect(lines, .part$pattern)
#     } else if (!is.null(.part$index)) {
#       .part$index
#     } else {
#       stop("MultiPart file with no index defined")
#     }
#   }

#   init <- function(.) {
#     .$colnames <- fields_names(.$fields)
#     .$widths <- fields_widths(.$fields)
#     .$handlers <- fields_handlers(.$fields)
#   }
# })
