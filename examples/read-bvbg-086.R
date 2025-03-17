.meta <- download_marketdata("b3-bvbg-086", do_cache = TRUE, refdate = "2018-01-02")
meta_clean(.meta)

library(XML)

names_map <- list(
  NtlFinVol = "volume",
  OpnIntrst = "open_interest",
  FinInstrmQty = "traded_contracts",
  BestAskPric = "best_ask_price",
  BestBidPric = "best_bid_price",
  FrstPric = "first_price",
  MinPric = "min_price",
  MaxPric = "max_price",
  LastPric = "last_price",
  TradAvrgPric = "average_price",
  RglrTxsQty = "regular_transactions_quantity",
  RglrTraddCtrcts = "regular_traded_contracts",
  NtlRglrVol = "regular_volume",
  NonRglrTxsQty = "nonregular_transactions_quantity",
  NonRglrTraddCtrcts = "nonregular_traded_contracts",
  NtlNonRglrVol = "nonregular_volume",
  OscnPctg = "oscillation_percentage",
  AdjstdQt = "adjusted_quote",
  AdjstdQtTax = "adjusted_tax",
  PrvsAdjstdQt = "previous_adjusted_quote",
  PrvsAdjstdQtTax = "previous_adjusted_tax",
  VartnPts = "variation_points",
  AdjstdValCtrct = "adjusted_value_contract",
  TckrSymb = "symbol",
  Dt = "trade_date"
)

handler <- function(name, attrs, .state) {
  if (name == "PricRpt") {
    .state$count <- .state$count + 1
  } else if (name %in% names(names_map)) {
    .state$column <- names_map[[name]]
    .state$collecting <- TRUE
  } else if (name == "FinInstrmId") {
    .state$collecting_fin_instrm_id <- TRUE
  } else if (.state$collecting_fin_instrm_id && name == "Id") {
    .state$column <- "security_id"
    .state$collecting <- TRUE
  }
  .state
}
text_handler <- function(text, .state) {
  if (.state$collecting) {
    .state[[.state$column]][.state$count] <- text
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
envir = new.env()
envir$count <- 0
envir$collecting <- FALSE
envir$collecting_fin_instrm_id <- FALSE
for (n in names_map) {
  envir[[n]] <- character(1)
}
xmlEventParse(.meta$downloaded[[1]],
  handlers = list(startElement = handler, text = text_handler, endElement = end_handler),
  state = envir
)
tibble(
  envir$trade_date,
  envir$symbol,
  envir$security_id,
  envir$last_price,
  envir$volume,
)

envir$close

handler <- function(name, attrs) {
  cat(name, "\n") # Process each XML node
}

xmlEventParse(.meta$downloaded[[1]],
  handlers = list("TckrSymb" = handler),
  state = 0
)


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
.parse_columns(., df)
