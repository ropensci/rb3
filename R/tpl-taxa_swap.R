

TaxaSwap <- MarketDataFWF$proto(expr={
	filename <- 'TaxaSwap.txt'

	parser <- transmute::transmuter(
		transmute::match_regex('\\+|-', function(text, match) {
			idx <- text == '-'
			x <- rep(1, length(text))
			x[idx] <- -1
			x
		}),
		NUMERIC.TRANSMUTER
	)

	fields <- fields(
		field('Identificação da transação', width=6),
		field('Complemento da transação', width=3),
		field('Tipo de registro', width=2),
		field('Data de geração do arquivo', width=8, handler=to_date('%Y%m%d')),
		field('Código das curvas a termo', width=2, handler=to_factor()),
		field('Código da taxa ', width=5, handler=to_factor()),
		field('Descrição da taxa', width=15, handler=to_factor()),
		field('Número de dias corridos da taxa de juro', width=5),
		field('Número de saques da taxa de juro', width=5),
		field('Sinal da taxa teórica', width=1),
		field('Taxa teórica', width=14,
			handler=to_numeric(dec=7, sign='Sinal da taxa teórica')),
		field('Característica do vértice', width=1,
			handler=to_factor(levels=c('F', 'M'), labels=c('Fixo', 'Móvel'))),
		field('Código do vértice', width=5)
	)
})

MarketData$register(TaxaSwap)
