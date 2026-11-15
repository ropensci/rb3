test_that("is_html_file detects HTML pages but not XML or CSV", {
  f <- tempfile()
  writeLines(c("﻿  <!DOCTYPE html>", "<html><body>erro</body></html>"), f)
  expect_true(is_html_file(f))
  writeLines("<html lang='pt-BR'>", f)
  expect_true(is_html_file(f))
  writeLines('<?xml version="1.0" encoding="UTF-8"?><Document/>', f)
  expect_false(is_html_file(f))
  writeLines("Ticker symbol;ISIN code", f)
  expect_false(is_html_file(f))
})

test_that("an HTML page is a failed download when the template does not expect HTML", {
  tpl <- template_retrieve("b3-futures-settlement-prices")
  meta <- template_meta_create_or_load(tpl$id, refdate = as.Date("1999-12-31"))
  withr::defer(meta_clean(meta))
  f <- tempfile(fileext = ".csv")
  writeLines("<!doctype html><html><body>Manutencao</body></html>", f)
  expect_error(process_downloaded_file(f, tpl, meta), class = "error_download_fail")
  # as in download_marketdata(): the meta stays not downloaded, so the next fetch retries it
  meta <- tryCatch(process_downloaded_file(f, tpl, meta), error = function(e) handle_download_error(e, meta))
  expect_false(meta$is_downloaded)
  expect_length(meta$downloaded, 0)
})
