
PUWEB <- MarketDataMultiPartCSV$proto(expr={
	filename <- 'PUWEB.TXT'
	separator <- ';'

	parts <- list(
		'Cabeçalho'=list(
			pattern='^01',
			fields=fields(
				field('Tipo de registro'),
				field('Data de geração do arquivo', handler=to_date('%Y%m%d')),
				field('Nome do arquivo')
			)
		),
		'Corpo'=list(
			pattern='^02',
			fields=fields(
				field('Tipo de registro'),
				field('Código do título'),
				field('Descrição do título', handler=to_factor(
					levels=c('LTN', 'NTN-F', 'LFT', 'NTNB', 'NTNC', 'NTN-A3'),
					labels=c('LTN', 'NTNF', 'LFT', 'NTNB', 'NTNC', 'NTNA3')
				)),
				field('Data de emissão do título', handler=to_date('%Y%m%d')),
				field('Data de vencimento do título', handler=to_date('%Y%m%d')),
				field('Valor de mercado em PU'),
				field('Valor do PU em cenário de estresse'),
				field('Valor de mercado em PU para D+1')
			)
		)
	)
})

MarketData$register(PUWEB)

