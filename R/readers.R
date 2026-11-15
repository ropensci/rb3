.parse_columns <- function(., df) {
  loc <- if (is.null(.$reader$locale)) {
    readr::locale()
  } else {
    do.call(readr::locale, .$reader$locale)
  }
  cols <- fields_collectors(.$fields)
  for (nx in .$colnames) {
    df[[nx]] <- readr::parse_vector(as.character(df[[nx]]), cols[[nx]], locale = loc)
  }
  df
}

csv_read_file <- function(., filename, ...) {
  df <- readr::read_csv(filename,
    col_names = .$colnames, col_types = fields_collectors(.$fields),
    locale = readr::locale(), skip = .$reader$skip
  )
  df
}

fwf_read_file <- function(., filename, ...) {
  encoding <- if (!is.null(.$reader) && !is.null(.$reader$encoding)) .$reader$encoding else "UTF-8"
  suppressWarnings(
    df <- readr::read_fwf(filename, readr::fwf_widths(.$widths, .$colnames),
      col_types = fields_collectors(.$fields), locale = readr::locale(encoding = encoding)
    )
  )
  hs <- fields_handlers(.$fields)
  for (nx in colnames(df)) {
    df[[nx]] <- hs[[nx]](df[[nx]])
  }
  df
}

# BDI "Negócios consolidados do pregão - Derivativos" CSV export: every row and column
bdi_derivatives_read <- function(., filename, ...) {
  args <- list(...)
  lines <- readr::read_lines(filename)
  header <- which(str_starts(lines, "Ticker symbol"))
  if (length(header) == 0) {
    return(NULL)
  }
  df <- suppressWarnings(readr::read_delim(filename,
    delim = ";", skip = header - 1, na = c("", "-"),
    col_types = readr::cols(.default = readr::col_character()), show_col_types = FALSE
  ))
  cols <- c(
    symbol = "Ticker symbol", isin = "ISIN code", segment = "Segment",
    open = "Opening price", low = "Minimum price", high = "Maximum price",
    average = "Trade average price", close = "Last price", oscillation = "Oscillation",
    adjusted_quote = "Adjusted quote", adjusted_tax = "Adjusted quote tax",
    # mislabeled in the english export: it holds the previous settlement price
    previous_adjusted_quote = "Previous adjusted quote tax",
    reference_price = "Reference price", variation_points = "Variation",
    adjusted_value_contract = "Settlement value per contract (R$)",
    best_bid_price = "Last buy order", best_ask_price = "Last sell order",
    transactions_quantity = "Trade quantity", traded_contracts = "Financial instrument quantity",
    volume = "National financial volume"
  )
  df <- dplyr::select(df, dplyr::all_of(cols))
  num <- setdiff(names(cols), c("symbol", "isin", "segment"))
  df[num] <- lapply(df[num], readr::parse_number)
  df$refdate <- as.Date(args$refdate)
  df
}

settlement_prices_read <- function(., filename, ...) {
  # raw files downloaded before #125 are the old "Ajustes do pregão" HTML page
  if (startsWith(trimws(readr::read_file(filename)), "<")) {
    return(settlement_prices_html_read(filename, ...))
  }
  df <- bdi_derivatives_read(., filename, ...)
  if (is.null(df)) {
    return(NULL)
  }
  # only futures carry a settlement price ("Adjusted quote")
  df <- df[!is.na(df$adjusted_quote), ]
  dplyr::tibble(
    commodity = str_sub(df$symbol, 1, -4),
    maturity_code = str_sub(df$symbol, -3),
    previous_price = df$previous_adjusted_quote,
    price = df$adjusted_quote,
    price_change = df$variation_points,
    settlement_value = df$adjusted_value_contract,
    refdate = df$refdate
  )
}

