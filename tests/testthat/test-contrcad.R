
test_that("it should load CONTRCAD with the correct field types", {
  f <- system.file("extdata/CONTRCAD.TXT", package = "rb3")
  suppressWarnings(
    df <- read_marketdata(f, template = "CONTRCAD")
  )
  expect_s3_class(df$tipo_opcao, "factor")
})