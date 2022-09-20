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

fwf_read_file <- function(., filename, parse_fields = TRUE) {
  df <- read_fwf(filename, .$widths, colnames = .$colnames)
  if (parse_fields) {
    parse_columns(df, .$colnames, .$handlers, .$.parser())
  } else {
    df
  }
}

csv_read_file <- function(., filename, parse_fields = TRUE) {
  skip <- try(.$skip, TRUE)
  skip <- if (is(skip, "try-error")) 0 else skip
  comment <- try(.$comment, TRUE)
  comment <- if (is(comment, "try-error")) "#" else comment
  df <- read.table(filename,
    col.names = .$colnames, sep = .$separator, skip = skip,
    comment.char = comment, as.is = TRUE, stringsAsFactors = FALSE
  )
  if (parse_fields) {
    parse_columns(df, .$colnames, .$handlers, .$.parser())
  } else {
    df
  }
}

json_read_file <- function(., filename, parse_fields = TRUE) {
  jason <- fromJSON(filename)
  df <- as.data.frame(jason)
  colnames(df) <- .$colnames
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

settlement_prices_read <- function(., filename, parse_fields = TRUE) {
  doc <- read_html(filename)
  xpath <- "//table[contains(@id, 'tblDadosAjustes')]"
  table <- html_element(doc, xpath = xpath)
  if (is(table, "xml_node")) {
    df <- html_table(table)
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
  jason <- fromJSON(filename)
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
  text <- read_file(filename)

  char_vec <- read_html(text) |>
    html_nodes("td") |>
    html_text()

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

  df <- tibble(
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
    parse_columns(df, .$colnames, .$handlers, .$.parser())
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
      parse_columns(df, part$colnames, part$handlers, .$.parser())
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
    parse_columns(df, .$colnames, .$handlers, .$.parser())
  } else {
    df
  }
}

pricereport_reader <- function(., filename, parse_fields = TRUE) {
  doc <- xmlInternalTreeParse(filename)
  negs <- getNodeSet(doc, "//d:PricRpt", c(d = "urn:bvmf.217.01.xsd"))

  df <- map_dfr(negs, function(node) {
    refdate <- xmlValue(node[["TradDt"]][["Dt"]])
    ticker <- xmlValue(node[["SctyId"]][["TckrSymb"]])
    attrib <- node[["FinInstrmAttrbts"]]

    tibble(
      refdate = refdate,
      ticker_symbol = ticker,
      security_id = xmlValue(node[["FinInstrmId"]][["OthrId"]][["Id"]]),
      security_proprietary = xmlValue(
        node[["FinInstrmId"]][["OthrId"]][["Tp"]][["Prtry"]]
      ),
      security_market = xmlValue(
        node[["FinInstrmId"]][["PlcOfListg"]][["MktIdrCd"]]
      ),
      volume = xmlValue(attrib[["NtlFinVol"]]),
      open_interest = xmlValue(attrib[["OpnIntrst"]]),
      traded_contracts = xmlValue(attrib[["FinInstrmQty"]]),
      best_ask_price = xmlValue(attrib[["BestAskPric"]]),
      best_bid_price = xmlValue(attrib[["BestBidPric"]]),
      first_price = xmlValue(attrib[["FrstPric"]]),
      min_price = xmlValue(attrib[["MinPric"]]),
      max_price = xmlValue(attrib[["MaxPric"]]),
      last_price = xmlValue(attrib[["LastPric"]]),
      average_price = xmlValue(attrib[["TradAvrgPric"]]),
      regular_transactions_quantity = xmlValue(attrib[["RglrTxsQty"]]),
      regular_traded_contracts = xmlValue(attrib[["RglrTraddCtrcts"]]),
      regular_volume = xmlValue(attrib[["NtlRglrVol"]]),
      nonregular_transactions_quantity = xmlValue(attrib[["NonRglrTxsQty"]]),
      nonregular_traded_contracts = xmlValue(attrib[["NonRglrTraddCtrcts"]]),
      nonregular_volume = xmlValue(attrib[["NtlNonRglrVol"]]),
      oscillation_percentage = xmlValue(attrib[["OscnPctg"]]),
      adjusted_quote = xmlValue(attrib[["AdjstdQt"]]),
      adjusted_tax = xmlValue(attrib[["AdjstdQtTax"]]),
      previous_adjusted_quote = xmlValue(attrib[["PrvsAdjstdQt"]]),
      previous_adjusted_tax = xmlValue(attrib[["PrvsAdjstdQtTax"]]),
      variation_points = xmlValue(attrib[["VartnPts"]]),
      adjusted_value_contract = xmlValue(attrib[["AdjstdValCtrct"]]),
    )
  })

  colnames(df) <- .$colnames
  if (parse_fields) {
    parse_columns(df, .$colnames, .$handlers, .$.parser())
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
      parse_columns(df, part$colnames, part$handlers, .$.parser())
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
      parse_columns(df, part$colnames, part$handlers, .$.parser())
    } else {
      df
    }
  }
  class(l) <- "parts"
  l
}

company_cash_dividends_reader <- function(., filename, parse_fields = TRUE) {
  jason <- fromJSON(filename)
  if (length(jason$results) == 0)  {
    return(NULL)
  }
  df <- as.data.frame(jason[["results"]])
  colnames(df) <- .$colnames
  if (parse_fields) {
    parse_columns(df, .$colnames, .$handlers, .$.parser())
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