# Old www2.bmf.com.br "Ajustes do pregão" page (discontinued, #125): kept to read cached raw files
settlement_prices_html_read <- function(filename, ...) {
  args <- list(...)
  doc <- XML::htmlTreeParse(filename, encoding = "UTF8", useInternalNodes = TRUE)
  table <- XML::getNodeSet(doc, "//table[contains(@id, 'tblDadosAjustes')]")
  if (length(table) != 1) {
    return(NULL)
  }
  vals <- sapply(table[[1]][["tbody"]]["tr"], \(x) sapply(x["td"], XML::xmlValue))
  dm <- matrix(vals, nrow = ncol(vals), byrow = TRUE)
  refdate_ns <- XML::getNodeSet(doc, "//p[contains(@class, 'small-text-left legenda')]")
  refdate <- if (length(refdate_ns) > 0) {
    as.Date(str_match(XML::xmlValue(refdate_ns[[1]]), "\\d{2}/\\d{2}/\\d{4}")[1, 1], "%d/%m/%Y")
  } else {
    as.Date(args$refdate)
  }
  chr <- function(x) readr::parse_character(x, na = c("", "NA"))
  num <- function(x) readr::parse_number(x, locale = readr::locale(decimal_mark = ",", grouping_mark = "."))
  dplyr::tibble(
    commodity = flatten_names(chr(dm[, 1])),
    maturity_code = chr(dm[, 2]),
    previous_price = num(dm[, 3]),
    price = num(dm[, 4]),
    price_change = num(dm[, 5]),
    settlement_value = num(dm[, 6]),
    refdate = refdate
  )
}

# commodity is only filled on the first row of each group: carry it down and keep the code
flatten_names <- function(nx) {
  for (ix in seq_along(nx)) {
    if (!is.na(nx[ix])) {
      last_name <- nx[ix]
    }
    nx[ix] <- last_name
  }
  as.vector(str_match(nx, "^(\\w+)")[, 2])
}

# B3 file "Mercado de Derivativos - Taxas de Mercado para Swaps" (TaxaSwap.txt, fixed width)
curve_read <- function(., filename, ...) {
  cols <- readr::fwf_widths(
    c(6, 3, 2, 8, 2, 5, 15, 5, 5, 1, 14, 1, 5),
    c(
      "seq", "seq_compl", "regtype", "refdate", "curve_type", "curve_name", "description",
      "cur_days", "biz_days", "sign", "rate", "vertex_type", "vertex_code"
    )
  )
  df <- readr::read_fwf(filename, cols,
    col_types = readr::cols(.default = readr::col_character()),
    locale = readr::locale(encoding = .$reader$encoding)
  )
  dplyr::tibble(
    refdate = as.Date(df$refdate, "%Y%m%d"),
    curve_name = df$curve_name,
    cur_days = as.integer(df$cur_days),
    biz_days = as.integer(df$biz_days),
    rate = as.numeric(paste0(df$sign, df$rate)) / 1e7 # 7 decimals, in percent
  )
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

  df <- dplyr::as_tibble(envir$data)
  df <- df[, fields_names(.$fields)]
  .parse_columns(., df)
}

read_file_wrapper <- function(., filename, meta) {
  download_args <- meta$download_args
  if (!is.null(meta$extra_arg)) {
    download_args[["extra_arg"]] <- meta$extra_arg
  }
  do.call(.$read_file, append(list(., filename), download_args))
}

stock_indexes_json_reader <- function(., filename, ...) {
  args_ <- list(...)
  jason <- try(jsonlite::fromJSON(filename), silent = TRUE)
  if (inherits(jason, "try-error")) {
    return(NULL)
  }
  df <- dplyr::as_tibble(jason$results)
  if (.$id %in% c("b3-indexes-theoretical-portfolio", "b3-indexes-current-portfolio")) {
    df$header_part <- jason$header$part
    df$header_theoricalQty <- jason$header$theoricalQty
    df$header_reductor <- jason$header$reductor
    df$index <- args_$index
    df$refdate <- args_$extra_arg
    if (utils::hasName(jason$header, "date")) {
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
