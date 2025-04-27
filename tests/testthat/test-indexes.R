skip_on_cran()
skip_if_offline()

test_that("it should get index composition", {
  m <- tryCatch(download_marketdata("b3-indexes-composition"), error = function(e) {
    template_meta_load("b3-indexes-composition")
  })
  read_marketdata(m)

  x <- indexes_composition_get()
  expect_true(is(x, "arrow_dplyr_query") || is(x, "ArrowObject"))
  x <- x |> collect()
  expect_true(length(x) > 0)
})

test_that("it should get available indexes", {
  x <- indexes_get()
  expect_true(length(x) > 0)
})

test_that("it should get index weights for current portfolio", {
  suppressMessages(fetch_marketdata("b3-indexes-current-portfolio", index = "IBOV"))

  x <- indexes_current_portfolio_get()
  expect_true(is(x, "arrow_dplyr_query") || is(x, "ArrowObject"))
  
  x <- x |> filter(index == "IBOV") |> collect()
  expect_equal(as.integer(round(sum(x$weight), 0)), 1L)
  expect_true(nrow(x) > 0)
})

test_that("it should get index weights for theoretical portfolio", {
  suppressMessages(fetch_marketdata("b3-indexes-theoretical-portfolio", index = "IBOV"))

  x <- indexes_theoretical_portfolio_get()
  expect_true(is(x, "arrow_dplyr_query") || is(x, "ArrowObject"))
  
  x <- x |> filter(index == "IBOV") |> collect()
  expect_equal(as.integer(round(sum(x$weight), 0)), 1L)
  expect_true(nrow(x) > 0)
})

# test_that("it should get indexreport", {
#   date <- preceding(Sys.Date() - 1, "Brazil/ANBIMA")
#   x <- suppressWarnings(indexreport_get(date, do_cache = FALSE))
#   expect_s3_class(x, "data.frame")
#   expect_true(ncol(x) == 8)
#   expect_true(nrow(x) > 0)
#   date1 <- preceding(Sys.Date() - 5, "Brazil/ANBIMA")
#   x <- suppressWarnings(indexreport_mget(date1, date, do_cache = FALSE))
#   expect_s3_class(x, "data.frame")
#   expect_true(ncol(x) == 8)
#   expect_true(nrow(x) > 0)
# })

test_that("it should get index historical data", {
  suppressMessages(fetch_marketdata("b3-indexes-historical-data", index = "IBOV", year = 2022))
  x <- indexes_historical_data_get()
  expect_true(is(x, "arrow_dplyr_query") || is(x, "ArrowObject"))
  x <- x |> collect()
  expect_s3_class(x, "data.frame")
  expect_true(ncol(x) == 3)
  expect_true(nrow(x) > 0)
  expect_equal(format(x$refdate[1], "%Y"), "2022")
})
