test_that("it should create a registry class", {
  # Create a new registry
  registry <- create_registry()
  reg <- registry$get_instance()
  expect_s3_class(reg, "registry")
  expect_true(length(reg) == 0)
  expect_equal(registry_keys(reg), character(0))
})

test_that("it should add and retrieve elements", {
  # Create a new registry
  registry <- create_registry()
  reg <- registry$get_instance()
  # Add elements
  reg <- registry_put(reg, "a", 1)
  reg <- registry_put(reg, "b", 2)
  expect_equal(registry_keys(reg), c("a", "b"))
  expect_equal(registry_get(reg, "a"), 1)
  expect_equal(registry_get(reg, "b"), 2)
  # retrieve the instance again
  expect_equal(registry_keys(reg), c("a", "b"))
  expect_equal(registry_get(reg, "a"), 1)
  expect_equal(registry_get(reg, "b"), 2)
})

test_that("it should add and retrieve elements with [[ operator", {
  # Create a new registry
  registry <- create_registry()
  reg <- registry$get_instance()
  # Add elements
  reg[["a"]] <- 1
  reg[["b"]] <- 2
  expect_equal(registry_keys(reg), c("a", "b"))
  expect_equal(names(reg), registry_keys(reg))
  expect_equal(reg[["a"]], 1)
  expect_equal(reg[["b"]], 2)
  expect_equal(registry_get(reg, "a"), reg[["a"]])
  expect_equal(registry_get(reg, "b"), reg[["b"]])
  # retrieve the instance again
  reg <- registry$get_instance()
  expect_equal(names(reg), c("a", "b"))
  expect_equal(reg[["a"]], 1)
  expect_equal(reg[["b"]], 2)
})

test_that("it should add and retrieve elements with $ operator", {
  # Create a new registry
  registry <- create_registry()
  reg <- registry$get_instance()
  # Add elements
  reg$a <- 1
  reg$b <- 2
  expect_equal(names(reg), c("a", "b"))
  expect_equal(reg$a, 1)
  expect_equal(reg$b, 2)
  # retrieve the instance again
  reg <- registry$get_instance()
  expect_equal(names(reg), c("a", "b"))
  expect_equal(reg$a, 1)
  expect_equal(reg$b, 2)
})