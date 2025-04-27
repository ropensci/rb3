# Helper functions to reduce repetitive testing code
test_field_creation <- function(name, description = NULL, expected_attrs = list()) {
  # Create field with or without description
  if (is.null(description)) {
    f <- field(name)
  } else {
    f <- field(name, description)
  }
  
  # Basic field class and name checks
  expect_s3_class(f, "field")
  expect_equal(as.character(f), name)
  
  # Check expected attributes
  for (attr_name in names(expected_attrs)) {
    expect_equal(attr(f, attr_name), expected_attrs[[attr_name]])
  }
  
  return(f)
}

# Single field creation tests
test_that("it should create a field with full specifications", {
  f <- field("field_name", "field_description")
  expect_s3_class(f, "field")
  expect_equal(as.character(f), "field_name")
  expect_equal(attr(f, "description"), "field_description")
  expect_equal(attr(f, "width"), 0)
  expect_equal(attr(f, "type"), type("character"))
  expect_equal(attr(f, "collector"), readr::col_character())
  expect_equal(class(attr(f, "arrow")), class(arrow::string()))
})

test_that("it should create a field with default values", {
  f <- test_field_creation("field_name", 
                          expected_attrs = list(
                            description = "",
                            width = 0,
                            type = type("character")
                          ))
  
  # Additional checks for default values
  expect_equal(attr(f, "collector"), readr::col_character())
  expect_equal(class(attr(f, "arrow")), class(arrow::string()))
})

test_that("it should create a field with invalid description", {
  expect_warning(field("field_name", 0))
  f <- suppressWarnings(field("field_name", 0))
  expect_equal(attr(f, "description"), "")
})

test_that("it should create a field with custom width and type", {
  f <- field("field_name", "description", width(10), type("numeric", dec=2))
  expect_equal(attr(f, "width"), 10)
  expect_equal(attr(f, "type"), type("numeric", dec=2))
  expect_equal(attr(f, "type")$dec, 2)
})

# Multiple fields (fields collection) tests
test_that("it should create fields collection", {
  f1 <- field("f1")
  f2 <- field("f2")
  fs <- fields(f1, f2)
  expect_s3_class(fs, "fields")
  expect_equal(fields_names(fs), c("f1", "f2"))
  expect_equal(fields_widths(fs), c(0, 0))
  expect_equal(fields_description(fs), c("", ""))
  expect_equal(fields_types(fs), c("character", "character"))
  # expect_equal(
  #   fields_handlers(fs),
  #   list(f1 = pass_thru_handler(), f2 = pass_thru_handler())
  # )
  df <- data.frame(
    `Field name` = c("f1", "f2"),
    `Description` = "",
    `Width` = 0,
    `Type` = "character",
    check.names = FALSE
  )
  expect_equal(as.data.frame(fs), df)
})

test_that("it should extract field attributes correctly", {
  f1 <- field("f1", "First field", width(5), type("numeric", dec=2))
  f2 <- field("f2", "Second field", width(10), type("date"))
  fs <- fields(f1, f2)
  
  # Test attribute extraction
  expect_equal(fields_names(fs), c("f1", "f2"))
  expect_equal(fields_widths(fs), c(5, 10))
  expect_equal(fields_description(fs), c("First field", "Second field"))
  expect_equal(fields_types(fs), c("numeric", "date"))
  
  # Test arrow types
  arrow_types <- fields_arrow_types(fs)
  expect_equal(names(arrow_types), c("f1", "f2"))
  expect_equal(class(arrow_types$f1), c("Float64", "FixedWidthType", "DataType", "ArrowObject", "R6"))
  expect_equal(class(arrow_types$f2), c("Date32", "DateType", "FixedWidthType", "DataType", "ArrowObject", "R6"))
})

test_that("new_field creates field from specifications", {
  spec <- list(
    name = "test_field",
    description = "A test field",
    width = 15,
    type = "numeric(dec=2)"
  )
  
  f <- new_field(spec)
  expect_s3_class(f, "field")
  expect_equal(as.character(f), "test_field")
  expect_equal(attr(f, "description"), "A test field")
  expect_equal(attr(f, "width"), 15)
  expect_equal(attr(f, "type")$dec, 2)
})
