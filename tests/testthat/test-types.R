# Helper functions to reduce repetitive test code
test_type_creation <- function(type_name, expected_attrs = list()) {
  t <- do.call(type, c(list(type_name), expected_attrs))
  expect_true(t == type_name)
  expect_equal(class(t), c("type", type_name))
  
  # Test that the attributes are set correctly
  for (attr_name in names(expected_attrs)) {
    expect_equal(attr(t, attr_name), expected_attrs[[attr_name]])
  }
  
  return(t)
}

test_type_parsing <- function(type_str, expected_name, expected_attrs = list()) {
  t <- type_parse(type_str)
  expect_true(t == expected_name)
  expect_equal(class(t), c("type", expected_name))
  
  # Test that the attributes are set correctly
  for (attr_name in names(expected_attrs)) {
    expect_equal(attr(t, attr_name), expected_attrs[[attr_name]])
  }
  
  return(t)
}

# Basic type creation tests
test_that("it should create basic types", {
  # Test all basic types with default attributes
  basic_types <- c("date", "time", "datetime", "numeric", "number", "integer", "character", "logical")
  
  for (type_name in basic_types) {
    test_type_creation(type_name)
  }
})

test_that("it should create types with custom attributes", {
  # Date with custom format
  test_type_creation("date", list(format = "%d/%m/%Y"))
  
  # Time with custom format
  test_type_creation("time", list(format = "%I:%M %p"))
  
  # Datetime with custom format
  test_type_creation("datetime", list(format = "%d/%m/%Y %H:%M"))
  
  # Numeric with custom decimal places and sign
  test_type_creation("numeric", list(dec = 2, sign = "+"))
})

# Type parsing tests
test_that("it should parse basic type strings", {
  # Test all basic types
  test_type_parsing("date", "date", list(format = "%Y-%m-%d"))
  test_type_parsing("time", "time", list(format = "%H:%M:%S"))
  test_type_parsing("datetime", "datetime", list(format = "%Y-%m-%d %H:%M:%S"))
  test_type_parsing("numeric", "numeric", list(dec = 0, sign = "+"))
  test_type_parsing("number", "number")
  test_type_parsing("integer", "integer")
  test_type_parsing("character", "character")
  test_type_parsing("logical", "logical")
})

test_that("it should parse type strings with parameters", {
  # Date with custom format
  test_type_parsing("date(format = '%d/%m/%Y')", "date", list(format = "%d/%m/%Y"))
  
  # Time with custom format
  test_type_parsing("time(format='%I:%M %p')", "time", list(format = "%I:%M %p"))
  
  # Datetime with custom format
  test_type_parsing("datetime(format='%d/%m/%Y %H:%M')", "datetime", list(format = "%d/%m/%Y %H:%M"))
  
  # Numeric with custom decimal places and sign
  test_type_parsing("numeric(dec = 2, sign = '+')", "numeric", list(dec = 2, sign = "+"))
})

test_that("it should handle type attribute access and modification", {
  t <- type("date")
  expect_equal(t$format, "%Y-%m-%d")
  
  # Modify attribute
  t$format <- "%d/%m/%Y"
  expect_equal(t$format, "%d/%m/%Y")
  
  # Numeric type attributes
  n <- type("numeric", dec = 2)
  expect_equal(n$dec, 2)
  expect_equal(n$sign, "+")
  
  # Change attribute
  n$dec <- 4
  expect_equal(n$dec, 4)
})

test_that("it should handle error conditions", {
  # Invalid type name
  expect_error(type("invalid_type"), "Invalid type name")
  
  # Invalid type string
  expect_error(type_parse("invalid_type"), "Invalid type string")
  
  # is_valid_type function
  expect_true(is_valid_type("date"))
  expect_false(is_valid_type("invalid_type"))
})