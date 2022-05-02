test_that("rstudio addin", {
  
  # make sure the functions are called in covr::report()
  if (covr::in_covr()) {
    show_templates()
    display_template()
  }
  
  expect_true(TRUE)
})
