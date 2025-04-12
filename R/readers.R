.parse_columns <- function(., df) {
  loc <- if (is.null(.$reader$locale)) {
    readr::locale()
  } else {
    do.call(readr::locale, .$reader$locale)
  }
  cols <- fields_cols(.$fields)
  for (nx in .$colnames) {
    df[[nx]] <- readr::parse_vector(as.character(df[[nx]]), cols[[nx]], locale = loc)
  }
  df
}

csv_read_file <- function(., filename, ...) {
  df <- readr::read_csv(filename,
    col_names = .$colnames, col_types = fields_cols(.$fields),
    locale = readr::locale(), skip = .$reader$skip
  )
  df
}

fwf_read_file <- function(., filename, ...) {
  encoding <- if (!is.null(.$reader) && !is.null(.$reader$encoding)) .$reader$encoding else "UTF-8"
  suppressWarnings(
    df <- readr::read_fwf(filename, readr::fwf_widths(.$widths, .$colnames),
      col_types = fields_cols(.$fields), locale = readr::locale(encoding = encoding)
    )
  )
  hs <- fields_handlers(.$fields)
  ns <- sapply(hs, \(h) attr(h, "type")) == "numeric"
  for (nx in colnames(df)[ns]) {
    df[[nx]] <- suppressWarnings(hs[[nx]](df[[nx]]))
  }
  df
}

flatten_names <- function(nx) {
  for (ix in seq_along(nx)) {
    if (!is.na(nx[ix])) {
      last_name <- nx[ix]
    }
    nx[ix] <- last_name
  }
  x <- nx |> str_match("^(\\w+)")
  as.vector(x[, 2])
}

settlement_prices_read <- function(., filename, ...) {
  doc <- htmlTreeParse(filename, encoding = "UTF8", useInternalNodes = TRUE)
  refdate_ns <- getNodeSet(doc, "//p[contains(@class, 'small-text-left legenda')]")
  if (length(refdate_ns) > 0) {
    refdate <- str_match(xmlValue(refdate_ns[[1]]), "\\d{2}/\\d{2}/\\d{4}")[1, 1]
  }
  xpath <- "//table[contains(@id, 'tblDadosAjustes')]"
  table <- getNodeSet(doc, xpath)
  if (is(table, "XMLNodeSet") && length(table) == 1) {
    tb <- table[[1]]
    vals <- sapply(tb[["tbody"]]["tr"], \(x) sapply(x["td"], xmlValue))
    dm <- matrix(vals, nrow = ncol(vals), byrow = TRUE)
  } else {
    return(NULL)
  }
  dm <- cbind(dm, refdate)
  colnames(dm) <- .$colnames
  df <- as_tibble(dm)

  df <- .parse_columns(., df)
  df[["commodity"]] <- flatten_names(df[["commodity"]])
  df
}

cols_number <- c(
  ACC = 2, BRP = 2, DCO = 2, DIC = 2, DIM = 2, DOC = 2, DOL = 2, EUC = 2,
  EUR = 2, INP = 2, JPY = 2, LIB = 2, PTX = 2, SDE = 2, SLP = 2, APR = 3,
  DP = 3, PRE = 3, TFP = 3, TP = 3, TR = 3
)

curve_read <- function(., filename, ...) {
  text <- read_file(filename)
  doc <- htmlTreeParse(filename, encoding = "UTF8", useInternalNodes = TRUE)
  char_vec <- xmlSApply(getNodeSet(doc, "//table/td"), xmlValue)

  if (length(char_vec) == 0) {
    return(NULL)
  }

  ctx <- str_match(text, "\"([A-Z]+)\"\\s+selected")
  curve_name <- ctx[1, 2]

  mtx <- str_match(text, "Atualizado em: (\\d{2}/\\d{2}/\\d{4})")
  refdate <- mtx[1, 2]

  if (cols_number[curve_name] == 2) {
    idx1 <- seq(1, length(char_vec), by = 2)
    idx2 <- seq(2, length(char_vec), by = 2)

    cur_days <- char_vec[idx1]
    col1 <- char_vec[idx2]
    col2 <- NA_character_
  } else {
    idx1 <- seq(1, length(char_vec), by = 3)
    idx2 <- seq(2, length(char_vec), by = 3)
    idx3 <- seq(3, length(char_vec), by = 3)

    cur_days <- char_vec[idx1]
    col1 <- char_vec[idx2]
    col2 <- char_vec[idx3]
  }

  df <- tibble(
    refdate,
    curve_name,
    cur_days,
    col1,
    col2
  )
  colnames(df) <- .$colnames

  .parse_columns(., df)
}

