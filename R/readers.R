.parse_columns <- function(., df) {
  loc <- do.call(readr::locale, .$reader$locale)
  cols <- fields_cols(.$fields)
  for (nx in .$colnames) {
    df[[nx]] <- readr::parse_vector(df[[nx]], cols[[nx]], locale = loc)
  }
  df
}

fwf_read_file <- function(., filename) {
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

settlement_prices_read <- function(., filename) {
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

curve_read <- function(., filename) {
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

pricereport_reader <- function(., filename) {
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
  df
}