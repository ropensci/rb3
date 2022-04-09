context("CONTRCAD")

test_that("it should load CONTRCAD with the correct field types", {
  f <- system.file("extdata/CONTRCAD.TXT", package = "rb3")
  suppressWarnings(
    df <- read_marketdata(f)
  )
  expect_is(df$tipo_opcao, "factor")
})