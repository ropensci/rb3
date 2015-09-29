context('CONTRCAD')

test_that('it should load CONTRCAD with the correct field types', {
	df <- read_marketdata('../../inst/extdata/CONTRCAD.TXT')
	expect_is(df$`Indicador de Tipo de Opção`, 'factor')
})