context('BD_Arbit')

test_that('it should load BD_Arbit with the correct field types', {
  df <- read_marketdata('../../inst/extdata/BD_Final.txt')
  expect_is(df$data_geracao_arquivo, 'Date')
  expect_is(df$tipo_serie, 'factor')
  expect_is(df$hora_criacao_registro, 'POSIXct')
  expect_is(df$data_vencimento, 'Date')
  expect_is(df$hora_ult_negocio, 'POSIXct')
  expect_is(df$data_ult_negocio, 'Date')
  expect_is(df$data_inicio_entrega, 'Date')
  expect_is(df$data_limite_negociacao, 'Date')
  expect_is(df$data_liquidacao_financeira, 'Date')
})
