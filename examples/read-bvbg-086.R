t <- template_retrieve("b3-bvbg-086")
.meta <- download_marketdata("b3-bvbg-086", do_cache = TRUE, refdate = "2025-03-10")
df <- read_marketdata(.meta)

df <- pricereport_reader(t, .meta$downloaded[[1]])
df <- df[, fields_names(t$fields)]
df <- .parse_columns(t, df)
tb <- arrow::arrow_table(df, schema = template_schema(t))


library(XML)

pricereport_reader <- function(., filename) {
  count_handler <- \(name, attrs, .state) (.state <- .state + 1)
  n_rows <- XML::xmlEventParse(
    filename,
    handlers = list(PricRpt = count_handler),
    state = 0
  )

  fin_instrm_id_names <- c(Id = "security_id", Prtry = "security_proprietary", MktIdrCd = "security_market")
  .tags <- Filter(\(x) !x %in% names(fin_instrm_id_names), fields_tags(.$fields))
  fin_instrm_names <- setNames(names(.tags), .tags)

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
  .parse_columns(., df)
}



# doc <- xmlInternalTreeParse(filename)
# negs <- getNodeSet(doc, "//d:PricRpt", c(d = "urn:bvmf.217.01.xsd"))

# df <- map_dfr(negs, function(node) {
#   refdate <- xmlValue(node[["TradDt"]][["Dt"]])
#   ticker <- xmlValue(node[["SctyId"]][["TckrSymb"]])
#   attrib <- node[["FinInstrmAttrbts"]]

#   tibble(
#     refdate = refdate,
#     ticker_symbol = ticker,
#     security_id = xmlValue(node[["FinInstrmId"]][["OthrId"]][["Id"]]),
#     security_proprietary = xmlValue(
#       node[["FinInstrmId"]][["OthrId"]][["Tp"]][["Prtry"]]
#     ),
#     security_market = xmlValue(
#       node[["FinInstrmId"]][["PlcOfListg"]][["MktIdrCd"]]
#     ),
#     volume = xmlValue(attrib[["NtlFinVol"]]),
#     open_interest = xmlValue(attrib[["OpnIntrst"]]),
#     traded_contracts = xmlValue(attrib[["FinInstrmQty"]]),
#     best_ask_price = xmlValue(attrib[["BestAskPric"]]),
#     best_bid_price = xmlValue(attrib[["BestBidPric"]]),
#     first_price = xmlValue(attrib[["FrstPric"]]),
#     min_price = xmlValue(attrib[["MinPric"]]),
#     max_price = xmlValue(attrib[["MaxPric"]]),
#     last_price = xmlValue(attrib[["LastPric"]]),
#     average_price = xmlValue(attrib[["TradAvrgPric"]]),
#     regular_transactions_quantity = xmlValue(attrib[["RglrTxsQty"]]),
#     regular_traded_contracts = xmlValue(attrib[["RglrTraddCtrcts"]]),
#     regular_volume = xmlValue(attrib[["NtlRglrVol"]]),
#     nonregular_transactions_quantity = xmlValue(attrib[["NonRglrTxsQty"]]),
#     nonregular_traded_contracts = xmlValue(attrib[["NonRglrTraddCtrcts"]]),
#     nonregular_volume = xmlValue(attrib[["NtlNonRglrVol"]]),
#     oscillation_percentage = xmlValue(attrib[["OscnPctg"]]),
#     adjusted_quote = xmlValue(attrib[["AdjstdQt"]]),
#     adjusted_tax = xmlValue(attrib[["AdjstdQtTax"]]),
#     previous_adjusted_quote = xmlValue(attrib[["PrvsAdjstdQt"]]),
#     previous_adjusted_tax = xmlValue(attrib[["PrvsAdjstdQtTax"]]),
#     variation_points = xmlValue(attrib[["VartnPts"]]),
#     adjusted_value_contract = xmlValue(attrib[["AdjstdValCtrct"]]),
#   )
# })

# colnames(df) <- .$colnames
# .parse_columns(., df)
