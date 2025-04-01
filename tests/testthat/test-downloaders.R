skip_on_cran()
skip_if_offline()

if (Sys.info()["sysname"] == "Linux") {
  httr::set_config(httr::config(ssl_verifypeer = FALSE))
}

test_that("it should download a file directly by its URL", {
  tpl <- template_retrieve("template-test")
  dest <- tempfile()
  x <- download_marketdata_wrapper(tpl, dest)
  expect_true(x)
  expect_true(file.exists(dest))
})

test_that("it should download a file with a datetime downloader", {
  tpl <- template_retrieve("b3-cotahist-daily")
  dest <- tempfile()
  expect_false(download_marketdata_wrapper(tpl, dest))
  expect_false(file.exists(dest))
  date <- getdate("last bizday", Sys.Date(), "Brazil/ANBIMA")
  x <- download_marketdata_wrapper(tpl, dest, refdate = date)
  expect_true(x)
  expect_true(file.exists(dest))
})

test_that("it should fail to settlement_prices_download", {
  tpl <- template_retrieve("b3-reference-rates")
  f <- download_marketdata_wrapper(tpl, tempfile())
  expect_false(f)
  dest <- tempfile()
  x <- download_marketdata_wrapper(tpl, dest, refdate = as.Date("2022-12-01"))
  expect_false(x)
  expect_false(file.exists(dest))
})

test_that("it should fail to curve_download", {
  tpl <- template_retrieve("b3-reference-rates")
  f <- download_marketdata_wrapper(tpl, tempfile())
  expect_false(f)
})

test_that("it should defaults to PRE in curve_download", {
  tpl <- template_retrieve("b3-reference-rates")
  f <- download_marketdata_wrapper(tpl, tempfile(), refdate = as.Date("2022-05-10"), curve_name = "PRE")
  expect_true(f)
})

# test_that("it should fail to datetime_download", {
#   tpl <- template_retrieve("OpcoesAcoesEmAberto")
#   f <- datetime_download(tpl, tempfile())
#   expect_false(f)
# })

# test_that("it should stock_indexes_composition_download", {
#   tpl <- template_retrieve("GetStockIndex")
#   vcr::use_cassette("GetStockIndex", {
#     f <- stock_indexes_composition_download(tpl, tempfile())
#   })
#   expect_true(f)
# })

# test_that("it should base64_datetime_download", {
#   tpl <- template_retrieve("NegociosBalcao")
#   refdate <- as.Date("2022-12-07")
#   vcr::use_cassette("NegociosBalcao", {
#     f <- base64_datetime_download(tpl, tempfile(), refdate = refdate)
#   })
#   expect_true(f)
# })

# test_that("it should fail base64_datetime_download", {
#   skip_on_os("mac")
#   tpl <- template_retrieve("NegociosBalcao")
#   refdate <- as.Date("2022-06-05")
#   f <- base64_datetime_download(tpl, tempfile(), refdate = refdate)
#   expect_false(f)
# })

# test_that("it should download an empty file", {
#   tpl <- template_retrieve("GetListedSupplementCompany")
#   vcr::use_cassette("GetListedSupplementCompanyEmpty", {
#     fname <- tempfile()
#     f <- company_listed_supplement_download(tpl, fname, company_name = "WWWW")
#   })
#   expect_true(file.size(fname) <= 2)
#   expect_true(f)
# })

# test_that("it should company_listed_supplement_download", {
#   tpl <- template_retrieve("GetListedSupplementCompany")
#   vcr::use_cassette("GetListedSupplementCompany", {
#     fname <- tempfile()
#     f <- company_listed_supplement_download(tpl, fname, company_name = "ABEV")
#   })
#   expect_true(file.size(fname) > 2)
#   expect_true(f)
# })

# test_that("it should company_details_download", {
#   tpl <- template_retrieve("GetDetailsCompany")
#   vcr::use_cassette("GetDetailsCompany", {
#     fname <- tempfile()
#     f <- company_details_download(tpl, fname, code_cvm = "24910")
#   })
#   expect_true(file.size(fname) > 2)
#   expect_true(f)
# })

# test_that("it should company_cash_dividends_download ", {
#   tpl <- template_retrieve("GetListedCashDividends")
#   vcr::use_cassette("GetListedCashDividends", {
#     fname <- tempfile()
#     f <- company_cash_dividends_download(tpl, fname,
#       trading_name = "AMBEVSA"
#     )
#   })
#   expect_true(file.size(fname) > 2)
#   expect_true(f)
# })

# test_that("it should stock_indexes_statistics_download ", {
#   tpl <- template_retrieve("GetPortfolioDay_IndexStatistics")
#   vcr::use_cassette("GetPortfolioDay_IndexStatistics", {
#     fname <- tempfile()
#     f <- stock_indexes_statistics_download(tpl, fname,
#       index_name = "IBOV", year = 2022
#     )
#   })
#   expect_true(file.size(fname) > 2)
#   expect_true(f)
# })

# test_that("it should stock_indexes_current_portfolio_download ", {
#   tpl <- template_retrieve("GetPortfolioDay")
#   vcr::use_cassette("GetPortfolioDay", {
#     fname <- tempfile()
#     f <- stock_indexes_current_portfolio_download(tpl, fname,
#       index_name = "IBOV"
#     )
#   })
#   expect_true(file.size(fname) > 2)
#   expect_true(f)
# })

# test_that("it should stock_indexes_theo_portfolio_download ", {
#   tpl <- template_retrieve("GetTheoricalPortfolio")
#   vcr::use_cassette("GetTheoricalPortfolio", {
#     fname <- tempfile()
#     f <- stock_indexes_theo_portfolio_download(tpl, fname,
#       index_name = "IBOV"
#     )
#   })
#   expect_true(file.size(fname) > 2)
#   expect_true(f)
# })

# test_that("it should datetime_download FPR file", {
#   tpl <- template_retrieve("FPR")
#   refdate <- as.Date("2022-12-07")
#   vcr::use_cassette("FPR", {
#     f <- datetime_download(tpl, tempfile(), refdate = refdate)
#   })
#   expect_true(f)
# })

# # test_that("it should datetime_download NegociosBTB file", {
# #   tpl <- template_retrieve("NegociosBTB")
# #   refdate <- bizdays::getdate("last bizday", Sys.Date(), "Brazil/B3")
# #   vcr::use_cassette("NegociosBTB",
# #     {
# #       f <- datetime_download(tpl, tempfile(), refdate = refdate)
# #     },
# #     record = "all"
# #   )
# #   expect_true(f)
# # })

# test_that("it should datetime_download OpcoesAcoesEmAberto", {
#   tpl <- template_retrieve("OpcoesAcoesEmAberto")
#   refdate <- as.Date("2022-12-07")
#   f <- datetime_download(tpl, tempfile(), refdate = refdate)
#   expect_true(f)
# })