pricereport_reader <- function(., filename, ...) {
  count_handler <- \(name, attrs, .state) (.state <- .state + 1)
  n_rows <- XML::xmlEventParse(
    filename,
    handlers = list(PricRpt = count_handler),
    state = 0
  )

  fin_instrm_id_names <- c(Id = "security_id", Prtry = "security_proprietary", MktIdrCd = "security_market")
  .tags <- Filter(\(x) !x %in% names(fin_instrm_id_names), fields_tags(.$fields))
  fin_instrm_names <- stats::setNames(names(.tags), .tags)

  start_handler <- function(name, attrs, .state) {
    if (name == "PricRpt") {
      .state$count <- .state$count + 1
    } else if (name == "FinInstrmId") {
      .state$collecting_fin_instrm_id <- TRUE
    } else if (!.state$collecting_fin_instrm_id && name %in% names(fin_instrm_names)) {
      .state$column <- fin_instrm_names[name]
      .state$collecting <- TRUE
    } else if (.state$collecting_fin_instrm_id && name %in% names(fin_instrm_id_names)) {
      .state$column <- fin_instrm_id_names[name]
      .state$collecting <- TRUE
    }
    .state
  }
  text_handler <- function(text, .state) {
    if (.state$collecting) {
      .state$data[[.state$column]][.state$count] <- text
      .state$collecting <- FALSE
    }
    .state
  }
  end_handler <- function(name, .state) {
    if (name == "FinInstrmId") {
      .state$collecting_fin_instrm_id <- FALSE
    }
    .state
  }
  envir <- list()
  envir$count <- 0
  envir$collecting <- FALSE
  envir$collecting_fin_instrm_id <- FALSE
  envir$data <- list()
  for (n in fin_instrm_names) envir$data[[n]] <- character(n_rows)
  for (n in fin_instrm_id_names) envir$data[[n]] <- character(n_rows)
  envir <- XML::xmlEventParse(filename,
    handlers = list(
      startElement = start_handler,
      text = text_handler,
      endElement = end_handler
    ),
    state = envir
  )

  df <- as_tibble(envir$data)
  df <- df[, fields_names(.$fields)]
  .parse_columns(., df)
}

read_file_wrapper <- function(., filename, meta) {
  download_args <- jsonlite::fromJSON(meta$download_args)
  if (!is.null(meta$extra_arg)) {
    download_args[["extra_arg"]] <- meta$extra_arg
  }
  do.call(.$read_file, append(list(., filename), download_args))
}

stock_indexes_json_reader <- function(., filename, ...) {
  args_ <- list(...)
  jason <- try(fromJSON(filename), silent = TRUE)
  if (inherits(jason, "try-error")) {
    return(NULL)
  }
  df <- tibble::as_tibble(jason$results)
  if (.$id %in% c("b3-indexes-theoretical-portfolio", "b3-indexes-current-portfolio")) {
    df$header_part <- jason$header$part
    df$header_theoricalQty <- jason$header$theoricalQty
    df$header_reductor <- jason$header$reductor
    df$index <- args_$index
    df$refdate <- args_$extra_arg
    if (hasName(jason$header, "date")) {
      df$portfolio_date <- strptime(jason$header$date, "%d/%m/%y")
    }
  } else if (.$id == "b3-indexes-historical-data") {
    df$year <- args_$year
    df$index <- args_$index
  } else if (.$id == "b3-indexes-composition") {
    df$refdate <- args_$extra_arg
    df$update_date <- jason$header$update
    df$start_month <- jason$header$startMonth
    df$end_month <- jason$header$endMonth
    df$year <- jason$header$year
  } else {
    cli::cli_abort("Invalid template {.$id}")
  }

  colnames(df) <- .$colnames
  .parse_columns(., df)
}
