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
  parse_text(parser, df) |> tibble::as_tibble()
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

options_open_interest_read <- function(., filename, parse_fields = TRUE) {
  jason <- jsonlite::fromJSON(filename)
  if (is.null(jason$Empresa)) {
    return(NULL)
  }
  df <- do.call(rbind, jason$Empresa)
  names(df) <- .$colnames
  if (parse_fields) {
    parse_columns(df, .$colnames, .$handlers, .$.parser())
  } else {
    df
  }
}

cols_number <- c(
  ACC = 2, BRP = 2, DCO = 2, DIC = 2, DIM = 2, DOC = 2, DOL = 2, EUC = 2,
  EUR = 2, INP = 2, JPY = 2, LIB = 2, PTX = 2, SDE = 2, SLP = 2, APR = 3,
  DP = 3, PRE = 3, TFP = 3, TP = 3, TR = 3
)

curve_read <- function(., filename, parse_fields = TRUE) {
  text <- readr::read_file(filename)

  char_vec <- rvest::read_html(text) |>
    rvest::html_nodes("td") |>
    rvest::html_text()

  if (length(char_vec) == 0) {
    return(NULL)
  }

  ctx <- str_match(text, "\"([A-Z]+)\"\\s+selected")
  curve_name <- ctx[1, 2]

  mtx <- str_match(text, "Atualizado em: (\\d{2}/\\d{2}/\\d{4})")
  refdate <- mtx[1, 2] |> as.Date("%d/%m/%Y")

  if (cols_number[curve_name] == 2) {
    idx1 <- seq(1, length(char_vec), by = 2)
    idx2 <- seq(2, length(char_vec), by = 2)

    cur_days <- char_vec[idx1]
    col1 <- char_vec[idx2]
    col2 <- NA
  } else {
    idx1 <- seq(1, length(char_vec), by = 3)
    idx2 <- seq(2, length(char_vec), by = 3)
    idx3 <- seq(3, length(char_vec), by = 3)

    cur_days <- char_vec[idx1]
    col1 <- char_vec[idx2]
    col2 <- char_vec[idx3]
  }

  df <- dplyr::tibble(
    refdate,
    cur_days,
    col1,
    col2
  )

  colnames(df) <- .$colnames
  if (parse_fields) {
    parse_columns(df, .$colnames, .$handlers, .$.parser())
  } else {
    df
  }
}

stock_indexes_composition_reader <- function(., filename, parse_fields = TRUE) {
  jason <- jsonlite::fromJSON(filename)
  if (is.null(jason$results)) {
    return(NULL)
  }
  df <- jason$results
  df[["update"]] <- jason$header$update
  df[["start_month"]] <- jason$header$startMonth
  df[["end_month"]] <- jason$header$endMonth
  df[["year"]] <- jason$header$year
  colnames(df) <- .$colnames
  if (parse_fields) {
    parse_columns(df, .$colnames, .$handlers, .$.parser())
  } else {
    df
  }
}

stock_indexes_json_reader <- function(., filename, parse_fields = TRUE) {
  jason <- jsonlite::fromJSON(filename)
  l <- list()
  for (part_name in names(.$parts)) {
    part <- .$parts[[part_name]]
    df <- as.data.frame(jason[[part$name]])
    colnames(df) <- part$colnames
    l[[part_name]] <- if (parse_fields) {
      parse_columns(df, part$colnames, part$handlers, .$.parser())
    } else {
      df
    }
  }
  class(l) <- "parts"
  l
}