
Indic <- MarketDataFWF$proto(expr={
	name <- 'indic'
	filename <- 'Indic.txt'
	
	parser <- textparser::textparser(
		parse_indic_numeric=textparser::parser('^\\+\\d+$', function(text, match) {
			as.numeric(text)
		}, textparser::priority(1))
	)
	
	fields <- fields(
		fwf_field('Identificação da transação', width=6, handler=to_numeric()),
		fwf_field('Complemento da transação', width=3, handler=to_numeric()),
		fwf_field('Tipo de registro', width=2, handler=to_numeric()),
		fwf_field('Data de geração do arquivo', width=8, handler=to_date(format='%Y%m%d')),
		fwf_field('Grupo do indicador', width=2, handler=to_factor(levels=c('IA', 'DE', 'RT', 'BV', 'ME', 'ID'), labels=c('Indicadores agropecuários', 'Títulos da dívida externa',
					'Indicadores gerais', 'Ibovespa', 'Moeda estrangeira',
					'Índice IDI'
				))),
		fwf_field('Código do indicador', width=25),
		fwf_field('Valor do indicador na data', width=25, handler=to_numeric(dec='Número de decimais do valor')),
		fwf_field('Número de decimais do valor', width=2, handler=to_numeric()),
		fwf_field('Filler', width=36)
	)
	
	colnames <- fields_names(fields)
	widths <- fields_widths(fields)
	handlers <- fields_handlers(fields)
})

MarketData$register(Indic)

# TODO: implement summary for templates