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

settlement_prices_read <- function(., filename, ...) {
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
  # only futures carry a settlement price ("Adjusted quote")
  df <- df[!is.na(df[["Adjusted quote"]]), ]
  symbol <- df[["Ticker symbol"]]
  dplyr::tibble(
    commodity = str_sub(symbol, 1, -4),
    maturity_code = str_sub(symbol, -3),
    # mislabeled in the english export: it holds the previous settlement price
    previous_price = readr::parse_number(df[["Previous adjusted quote tax"]]),
    price = readr::parse_number(df[["Adjusted quote"]]),
    price_change = readr::parse_number(df[["Variation"]]),
    settlement_value = readr::parse_number(df[["Settlement value per contract (R$)"]]),
    refdate = as.Date(args$refdate)
  )
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
