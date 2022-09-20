
test_that("it should load BD_Arbit with the correct field types", {
  f_txt <- system.file("extdata/BD_Arbit.txt", package = "rb3")
  f_txt <- copy_file_to_temp(f_txt)

  df <- read_marketdata(f_txt, template = "BD_Arbit")
  expect_s3_class(df$data_geracao_arquivo, "Date")
  expect_s3_class(df$tipo_serie, "factor")
  expect_s3_class(df$hora_criacao_registro, "POSIXct")
  expect_s3_class(df$data_vencimento, "Date")
  expect_s3_class(df$hora_ult_negocio, "POSIXct")
  expect_s3_class(df$data_ult_negocio, "Date")
  expect_s3_class(df$data_inicio_entrega, "Date")
  expect_s3_class(df$data_limite_negociacao, "Date")
  expect_s3_class(df$data_liquidacao_financeira, "Date")
})
