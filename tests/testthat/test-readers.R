test_that("curve_read parses the TS swap rates file", {
  tpl <- template_retrieve("b3-reference-rates")
  df <- curve_read(tpl, test_path("testdata", "TaxaSwap-sample.txt"))
  expect_equal(nrow(df), 4)
  expect_equal(df$refdate, rep(as.Date("2026-09-11"), 4))
  expect_equal(df$curve_name, c("DOC", "DOC", "PRE", "PRE"))
  expect_equal(df$cur_days[1], 3L)
  expect_equal(df$biz_days[1], 1L)
  expect_equal(df$rate[3], 13.9)
})

test_that("settlement_prices_read keeps only instruments with a settlement price", {
  tpl <- template_retrieve("b3-futures-settlement-prices")
  df <- settlement_prices_read(tpl, test_path("testdata", "bdm-derivatives-sample.csv"),
    refdate = as.Date("2026-09-11")
  )
  expect_equal(nrow(df), 2)
  expect_equal(df$commodity, c("DI1", "DI1"))
  expect_equal(df$maturity_code, c("F27", "F28"))
  expect_equal(df$price[1], 96230.69)
  expect_equal(df$previous_price[1], 96230.96)
  expect_equal(df$price_change[1], -0.27)
  expect_equal(df$settlement_value[1], -0.27)
  expect_equal(df$refdate, rep(as.Date("2026-09-11"), 2))
})

test_that("bdi_derivatives_read keeps every row and column of the BDI export", {
  tpl <- template_retrieve("b3-bdi-derivatives-trades")
  df <- bdi_derivatives_read(tpl, test_path("testdata", "bdm-derivatives-sample.csv"),
    refdate = as.Date("2026-09-11")
  )
  expect_equal(nrow(df), 3)
  expect_equal(names(df), tpl$colnames)
  expect_equal(df$symbol, c("BGIU26C032400", "DI1F27", "DI1F28"))
  expect_equal(df$reference_price[1], 34.32)
  expect_true(is.na(df$adjusted_quote[1]))
  di1 <- df[2, ]
  expect_equal(di1$isin, "BRBMEFD1I4Z0")
  expect_equal(di1$segment, "FINANCIAL")
  expect_equal(di1$open, 13.58)
  expect_equal(di1$close, 13.585)
  expect_equal(di1$adjusted_quote, 96230.69)
  expect_equal(di1$adjusted_tax, 13.587)
  expect_equal(di1$previous_adjusted_quote, 96230.96)
  expect_equal(di1$transactions_quantity, 3666)
  expect_equal(di1$traded_contracts, 380324)
  expect_equal(di1$volume, 36599672680)
  expect_equal(df$volume[3], 51191776839.8)
  expect_equal(df$refdate, rep(as.Date("2026-09-11"), 3))
})

test_that("settlement_prices_read also reads the old Ajustes do pregao HTML page", {
  tpl <- template_retrieve("b3-futures-settlement-prices")
  df <- settlement_prices_read(tpl, test_path("testdata", "ajustes-pregao-sample.html"),
    refdate = as.Date("2025-11-13")
  )
  expect_equal(names(df), tpl$colnames)
  expect_equal(nrow(df), 3)
  expect_equal(df$commodity, c("ABEVO", "ABEVO", "AFS"))
  expect_equal(df$maturity_code, c("X25", "Z25", "X25"))
  expect_equal(df$previous_price[3], 17086.6)
  expect_equal(df$price[3], 17061.9)
  expect_equal(df$price_change[3], -24.7)
  expect_equal(df$settlement_value[3], 76.68)
  expect_equal(df$refdate, rep(as.Date("2025-11-13"), 3))
})

test_that("trade_information_read keeps every row and column of TradeInformationConsolidated", {
  tpl <- template_retrieve("b3-trade-information-consolidated")
  df <- trade_information_read(tpl, test_path("testdata", "trade-information-consolidated-sample.csv"),
    refdate = as.Date("2026-11-13")
  )
  expect_equal(names(df), tpl$colnames)
  expect_equal(nrow(df), 5)
  expect_equal(df$symbol[1:4], c("03BK11", "PETR4", "DI1F27", "DI1F28"))
  expect_equal(df$segment[1:4], c("FORWARD", "CASH", "FINANCIAL", "FINANCIAL"))
  expect_equal(df$refdate, rep(as.Date("2026-11-13"), 5))
  petr <- df[2, ]
  expect_equal(petr$low, 44.62)
  expect_equal(petr$close, 45.3)
  expect_true(is.na(petr$adjusted_quote))
  expect_equal(petr$transactions_quantity, 38937)
  expect_equal(petr$volume, 1056495127)
  di1 <- df[3, ]
  expect_equal(di1$adjusted_quote, 98336.11)
  expect_equal(di1$adjusted_tax, 13.67)
  expect_equal(di1$traded_contracts, 111770)
  expect_equal(di1$volume, 10991078014.94)
})

test_that("fwf_read_file defaults to UTF-8 and applies negative numeric signs", {
  fs <- fields(
    field("code", "", width(3), type("character")),
    field("value", "", width(5), type("numeric", dec = 2, sign = "-"))
  )
  tpl <- list(fields = fs, widths = fields_widths(fs), colnames = fields_names(fs)) # no reader: UTF-8
  f <- withr::local_tempfile(lines = c("ABC01234", "XYZ00050"))
  df <- fwf_read_file(tpl, f)
  expect_equal(df$code, c("ABC", "XYZ"))
  expect_equal(df$value, c(-12.34, -0.5))
})

test_that("readers return NULL for files without data", {
  empty <- withr::local_tempfile(lines = "nothing here")
  expect_null(bdi_derivatives_read(template_retrieve("b3-bdi-derivatives-trades"), empty))
  expect_null(settlement_prices_read(template_retrieve("b3-futures-settlement-prices"), empty))
  expect_null(stock_indexes_json_reader(template_retrieve("b3-indexes-composition"), empty))
  header_only <- withr::local_tempfile(lines = c("title", "a;b"))
  expect_null(trade_information_read(template_retrieve("b3-trade-information-consolidated"), header_only))
  html <- withr::local_tempfile(lines = "<html><body><p>no table</p></body></html>")
  expect_null(settlement_prices_read(template_retrieve("b3-futures-settlement-prices"), html))
})
