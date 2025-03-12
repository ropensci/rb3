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
    t[[colnames[i]]] <- str_sub(lines, dx[1], dx[2])
  }

  as.data.frame(t,
    stringsAsFactors = FALSE, optional = TRUE,
    check.names = FALSE
  )
}

trim_fields <- function(x) {
  fields <- lapply(x, function(z) {
    if (is(z, "character")) {
      str_trim(z)
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
  parse_text(parser, df) |> as_tibble()
}

csv_read_file <- function(., filename, parse_fields = TRUE) {
  skip <- if (is.null(.$skip)) 0 else .$skip
  comment <- if (is.null(.$comment)) "#" else .$comment
  df <- read.table(filename,
    col.names = .$colnames, sep = .$separator, skip = skip,
    comment.char = comment, as.is = TRUE, stringsAsFactors = FALSE
  )
  if (parse_fields) {
    parse_columns(df, .$colnames, .$handlers, template_parser(.))
  } else {
    df
  }
}

json_read_file <- function(., filename, parse_fields = TRUE) {
  jason <- fromJSON(filename)
  df <- as.data.frame(jason)
  colnames(df) <- .$colnames
  if (parse_fields) {
    parse_columns(df, .$colnames, .$handlers, template_parser(.))
  } else {
    df
  }
}

mcsv_read_file <- function(., filename, parse_fields = TRUE) {
  lines <- readLines(filename)
  l <- list()
  for (part_name in names(.$parts)) {
    part <- .$parts[[part_name]]
    idx <- template_detect_lines(., part, lines)
    df <- read.table(
      text = lines[idx],
      col.names = part$colnames,
      sep = template_separator(., part),
      as.is = TRUE,
      stringsAsFactors = FALSE,
      check.names = FALSE,
      colClasses = "character"
    )
    l[[part_name]] <- if (parse_fields) {
      parse_columns(df, part$colnames, part$handlers, template_parser(.))
    } else {
      df
    }
  }
  class(l) <- "parts"
  l
}

mfwf_read_file <- function(., filename, parse_fields = TRUE) {
  lines <- readr::read_lines(filename)
  l <- list()
  for (part_name in names(.$parts)) {
    part <- .$parts[[part_name]]
    idx <- template_detect_lines(., part, lines)
    df <- read_fwf(
      text = lines[idx], widths = part$widths,
      colnames = part$colnames
    )
    l[[part_name]] <- if (parse_fields) {
      parse_columns(df, part$colnames, part$handlers, template_parser(.))
    } else {
      df
    }
  }
  class(l) <- "parts"
  l
}

options_open_interest_read <- function(., filename, parse_fields = TRUE) {
  jason <- fromJSON(filename)
  if (is.null(jason$Empresa)) {
    return(NULL)
  }
  df <- do.call(rbind, jason$Empresa)
  names(df) <- .$colnames
  if (parse_fields) {
    parse_columns(df, .$colnames, .$handlers, template_parser(.))
  } else {
    df
  }
}

stock_indexes_composition_reader <- function(., filename, parse_fields = TRUE) {
  jason <- fromJSON(filename)
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
    parse_columns(df, .$colnames, .$handlers, template_parser(.))
  } else {
    df
  }
}

stock_indexes_json_reader <- function(., filename, parse_fields = TRUE) {
  jason <- fromJSON(filename)
  l <- list()
  for (part_name in names(.$parts)) {
    part <- .$parts[[part_name]]
    if (is.null(jason[[part$name]])) {
      return(NULL)
    }
    df <- as.data.frame(jason[[part$name]])
    colnames(df) <- part$colnames
    l[[part_name]] <- if (parse_fields) {
      parse_columns(df, part$colnames, part$handlers, template_parser(.))
    } else {
      df
    }
  }
  class(l) <- "parts"
  l
}

indexreport_reader <- function(., filename, parse_fields = TRUE) {
  doc <- xmlInternalTreeParse(filename)

  indxrpt <- getNodeSet(doc, "//d:IndxRpt", c(d = "urn:bvmf.218.01.xsd"))
  refdate_ <- xmlValue(indxrpt[[1]][["TradDt"]][["Dt"]])

  indxs <- getNodeSet(doc, "//d:IndxInf", c(d = "urn:bvmf.218.01.xsd"))

  df <- map_dfr(indxs, function(node) {
    inf_node <- node[["SctyInf"]]

    tibble(
      refdate = refdate_,
      symbol = xmlValue(inf_node[["SctyId"]][["TckrSymb"]]),
      security_id = xmlValue(inf_node[["FinInstrmId"]][["OthrId"]][["Id"]]),
      security_proprietary = xmlValue(
        inf_node[["FinInstrmId"]][["OthrId"]][["Tp"]][["Prtry"]]
      ),
      security_market = xmlValue(
        inf_node[["FinInstrmId"]][["PlcOfListg"]][["MktIdrCd"]]
      ),
      asset_desc = xmlValue(node[["AsstDesc"]]),
      settlement_price = xmlValue(node[["SttlmVal"]]),
      open = xmlValue(inf_node[["OpngPric"]]),
      min = xmlValue(inf_node[["MinPric"]]),
      max = xmlValue(inf_node[["MaxPric"]]),
      average = xmlValue(inf_node[["TradAvrgPric"]]),
      close = xmlValue(inf_node[["ClsgPric"]]),
      last_price = xmlValue(inf_node[["IndxVal"]]),
      oscillation_val = xmlValue(inf_node[["OscnVal"]]),
      rising_shares_number = xmlValue(node[["RsngShrsNb"]]),
      falling_shares_number = xmlValue(node[["FlngShrsNb"]]),
      stable_shares_number = xmlValue(node[["StblShrsNb"]])
    )
  })

  colnames(df) <- .$colnames
  if (parse_fields) {
    parse_columns(df, .$colnames, .$handlers, template_parser(.))
  } else {
    df
  }
}

company_listed_supplement_reader <- function(., filename, parse_fields = TRUE) {
  jason <- fromJSON(filename)
  l <- list()
  for (part_name in names(.$parts)) {
    part <- .$parts[[part_name]]
    if (part_name == "Info") {
      df <- tibble(
        stockCapital = ck_if_null(jason$stockCapital),
        segment = ck_if_null(jason$segment),
        quotedPerSharSince = ck_if_null(jason$quotedPerSharSince),
        commonSharesForm = ck_if_null(jason$commonSharesForm),
        preferredSharesForm = ck_if_null(jason$preferredSharesForm),
        hasCommom = ck_if_null(jason$hasCommom),
        hasPreferred = ck_if_null(jason$hasPreferred),
        code = ck_if_null(jason$code),
        codeCVM = ck_if_null(jason$codeCVM),
        totalNumberShares = ck_if_null(jason$totalNumberShares),
        numberCommonShares = ck_if_null(jason$numberCommonShares),
        numberPreferredShares = ck_if_null(jason$numberPreferredShares),
        roundLot = ck_if_null(jason$roundLot),
        tradingName = ck_if_null(jason$tradingName),
      )
    } else {
      df <- as.data.frame(jason[[part$name]][[1]])
    }
    if (length(df) == 0) {
      next
    }
    colnames(df) <- part$colnames
    l[[part_name]] <- if (parse_fields) {
      parse_columns(df, part$colnames, part$handlers, template_parser(.))
    } else {
      df
    }
  }
  class(l) <- "parts"
  l
}

company_details_reader <- function(., filename, parse_fields = TRUE) {
  jason <- fromJSON(filename)
  l <- list()
  for (part_name in names(.$parts)) {
    part <- .$parts[[part_name]]
    if (part_name == "Info") {
      df <- tibble(
        issuingCompany = ck_if_null(jason$issuingCompany),
        companyName = ck_if_null(jason$companyName),
        tradingName = ck_if_null(jason$tradingName),
        cnpj = ck_if_null(jason$cnpj),
        industryClassification = ck_if_null(jason$industryClassification),
        industryClassificationEng = ck_if_null(jason$industryClassificationEng),
        activity = ck_if_null(jason$activity),
        website = ck_if_null(jason$website),
        hasQuotation = ck_if_null(jason$hasQuotation),
        status = ck_if_null(jason$status),
        marketIndicator = ck_if_null(jason$marketIndicator),
        market = ck_if_null(jason$market),
        institutionCommon = ck_if_null(jason$institutionCommon),
        institutionPreferred = ck_if_null(jason$institutionPreferred),
        code = ck_if_null(jason$code),
        codeCVM = ck_if_null(jason$codeCVM),
        lastDate = ck_if_null(jason$lastDate),
        hasEmissions = ck_if_null(jason$hasEmissions),
        hasBDR = ck_if_null(jason$hasBDR),
        typeBDR = ck_if_null(jason$typeBDR),
        describleCategoryBVMF = ck_if_null(jason$describleCategoryBVMF),
      )
    } else {
      df <- as.data.frame(jason[[part$name]])
    }
    if (length(df) == 0) {
      next
    }
    colnames(df) <- part$colnames
    l[[part_name]] <- if (parse_fields) {
      parse_columns(df, part$colnames, part$handlers, template_parser(.))
    } else {
      df
    }
  }
  class(l) <- "parts"
  l
}

company_cash_dividends_reader <- function(., filename, parse_fields = TRUE) {
  jason <- fromJSON(filename)
  if (length(jason$results) == 0) {
    return(NULL)
  }
  df <- as.data.frame(jason[["results"]])
  colnames(df) <- .$colnames
  if (parse_fields) {
    parse_columns(df, .$colnames, .$handlers, template_parser(.))
  } else {
    df
  }
}

ck_if_null <- function(x) {
  if (is.null(x)) {
    ""
  } else {
    x
  }
}
