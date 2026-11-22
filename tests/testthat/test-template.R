test_that("it should create a template", {
  tpl <- new_template("id")
  expect_equal(tpl$id, "id")
})

test_that("list_templates lists every registered template", {
  res <- list_templates()
  expect_named(res, c("Template", "Description"))
  expect_true(all(c("b3-cotahist-daily", "b3-reference-rates") %in% res$Template))
  expect_equal(nrow(res), length(template_registry$get_instance()))
})

test_that("print.template shows id, arguments and fields", {
  out <- cli::cli_fmt(res <- print(template_retrieve("b3-reference-rates")))
  expect_null(res)
  expect_match(out, "b3-reference-rates", all = FALSE)
  expect_match(out, "refdate", all = FALSE)
  expect_match(out, "Fields", all = FALSE)
})
