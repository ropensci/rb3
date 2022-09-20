test_that("it should create a field", {
  f <- field("field_name", "field_description")
  expect_s3_class(f, "field")
  expect_equal(as.character(f), "field_name")
  expect_equal(attr(f, "description"), "field_description")
  expect_equal(attr(f, "handler"), pass_thru_handler())
  expect_equal(attr(f, "width"), 0)
})

test_that("it should create a field with invalid description", {
  expect_warning(field("field_name", 0))
  f <- suppressWarnings(field("field_name", 0))
  expect_equal(attr(f, "description"), "")
})

test_that("it should create fields", {
  f1 <- field("f1")
  f2 <- field("f2")
  fs <- fields(f1, f2)
  expect_s3_class(fs, "fields")
  expect_equal(fields_names(fs), c("f1", "f2"))
  expect_equal(fields_widths(fs), c(0, 0))
  expect_equal(fields_description(fs), c("", ""))
  expect_equal(
    fields_handlers(fs),
    list(f1 = pass_thru_handler(), f2 = pass_thru_handler())
  )
  df <- data.frame(
    `Field name` = c("f1", "f2"),
    `Description` = "",
    `Width` = 0,
    `Type` = "character",
    check.names = FALSE
  )
  expect_equal(as.data.frame(fs), df)
})
