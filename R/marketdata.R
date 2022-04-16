
#' Read and parses files delivered by B3
#'
#' B3, and previously BMF&Bovespa, used to deliver many files with a diverse
#' set of valuable data and informations that can be used to study of can
#' be called of marketdata.
#' There are files with informations about futures, option, interest
#' rates, currency rates, bonds and many other subjects.
#'
#' @param filename a string containing a path for the file.
#' @param template a string with the template name.
#' @param parse_fields a logical indicating if the fields must be parsed.
#'
#' Each `template` has a default value for the `filename`, if the given
#' file name equals one template filename attribute, the matched template
#' is used to parse the file.
#' Otherwise the template must be provided.
#'
#' The function `show_templates` can be used to view the available templates
#' and their default filenames.
#'
#' @return `data.frame` of a list of `data.frame` containing data parsed from
#' files.
#'
#' @seealso show_templates display_template
#'
#' @examples
#' \dontrun{
#' # Eletro.txt matches the filename of Eletro template
#' path <- "Eletro.txt"
#' df <- read_marketdata(path)
#' path <- "Indic.txt"
#' df <- read_marketdata(path, template = "Indic")
#' path <- "PUWEB.TXT"
#' df <- read_marketdata(path, template = "PUWEB")
#' }
#' @export
read_marketdata <- function(filename, template = NULL, parse_fields = TRUE) {
  template <- .retrieve_template(filename, template)
  template$read_file(filename, parse_fields)
}

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

MarketData <- proto::proto(expr = {
  description <- ""

  ..registry.id <- registry$proto()
  ..registry.filename <- registry$proto()

  register <- function(., .class) {
    .class$init()

    # if the class is super (i.e has "name") then add to index
    if (any(.class$ls() == "id")) {
      .$..registry.id$put(.class$id, .class)
    }

    filename <- try(.class$filename)
    if (!is(filename, "try-error")) {
      .$..registry.filename$put(filename, .class)
    }
  }

  parser <- transmuter(
    match_regex("^\\+\\d+$", as.numeric, priority = 1),
    match_regex("^\\d+$", as.integer),
    match_regex("^\\d+\\.\\d+$", as.numeric),
    match_regex("^\\+|-$", function(text, match) {
      idx <- text == "-"
      x <- rep(1, length(text))
      x[idx] <- -1
      x
    }),
    match_regex("^(S|N)$", function(text, match) {
      text == "S"
    })
  )

  retrieve_template <- function(., key) {
    .$..registry.id$get(key)
  }

  show_templates <- function(.) {
    dx <- lapply(.$..registry.id$keys(), function(cls) {
      tpl_ <- .$..registry.id$get(cls)
      data.frame(
        "Template ID" = tpl_$id,
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
        cat("\n")
        print.fields(.$parts[[nx]]$fields)
      }
    }
    invisible(NULL)
  }
})

MarketDataFWF <- MarketData$proto(expr = {
  file_type <- "FWF"
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
      df <- parse_text(.$parser, df)
    }
    df
  }

  init <- function(.) {
    .$colnames <- fields_names(.$fields)
    .$widths <- fields_widths(.$fields)
    .$handlers <- fields_handlers(.$fields)
  }
})

MarketDataCSV <- MarketData$proto(expr = {
  file_type <- "CSV"
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
      df <- parse_text(.$parser, df)
    }
    df
  }
})

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

MarketDataMultiPartCSV <- MarketDataMultiPart$proto(expr = {
  file_type <- "MCSV"
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
      idx <- .$.detect_lines(part, lines)
      df <- read.table(
        text = lines[idx], col.names = part$colnames, sep = .$.separator(part),
        as.is = TRUE, stringsAsFactors = FALSE, check.names = FALSE,
        colClasses = "character"
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
        df <- do.call(
          "data.frame",
          c(df, stringsAsFactors = FALSE, check.names = FALSE)
        )
        df <- parse_text(.$parser, df)
      }
      l[[part_name]] <- df
    }
    class(l) <- "parts"
    l
  }
})

MarketDataMultiPartFWF <- MarketDataMultiPart$proto(expr = {
  file_type <- "MFWF"
  read_file <- function(., filename, parse_fields = TRUE) {
    lines <- readLines(filename)
    l <- list()
    for (part_name in names(.$parts)) {
      part <- .$parts[[part_name]]
      idx <- .$.detect_lines(part, lines)
      # print(part)
      df <- read_fwf(
        text = lines[idx], widths = part$widths,
        colnames = part$colnames
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
        df <- parse_text(.$parser, df)
      }
      l[[part_name]] <- df
    }
    class(l) <- "parts"
    l
  }
})