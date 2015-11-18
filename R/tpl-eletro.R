
Eletro <- MarketDataFWF$proto(expr={
	filename <- 'Eletro.txt'

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
		field("Identificação da transação", width=6),
		field("Complemento da transação", width=3),
		field("Tipo de tegistro", width=2),
		field("Data de geração do arquivo", width=8, handler=to_date('%Y%m%d')),
		field("Tipo de negociação", width=2, handler=to_factor(
			levels=c('SW', 'AG', 'TO'),
			labels=c('Swaps', 'Teleagro', 'Teleouro')
		)),
		field("Código da mercadoria", width=3),
		field("Código do mercado", width=1),
		field("Data-base", width=8, handler=to_date('%Y%m%d')),
		field("Data de vencimento", width=8, handler=to_date('%Y%m%d')),
		field("Volume do dia em R$", width=13),
		field("Volume do dia em US$", width=13),
		field("Qtd. contratos em aberto após liquidação", width=8),
		field("Qtd. de negócios efetuados", width=8),
		field("Qtd. de contratos negociados", width=8),
		field("Qtd. de contratos aberto antes da liquidação", width=8),
		field("Qtd. de contratos liquidados", width=8),
		field("Qtd. de contratos aberto final", width=8),
		field("Taxa média (swp)/prêmio médio (opç flex)", width=9, handler=to_numeric(dec=4)),
		field("Sinal da taxa média/prêmio médio", width=1),
		field("Tipo de taxa média", width=1, handler=to_factor(
			levels=c('D', 'P'),
			labels=c('diária', 'no período')
		)),
		field("Preço de exercício médio (opç flex)", width=22, handler=to_numeric(dec=7)),
		field("Sinal do preço médio de exercício", width=1),
		field("Volume aberto em R$", width=13),
		field("Volume aberto em US$", width=13)
	)
})

MarketData$register(Eletro)
