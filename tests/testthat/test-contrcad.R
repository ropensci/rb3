context('CONTRCAD')

test_that('it should load CONTRCAD with the correct field types', {
  df <- read_marketdata('../../inst/extdata/CONTRCAD.TXT')
  expect_is(df$tipo_opcao, 'factor')
})
