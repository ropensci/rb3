test_that("it should get suplement data for a given company", {
  company_supl <- .company_supplement_get("PDGR3")
  keys <- names(company_supl)
  expect_true(all.equal(
    keys, c("Info", "CashDividends", "StockDividends", "Subscriptions")
  ))
})

test_that("it should get listed suplement company info", {
  company_supl <- .company_supplement_get("PDGR")
  company_info <- .company_suplement_info_get("PDGR", company_supl)
  cols <- ncol(company_info)
  expect_true(cols == 16)

  company_supl <- .company_supplement_get("PETR")
  company_info <- .company_suplement_info_get("PETR", company_supl)
  expect_true(nrow(company_info$codes[[1]]) > 1)
})

test_that("it should get listed suplement stock dividends", {
  company_supl <- .company_supplement_get("PDGR")
  company_stock_div <- .company_suplement_stock_dividends_get(
    "PDGR",
    company_supl
  )
  cols <- ncol(company_stock_div)
  expect_true(cols == 7)

  company_supl <- .company_supplement_get("PETR")
  company_stock_div <- .company_suplement_stock_dividends_get(
    "PETR",
    company_supl
  )
  symbols <- unique(company_stock_div$symbol)
  expect_true(all.equal(c("PETR3", "PETR4"), symbols))
})

test_that("it should get listed suplement cash dividends", {
  company_supl <- .company_supplement_get("PDGR")
  company_cash_div <- .company_suplement_cash_dividends_get(
    "PDGR",
    company_supl
  )
  cols <- ncol(company_cash_div)
  expect_true(cols == 8)

  company_supl <- .company_supplement_get("PETR")
  company_cash_div <- .company_suplement_cash_dividends_get(
    "PETR",
    company_supl
  )
  symbols <- unique(company_cash_div$symbol)
  expect_true(all.equal(c("PETR3", "PETR4"), symbols))
})

test_that("it should get listed suplement subscriptions", {
  company_supl <- .company_supplement_get("PDGR")
  data <- .company_suplement_subscriptions_get("PDGR", company_supl)
  cols <- ncol(data)
  expect_true(cols == 10)
})

test_that("it should get company info for multiple companies", {
  company_info <- company_info_get(c("PDGR", "PETR"))

  expect_true(all.equal(company_info$asset_name, c("PDGR", "PETR")))
  expect_true(nrow(company_info) == 2)
  expect_true(ncol(company_info) == 16)
})

test_that("it should get stock dividends for multiple companies", {
  company_info <- company_stock_dividends_get(c("PDGR", "PETR"))

  expect_true(all.equal(company_info$asset_name |> unique(), c("PDGR", "PETR")))
  expect_true(ncol(company_info) == 7)
})

test_that("it should get cash dividends for multiple companies", {
  company_info <- company_cash_dividends_get(c("PDGR", "PETR"))

  expect_true(all.equal(company_info$asset_name |> unique(), c("PDGR", "PETR")))
  expect_true(ncol(company_info) == 8)
})

test_that("it should get subscriptions for multiple companies", {
  company_info <- company_subscriptions_get(c("PDGR", "INEP"))

  expect_true(all.equal(company_info$asset_name |> unique(), c("INEP", "PDGR")))
  expect_true(ncol(company_info) == 10)
})
