test_that("cdi", {
  skip_on_cran()
  skip_if_offline()

  # first call
  cdi_1 <- cdi_get()

  # seconde call (cached ver)
  cdi_2 <- cdi_get()

  expect_true(nrow(cdi_1) > 0)
  expect_equal(cdi_1, cdi_2)

  idi <- idi_get()
  expect_true(nrow(idi) > 0)
})
