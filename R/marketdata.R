
.retrieve_template <- function(filename, template) {
  template <- if (is.null(template)) {
    MarketData$retrieve_template(basename(filename))
  } else {
    MarketData$retrieve_template(template)
  }
  if (is.null(template)) {
    stop("Unknown template.")
  }
  template
}

registry <- proto::proto(expr = {
  .container <- list()
  put <- function(., key, value) {
    .$.container[[key]] <- value
    invisible(NULL)
  }

  get <- function(., key) {
    val <- try(base::get(key, .$.container), TRUE)
    if (is(val, "try-error")) NULL else val
  }

  keys <- function(.) {
    names(.$.container)
  }
})

NUMERIC.TRANSMUTER <- transmuter(
  match_regex("^\\d+$", as.integer),
  match_regex("^\\d+\\.\\d+$", as.numeric)
)

#' @export
MarketData <- proto::proto(expr = {
  description <- ""

  ..registry.id <- registry$proto()
  ..registry.class <- registry$proto()
  ..registry.filename <- registry$proto()

  register <- function(., .class) {
    .class$init()

    # if the class is super (i.e has "name") then add to index
    if (any(.class$ls() == "id")) {
      .$..registry.id$put(.class$id, .class)
    }

    name <- deparse(substitute(.class))
    .$..registry.class$put(name, .class)

    filename <- try(.class$filename)
    if (!is(filename, "try-error")) {
      .$..registry.filename$put(filename, .class)
    }
  }

  parser <- NUMERIC.TRANSMUTER

  retrieve_template <- function(., key) {
    # key <- tolower(key)
    tpl_ <- .$..registry.id$get(key)
    if (!is.null(tpl_)) {
      return(tpl_)
    } else {
      tpl_ <- .$..registry.class$get(key)
      tpl_ <- if (is.null(tpl_)) .$..registry.filename$get(key) else tpl_
      return(tpl_)
    }
  }

  show_templates <- function(.) {
    dx <- lapply(.$..registry.class$keys(), function(cls) {
      tpl_ <- .$..registry.class$get(cls)
      data.frame(
        "Template ID" = tpl_$id,
        "Class Name" = cls,
        "Filename" = tpl_$filename,
        "File Type" = tpl_$file_type,
        "Description" = tpl_$description,
        stringsAsFactors = FALSE,
        check.names = FALSE
      )
    })
    do.call(rbind, dx)
  }

  transform <- function(., df) identity(df)

  print <- function(.) {
    cat("Template ID:", .$id, "\n")
    cat("Expected filename:", .$filename, "\n")
    cat("File type:", .$file_type, "\n")
    if (is(.$fields, "fields")) {
      cat("\n")
      print.fields(.$fields)
    } else {
      parts_names <- names(.$parts)
      ix <- 0
      for (nx in parts_names) {
        ix <- ix + 1
        cat("\n")
        cat(sprintf("Part %d: %s\n", ix, nx))
        # if (! is.null(.$parts[[nx]]$lines))
        #   cat('Lines:', .$parts[[nx]]$lines, '\n')
        # else
        #   cat('Pattern:', .$parts[[nx]]$pattern, '\n')
        cat("\n")
        print.fields(.$parts[[nx]]$fields)
      }
    }
    invisible(NULL)
  }
})

#' @export
MarketDataFWF <- MarketData$proto(expr = {
  file_type <- "Fixed Width"
  read_file <- function(., filename, parse_fields = TRUE) {
    df <- read_fwf(filename, .$widths, colnames = .$colnames)
    if (parse_fields) {
      df <- trim_fields(df)
      e <- evalq(environment(), df, NULL)
      df <- lapply(.$colnames, function(x) {
        fun <- .$handlers[[x]]
        x <- df[[x]]
        do.call(fun, list(x), envir = e)
      })
      names(df) <- .$colnames
      df <- do.call("data.frame", c(df, stringsAsFactors = FALSE, check.names = FALSE))
      df <- transmute(.$parser, df)
    }
    df
  }

  init <- function(.) {
    .$colnames <- fields_names(.$fields)
    .$widths <- fields_widths(.$fields)
    .$handlers <- fields_handlers(.$fields)
  }
})

