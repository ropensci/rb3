test_that("it should create a template", {
  tpl <- new_template("id")
  expect_equal(tpl$id, "id")
})