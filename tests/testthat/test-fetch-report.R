# No network: download_marketdata() and read_marketdata() are mocked.
# size 1 = ok, 2 = no data, 3 = download failed

test_that("fetch_marketdata reports and returns the final state of each file", {
  local_mocked_bindings(
    download_marketdata = function(meta) {
      meta$is_downloaded <- meta$download_args$size != 3
      meta
    },
    read_marketdata = function(meta) {
      if (meta$is_downloaded) {
        meta$is_processed <- TRUE
        meta$is_valid <- meta$download_args$size == 1
      }
      meta
    }
  )
  metas <- create_meta_list("template-test-small-file", size = 1:3)
  withr::defer(purrr::walk(metas, meta_clean))

  msgs <- character(0)
  res <- withCallingHandlers(
    fetch_marketdata("template-test-small-file", size = 1:3),
    message = function(m) {
      msgs <<- c(msgs, conditionMessage(m))
      invokeRestart("muffleMessage")
    }
  )
  expect_s3_class(res, "tbl_df")
  expect_equal(res$status, c("ok", "invalid", "download_failed"))
  expect_equal(purrr::map_int(res$download_args, "size"), 1:3)
  out <- paste(msgs, collapse = "\n")
  expect_match(out, "1 of 3 files with data")
  expect_match(out, "no data: size = 2")
  expect_match(out, "download failed: size = 3")
})

test_that("fetch_report covers files never read and arguments with braces", {
  metas <- list(
    list(template = "t", download_args = list(x = "{a}"), is_downloaded = TRUE, is_processed = FALSE, is_valid = FALSE),
    list(template = "t", download_args = list(x = "b"), is_downloaded = TRUE, is_processed = TRUE, is_valid = TRUE)
  )
  msgs <- capture_messages(res <- fetch_report(metas))
  expect_match(paste(msgs, collapse = "\n"), "not read: x = \\{a\\}")
  expect_equal(res$status, c("not_read", "ok"))
})
