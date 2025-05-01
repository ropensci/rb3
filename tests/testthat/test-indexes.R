skip_on_cran()
skip_if_offline()

test_that("it should get index composition", {
  suppressMessages(fetch_marketdata("b3-indexes-composition"))
  m <- template_meta_load("b3-indexes-composition")
  expect_true(m$is_valid)

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
  suppressMessages(fetch_marketdata("b3-indexes-current-portfolio", index = "SMLL"))
  m <- template_meta_load("b3-indexes-current-portfolio", index = "SMLL")
  expect_true(m$is_valid)

  x <- indexes_current_portfolio_get()
  expect_true(is(x, "arrow_dplyr_query") || is(x, "ArrowObject"))
  
  x <- x |> filter(index == "SMLL") |> collect()
  expect_equal(as.integer(round(sum(x$weight), 0)), 1L)
  expect_true(nrow(x) > 0)
})

test_that("it should get index weights for theoretical portfolio", {
  suppressMessages(fetch_marketdata("b3-indexes-theoretical-portfolio", index = "SMLL"))
  m <- template_meta_load("b3-indexes-theoretical-portfolio", index = "SMLL")
  expect_true(m$is_valid)

  x <- indexes_theoretical_portfolio_get()
  expect_true(is(x, "arrow_dplyr_query") || is(x, "ArrowObject"))
  
  x <- x |> filter(index == "SMLL") |> collect()
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
  suppressMessages(fetch_marketdata("b3-indexes-historical-data", index = "SMLL", year = 2022))
  m <- template_meta_load("b3-indexes-historical-data", index = "SMLL", year = 2022)
  expect_true(m$is_valid)

  x <- indexes_historical_data_get()
  expect_true(is(x, "arrow_dplyr_query") || is(x, "ArrowObject"))
  x <- x |> collect()
  expect_s3_class(x, "data.frame")
  expect_true(ncol(x) == 3)
  expect_true(nrow(x) > 0)
  expect_equal(format(x$refdate[1], "%Y"), "2022")
})
