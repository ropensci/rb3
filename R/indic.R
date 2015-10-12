
Indic <- MarketDataFWF$proto(expr={
	filename <- 'Indic.txt'

	parser <- transmute::transmuter(
		transmute::match_regex('^\\+\\d+$', as.numeric, priority=1),
		NUMERIC.TRANSMUTER
	)

	fields <- fields(
		fwf_field('Identificação da transação', width=6, handler=to_numeric()),
		fwf_field('Complemento da transação', width=3, handler=to_numeric()),
		fwf_field('Tipo de registro', width=2, handler=to_numeric()),
		fwf_field('Data de geração do arquivo', width=8, handler=to_date(format='%Y%m%d')),
		fwf_field('Grupo do indicador', width=2,
			handler=to_factor(
				levels=c('IA', 'DE', 'RT', 'BV', 'ME', 'ID'),
				labels=c('Indicadores agropecuários', 'Títulos da dívida externa',
					'Indicadores gerais', 'Ibovespa', 'Moeda estrangeira',
					'Índice IDI'
				))),
		fwf_field('Código do indicador', width=25),
		fwf_field('Valor do indicador na data', width=25, handler=to_numeric(dec='Número de decimais do valor')),
		fwf_field('Número de decimais do valor', width=2, handler=to_numeric()),
		fwf_field('Filler', width=36)
	)
})

Indica <- Indic$proto(filename='Indica.txt')

MarketData$register(Indic)
MarketData$register(Indica)

# TODO: implement summary for templates
