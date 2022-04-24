read_fwf <- function(fname, widths, colnames = NULL, skip = 0, text) {
  colpositions <- list()
  x <- 1
  i <- 1
  for (y in widths) {
    colpositions[[i]] <- c(x, x + y - 1)
    x <- x + y
    i <- i + 1
  }

  if (is.null(colnames)) {
    colnames <- paste0("V", seq_along(widths))
  }

  lines <- if (missing(text)) readLines(fname) else text

  if (skip) {
    lines <- lines[-seq(skip), ]
  }

  t <- list()
  for (i in seq_along(colnames)) {
    dx <- colpositions[[i]]
    t[[colnames[i]]] <- stringr::str_sub(lines, dx[1], dx[2])
  }

  as.data.frame(t,
    stringsAsFactors = FALSE, optional = TRUE,
    check.names = FALSE
  )
}

trim_fields <- function(x) {
  fields <- lapply(x, function(z) {
    if (is(z, "character")) {
      stringr::str_trim(z)
    } else {
      z
    }
  })
  do.call("data.frame", c(fields,
    stringsAsFactors = FALSE,
    check.names = FALSE
  ))
}

parse_columns <- function(df, colnames, handlers, parser) {
  df <- trim_fields(df)
  e <- evalq(environment(), df, NULL)
  df <- lapply(colnames, function(x) {
    fun <- handlers[[x]]
    x <- df[[x]]
    do.call(fun, list(x), envir = e)
  })
  names(df) <- colnames
  df <- do.call(
    "data.frame",
    c(df, stringsAsFactors = FALSE, check.names = FALSE)
  )
  parse_text(parser, df)
}

fwf_read_file <- function(., filename, parse_fields = TRUE) {
  df <- read_fwf(filename, .$widths, colnames = .$colnames)
  if (parse_fields) {
    parse_columns(df, .$colnames, .$handlers, .$.parser())
  } else {
    df
  }
}

#' @importFrom utils read.table
csv_read_file <- function(., filename, parse_fields = TRUE) {
  df <- read.table(filename,
    col.names = .$colnames, sep = .$separator,
    as.is = TRUE, stringsAsFactors = FALSE
  )
  if (parse_fields) {
    parse_columns(df, .$colnames, .$handlers, .$.parser())
  } else {
    df
  }
}

json_read_file <- function(., filename, parse_fields = TRUE) {
  jason <- jsonlite::fromJSON(filename)
  df <- as.data.frame(jason)
  if (parse_fields) {
    parse_columns(df, .$colnames, .$handlers, .$.parser())
  } else {
    df
  }
}

mcsv_read_file <- function(., filename, parse_fields = TRUE) {
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
    l[[part_name]] <- if (parse_fields) {
      parse_columns(df, part$colnames, part$handlers, .$.parser())
    } else {
      df
    }
  }
  class(l) <- "parts"
  l
}

mfwf_read_file <- function(., filename, parse_fields = TRUE) {
  lines <- readLines(filename)
  l <- list()
  for (part_name in names(.$parts)) {
    part <- .$parts[[part_name]]
    idx <- .$.detect_lines(part, lines)
    df <- read_fwf(
      text = lines[idx], widths = part$widths,
      colnames = part$colnames
    )
    l[[part_name]] <- if (parse_fields) {
      parse_columns(df, part$colnames, part$handlers, .$.parser())
    } else {
      df
    }
  }
  class(l) <- "parts"
  l
}

#' @importFrom rvest html_table html_element read_html
settlement_prices_read <- function(., filename, parse_fields = TRUE) {
  doc <- rvest::read_html(filename)
  xpath <- "//table[contains(@id, 'tblDadosAjustes')]"
  table <- rvest::html_element(doc, xpath = xpath)
  if (is(table, "xml_node")) {
    df <- rvest::html_table(table)
  } else {
    return(NULL)
  }
  colnames(df) <- .$colnames
  if (parse_fields) {
    parse_columns(df, .$colnames, .$handlers, .$.parser())
  } else {
    df
  }
}