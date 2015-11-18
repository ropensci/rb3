
SupVol <- MarketDataMultiPartCSV$proto(expr={
	filename <- 'SupVol.txt'
	separator <- ';'
	
	parts <- list(
		'Cabeçalho'=list(
			lines=1,
			fields=fields(
				field('Data de geração do arquivo', to_date('%Y%m%d')),
				field('Identificação do arquivo')
			)
		),
		'Corpo'=list(
			lines=-1,
			fields=fields(
				field('Código da Curva de Volatilidade'),
				field('Descrição da Curva de Volatilidade'),
				field('Prazo (dias de Saque)'),
				field('Prazo (dias Corridos)'),
				field('Valor', to_numeric(dec=7))
			)
		)
	)
})

MarketData$register(SupVol)

