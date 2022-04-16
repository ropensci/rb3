
new_field <- function(x) {
  width_ <- if (!is.null(x$width)) width(x$width)
  if (x$handler$type == "numeric") {
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

new_template <- function(tpl) {
  nx <- names(tpl)
  ix <- match(nx, c("filetype", "fields", "parts")) |> is.na()
  nx <- nx[ix]

  if (tpl$filetype == "FWF") {
    obj <- MarketDataFWF$proto()
    for (n in nx) {
      obj[[n]] <- tpl[[n]]
    }
    obj[["fields"]] <- do.call(fields, lapply(tpl$fields, new_field))
  } else if (tpl$filetype == "MFWF") {
    obj <- MarketDataMultiPartFWF$proto()
    for (n in nx) {
      obj[[n]] <- tpl[[n]]
    }
    parts_names <- names(tpl$parts)
    parts <- list()
    for (part_name in parts_names) {
      parts[[part_name]] <- list(pattern = tpl$parts[[part_name]][["pattern"]])
      parts[[part_name]][["fields"]] <- do.call(
        fields,
        lapply(tpl$parts[[part_name]][["fields"]], new_field)
      )
    }
    obj[["parts"]] <- parts
  } else if (tpl$filetype == "CSV") {
    obj <- MarketDataCSV$proto()
    for (n in nx) {
      obj[[n]] <- tpl[[n]]
    }
    obj[["fields"]] <- do.call(fields, lapply(tpl$fields, new_field))
  } else if (tpl$filetype == "JSON") {
    obj <- MarketDataJSON$proto()
    for (n in nx) {
      obj[[n]] <- tpl[[n]]
    }
    obj[["fields"]] <- do.call(fields, lapply(tpl$fields, new_field))
  } else if (tpl$filetype == "MCSV") {
    obj <- MarketDataMultiPartCSV$proto()
    for (n in nx) {
      obj[[n]] <- tpl[[n]]
    }
    parts_names <- names(tpl$parts)
    parts <- list()
    for (part_name in parts_names) {
      parts[[part_name]] <- list(lines = tpl$parts[[part_name]][["lines"]])
      parts[[part_name]][["fields"]] <- do.call(
        fields,
        lapply(tpl$parts[[part_name]][["fields"]], new_field)
      )
    }
    obj[["parts"]] <- parts
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
}