#' @export
MarketDataCSV <- MarketData$proto(expr = {
  file_type <- "Comma-separated Values"
  read_file <- function(., filename, parse_fields = TRUE) {
    df <- read.table(filename,
      col.names = .$colnames, sep = .$separator,
      as.is = TRUE, stringsAsFactors = FALSE
    )
    if (parse_fields) {
      df <- trim_fields(df)
      e <- evalq(environment(), df, NULL)
      df <- lapply(.$colnames, function(x) {
        fun <- .$handlers[[x]]
        x <- df[[x]]
        do.call(fun, list(x), envir = e)
      })
      names(df) <- .$colnames
      df <- do.call("data.frame", c(df, stringsAsFactors = FALSE, check.names = FALSE))
      df <- transmute(.$parser, df)
    }
    df
  }
})

#' @export
MarketDataMultiPart <- MarketData$proto(expr = {
  .detect_lines <- function(., .part, lines) {
    if (is.null(.part$pattern)) {
      .part$lines
    } else {
      stringr::str_detect(lines, .part$pattern)
    }
  }

  init <- function(.) {
    for (idx in seq_along(.$parts)) {
      .$parts[[idx]]$colnames <- fields_names(.$parts[[idx]]$fields)
      .$parts[[idx]]$handlers <- fields_handlers(.$parts[[idx]]$fields)
      .$parts[[idx]]$widths <- fields_widths(.$parts[[idx]]$fields)
    }
  }
})

#' @export
MarketDataMultiPartCSV <- MarketDataMultiPart$proto(expr = {
  file_type <- "Comma-separated Values (with Multiple Parts)"
  .separator <- function(., .part = NULL) {
    if (is.null(.part)) {
      .$separator
    } else {
      sep <- try(.part$separator)
      if (is(sep, "try-error") || is.null(sep)) {
        .$separator
      } else {
        sep
      }
    }
  }

  read_file <- function(., filename, parse_fields = TRUE) {
    lines <- readLines(filename)
    l <- list()
    for (part_name in names(.$parts)) {
      part <- .$parts[[part_name]]
      idx <- .$.detect_lines(part, lines) # stringr::str_detect(lines, part$pattern)
      df <- read.table(
        text = lines[idx], col.names = part$colnames, sep = .$.separator(part),
        as.is = TRUE, stringsAsFactors = FALSE, check.names = FALSE, colClasses = "character"
      )
      if (parse_fields) {
        df <- trim_fields(df)
        e <- evalq(environment(), df, NULL)
        df <- lapply(part$colnames, function(x) {
          fun <- part$handlers[[x]]
          x <- df[[x]]
          do.call(fun, list(x), envir = e)
        })
        names(df) <- part$colnames
        df <- do.call("data.frame", c(df, stringsAsFactors = FALSE, check.names = FALSE))
        df <- transmute(.$parser, df)
      }
      l[[part_name]] <- df
    }
    class(l) <- "parts"
    l
  }
})

#' @export
MarketDataMultiPartFWF <- MarketDataMultiPart$proto(expr = {
  file_type <- "Fixed Width (with Multiple Parts)"
  read_file <- function(., filename, parse_fields = TRUE) {
    lines <- readLines(filename)
    l <- list()
    for (part_name in names(.$parts)) {
      part <- .$parts[[part_name]]
      idx <- .$.detect_lines(part, lines)
      # print(part)
      df <- read_fwf(text = lines[idx], widths = part$widths, colnames = part$colnames)
      if (parse_fields) {
        df <- trim_fields(df)
        e <- evalq(environment(), df, NULL)
        df <- lapply(part$colnames, function(x) {
          fun <- part$handlers[[x]]
          x <- df[[x]]
          do.call(fun, list(x), envir = e)
        })
        names(df) <- part$colnames
        df <- do.call("data.frame", c(df, stringsAsFactors = FALSE, check.names = FALSE))
        df <- transmute(.$parser, df)
      }
      l[[part_name]] <- df
    }
    class(l) <- "parts"
    l
  }
})