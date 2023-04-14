skip_on_cran()
skip_if_offline()

if (Sys.info()["sysname"] == "Linux") {
  httr::set_config(httr::config(ssl_verifypeer = FALSE))
}

test_that("it should get an error due to invalid symbol", {
  company_supl <- tryCatch(
    .company_supplement_get("WILX"),
    empty_file_error = function(e) NULL
  )
  expect_true(is.null(company_supl))
})

test_that("it should get supplementary data for a given company", {
  company_supl <- tryCatch(
    .company_supplement_get("PDGR3"),
    empty_file_error = function(e) NULL
  )
  skip_if(is.null(company_supl))
  keys <- names(company_supl)
  expect_true(all.equal(
    keys, c("Info", "CashDividends", "StockDividends", "Subscriptions")
  ))
})

test_that("it should get listed supplementary company info", {
  company_supl <- tryCatch(
    .company_supplement_get("PDGR"),
    empty_file_error = function(e) NULL
  )
  skip_if(is.null(company_supl))

  company_info <- tryCatch(
    .company_supplementary_info_get("PDGR", company_supl),
    empty_file_error = function(e) NULL
  )
  skip_if(is.null(company_info))
  
  cols <- ncol(company_info)
  expect_true(cols == 16)

  company_supl <- tryCatch(
    .company_supplement_get("PETR"),
    empty_file_error = function(e) NULL
  )
  skip_if(is.null(company_supl))
  
  company_info <- tryCatch(
    .company_supplementary_info_get("PETR", company_supl),
    empty_file_error = function(e) NULL
  )
  skip_if(is.null(company_info))
  expect_true(nrow(company_info$codes[[1]]) > 1)
})

test_that("it should get listed supplementary stock dividends", {
  company_supl <- tryCatch(
    .company_supplement_get("PDGR"),
    empty_file_error = function(e) NULL
  )
  skip_if(is.null(company_supl))
  
  company_stock_div <- tryCatch(
    .company_supplementary_stock_dividends_get("PDGR", company_supl),
    empty_file_error = function(e) NULL
  )
  skip_if(is.null(company_stock_div))
  
  cols <- ncol(company_stock_div)
  expect_true(cols == 7)

  company_supl <- tryCatch(
    .company_supplement_get("PETR"),
    empty_file_error = function(e) NULL
  )
  skip_if(is.null(company_supl))
  
  company_stock_div <- tryCatch(
    .company_supplementary_stock_dividends_get("PETR", company_supl),
    empty_file_error = function(e) NULL
  )
  skip_if(is.null(company_stock_div))

  symbols <- unique(company_stock_div$symbol)
  expect_true(all.equal(c("PETR3", "PETR4"), symbols))
})

test_that("it should get listed supplementary cash dividends", {
  company_supl <- tryCatch(
    .company_supplement_get("PDGR"),
    empty_file_error = function(e) NULL
  )
  skip_if(is.null(company_supl))
  
  company_cash_div <- tryCatch(
    .company_supplementary_cash_dividends_get("PDGR", company_supl),
    empty_file_error = function(e) NULL
  )
  skip_if(is.null(company_cash_div))
  
  cols <- ncol(company_cash_div)
  expect_true(cols == 8)

  company_supl <- tryCatch(
    .company_supplement_get("PETR"),
    empty_file_error = function(e) NULL
  )
  skip_if(is.null(company_supl))

  company_cash_div <- tryCatch(
    .company_supplementary_cash_dividends_get("PETR", company_supl),
    empty_file_error = function(e) NULL
  )
  skip_if(is.null(company_cash_div))
  
  symbols <- unique(company_cash_div$symbol)
  expect_true(all.equal(c("PETR3", "PETR4"), symbols))
})

test_that("it should get listed supplementary subscriptions", {
  company_supl <- tryCatch(
    .company_supplement_get("PDGR"),
    empty_file_error = function(e) NULL
  )
  skip_if(is.null(company_supl))
  
  data <- tryCatch(
    .company_supplementary_subscriptions_get("PDGR", company_supl),
    empty_file_error = function(e) NULL
  )
  skip_if(is.null(data))
  
  cols <- ncol(data)
  expect_true(cols == 10)
})

test_that("it should get company info for multiple companies", {
  company_info <- tryCatch(
    company_info_get(c("PDGR", "PETR")),
    empty_file_error = function(e) NULL
  )
  skip_if(is.null(company_info))
  
  expect_true(all.equal(company_info$asset_name, c("PDGR", "PETR")))
  expect_true(nrow(company_info) == 2)
  expect_true(ncol(company_info) == 16)
})

test_that("it should get stock dividends for multiple companies", {
  company_info <- tryCatch(
    company_stock_dividends_get(c("PDGR", "PETR")),
    empty_file_error = function(e) NULL
  )
  skip_if(is.null(company_info))
  
  expect_true(all.equal(company_info$asset_name |> unique(), c("PDGR", "PETR")))
  expect_true(ncol(company_info) == 7)
})

test_that("it should get cash dividends for multiple companies", {
  company_info <- tryCatch(
    company_cash_dividends_get(c("PDGR", "PETR")),
    empty_file_error = function(e) NULL
  )
  skip_if(is.null(company_info))
  
  expect_true(all.equal(company_info$asset_name |> unique(), c("PDGR", "PETR")))
  expect_true(ncol(company_info) == 8)
})

test_that("it should get subscriptions for multiple companies", {
  company_info <- tryCatch(
    company_subscriptions_get(c("PDGR", "INEP")),
    empty_file_error = function(e) NULL
  )
  skip_if(is.null(company_info))
  
  expect_true(all.equal(company_info$asset_name |> unique(), c("INEP", "PDGR")))
  expect_true(ncol(company_info) == 10)
})
