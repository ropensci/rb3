skip_on_cran()
skip_if_offline()

if (Sys.info()["sysname"] == "Linux") {
  httr::set_config(httr::config(ssl_verifypeer = FALSE))
}

test_that("it should download a file with a datetime downloader", {
  tpl <- .retrieve_template(NULL, "COTAHIST_DAILY")
  dest <- tempfile()
  expect_false(tpl$download_marketdata(dest))
  expect_false(file.exists(dest))
  skip_on_os("linux")
  date <- getdate("last bizday", Sys.Date(), "Brazil/ANBIMA")
  x <- tpl$download_marketdata(dest, refdate = date)
  expect_true(x)
  expect_true(file.exists(dest))
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
  dest <- tempfile()
  x <- settlement_prices_download(tpl, dest, refdate = as.Date("2022-12-01"))
  expect_true(x)
  expect_true(file.exists(dest))
})

test_that("it should stock_indexes_composition_download", {
  tpl <- .retrieve_template(NULL, "GetStockIndex")
  vcr::use_cassette("GetStockIndex", {
    f <- stock_indexes_composition_download(tpl, tempfile())
  })
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
  refdate <- as.Date("2022-12-07")
  vcr::use_cassette("NegociosBalcao", {
    f <- base64_datetime_download(tpl, tempfile(), refdate = refdate)
  })
  expect_true(f)
})

test_that("it should fail base64_datetime_download", {
  tpl <- .retrieve_template(NULL, "NegociosBalcao")
  refdate <- as.Date("2022-06-05")
  f <- base64_datetime_download(tpl, tempfile(), refdate = refdate)
  expect_false(f)
})

test_that("it should download an empty file", {
  tpl <- .retrieve_template(NULL, "GetListedSupplementCompany")
  vcr::use_cassette("GetListedSupplementCompanyEmpty", {
    fname <- tempfile()
    f <- company_listed_supplement_download(tpl, fname, company_name = "WWWW")
  })
  expect_true(file.size(fname) <= 2)
  expect_true(f)
})

test_that("it should company_listed_supplement_download", {
  tpl <- .retrieve_template(NULL, "GetListedSupplementCompany")
  vcr::use_cassette("GetListedSupplementCompany", {
    fname <- tempfile()
    f <- company_listed_supplement_download(tpl, fname, company_name = "ABEV")
  })
  expect_true(file.size(fname) > 2)
  expect_true(f)
})

test_that("it should company_details_download", {
  tpl <- .retrieve_template(NULL, "GetDetailsCompany")
  vcr::use_cassette("GetDetailsCompany", {
    fname <- tempfile()
    f <- company_details_download(tpl, fname, code_cvm = "24910")
  })
  expect_true(file.size(fname) > 2)
  expect_true(f)
})

test_that("it should company_cash_dividends_download ", {
  tpl <- .retrieve_template(NULL, "GetListedCashDividends")
  vcr::use_cassette("GetListedCashDividends", {
    fname <- tempfile()
    f <- company_cash_dividends_download(tpl, fname,
      trading_name = "AMBEVSA"
    )
  })
  expect_true(file.size(fname) > 2)
  expect_true(f)
})

test_that("it should stock_indexes_statistics_download ", {
  tpl <- .retrieve_template(NULL, "GetPortfolioDay_IndexStatistics")
  vcr::use_cassette("GetPortfolioDay_IndexStatistics", {
    fname <- tempfile()
    f <- stock_indexes_statistics_download(tpl, fname,
      index_name = "IBOV", year = 2022
    )
  })
  expect_true(file.size(fname) > 2)
  expect_true(f)
})

test_that("it should stock_indexes_current_portfolio_download ", {
  tpl <- .retrieve_template(NULL, "GetPortfolioDay")
  vcr::use_cassette("GetPortfolioDay", {
    fname <- tempfile()
    f <- stock_indexes_current_portfolio_download(tpl, fname,
      index_name = "IBOV"
    )
  })
  expect_true(file.size(fname) > 2)
  expect_true(f)
})

test_that("it should stock_indexes_theo_portfolio_download ", {
  tpl <- .retrieve_template(NULL, "GetTheoricalPortfolio")
  vcr::use_cassette("GetTheoricalPortfolio", {
    fname <- tempfile()
    f <- stock_indexes_theo_portfolio_download(tpl, fname,
      index_name = "IBOV"
    )
  })
  expect_true(file.size(fname) > 2)
  expect_true(f)
})

test_that("it should datetime_download FPR file", {
  tpl <- .retrieve_template(NULL, "FPR")
  refdate <- as.Date("2022-12-07")
  vcr::use_cassette("FPR", {
    f <- datetime_download(tpl, tempfile(), refdate = refdate)
  })
  expect_true(f)
})

test_that("it should datetime_download NegociosBTB file", {
  tpl <- .retrieve_template(NULL, "NegociosBTB")
  refdate <- bizdays::getdate("last bizday", Sys.Date(), "Brazil/B3")
  vcr::use_cassette("NegociosBTB",
    {
      f <- datetime_download(tpl, tempfile(), refdate = refdate)
    },
    record = "all"
  )
  expect_true(f)
})

test_that("it should datetime_download OpcoesAcoesEmAberto", {
  tpl <- .retrieve_template(NULL, "OpcoesAcoesEmAberto")
  refdate <- as.Date("2022-12-07")
  f <- datetime_download(tpl, tempfile(), refdate = refdate)
  expect_true(f)
})
