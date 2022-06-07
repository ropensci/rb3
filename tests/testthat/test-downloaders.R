
if (!covr::in_covr()) {
  skip_on_cran()
}

test_that("it should download a file with a simple downloader", {
  tpl <- .retrieve_template(NULL, "CDIIDI")
  dest <- tempfile()
  expect_true(tpl$download_marketdata(dest))
  expect_true(file.exists(dest))
})

test_that("it should download a file with a datetime downloader", {
  tpl <- .retrieve_template(NULL, "COTAHIST_YEARLY")
  dest <- tempfile()
  expect_false(tpl$download_marketdata(dest))
  expect_false(file.exists(dest))
  skip_on_os("linux")
  expect_true(tpl$download_marketdata(dest, refdate = Sys.Date()))
  expect_true(file.exists(dest))
  info <- file.info(dest)
  expect_true(info$size > 1000000)
})

test_that("it should fail to datetime_download", {
  tpl <- .retrieve_template(NULL, "OpcoesAcoesEmAberto")
  f <- datetime_download(tpl, tempfile())
  expect_false(f)
})

test_that("it should fail to settlement_prices_download", {
  tpl <- .retrieve_template(NULL, "AjustesDiarios")
  f <- settlement_prices_download(tpl, tempfile())
  expect_false(f)
})

test_that("it should stock_indexes_composition_download", {
  tpl <- .retrieve_template(NULL, "GetStockIndex")
  f <- stock_indexes_composition_download(tpl, tempfile())
  expect_true(f)
})

test_that("it should fail to curve_download", {
  tpl <- .retrieve_template(NULL, "TaxasReferenciais")
  f <- curve_download(tpl, tempfile())
  expect_false(f)
})

test_that("it should defaults to PRE in curve_download", {
  tpl <- .retrieve_template(NULL, "TaxasReferenciais")
  f <- curve_download(tpl, tempfile(), refdate = as.Date("2022-05-10"))
  expect_true(f)
})

test_that("it should base64_datetime_download", {
  tpl <- .retrieve_template(NULL, "NegociosBalcao")
  refdate <- preceding(Sys.Date() - 1, "Brazil/B3")
  f <- base64_datetime_download(tpl, tempfile(), refdate = refdate)
  expect_true(f)
})

test_that("it should fail base64_datetime_download", {
  tpl <- .retrieve_template(NULL, "NegociosBalcao")
  refdate <- as.Date("2022-06-05")
  f <- base64_datetime_download(tpl, tempfile(), refdate = refdate)
  expect_false(f)
})

test_that("it should company_listed_supplement_download", {
  tpl <- .retrieve_template(NULL, "GetListedSupplementCompany")
  f <- company_listed_supplement_download(tpl, tempfile(),
    company_name = "ABEV"
  )
  expect_true(f)
})

test_that("it should company_details_download", {
  tpl <- .retrieve_template(NULL, "GetDetailsCompany")
  f <- company_details_download(tpl, tempfile(),
    code_cvm = "23264"
  )
  expect_true(f)
})

test_that("it should company_cash_dividends_download ", {
  tpl <- .retrieve_template(NULL, "GetListedCashDividends")
  f <- company_cash_dividends_download(tpl, tempfile(),
    trading_name = "AMBEVSA"
  )
  expect_true(f)
})