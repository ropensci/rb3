test_that("it should create a registry class", {
  # Create a new registry
  registry <- create_registry()
  reg <- registry$get_instance()
  expect_s3_class(reg, "registry")
  expect_true(length(reg$data) == 0)
  expect_equal(registry_keys(reg), character(0))
})

test_that("it should add and retrieve elements", {
  # Create a new registry
  registry <- create_registry()
  reg <- registry$get_instance()
  # Add elements
  reg[["a"]] <- 1
  reg[["b"]] <- 2
  expect_equal(registry_keys(reg), c("a", "b"))
  expect_equal(names(reg), c("a", "b"))
  expect_equal(reg[["a"]], 1)
  expect_equal(reg[["b"]], 2)
  expect_equal(registry_get(reg, "a"), 1)
  expect_equal(registry_get(reg, "b"), 2)
})