
Premio <- MarketDataFWF$proto(expr={
	filename <- 'Premio.txt'
	
	fields <- fields(
		field('Identificação da transação', width=6),
		field('Complemento da transação', width=3),
		field('Tipo de registro', width=2),
		field('Data de geração do arquivo', width=8, handler=to_date('%Y%m%d')),
		field('Código da mercadoria', width=3, handler=to_factor()),
		field('Tipo de mercado', width=1, handler=to_factor(
			levels=1:5,
			labels=c('Disponível', 'Futuro', 'Opções sobre Disponível', 'Opções sobre Futuro', 'Termo')
		)),
		field('Série', width=4),
		field('Tipo de opção', width=1, handler=to_factor(
			levels=c('C', 'V'),
			labels=c('Compra', 'Venda')
		)),
		field('Modelo de opção', width=1, handler=to_factor(
			levels=c('A', 'E'),
			labels=c('Americana', 'Europeia')
		)),
		field('Data de vencimento', width=8, handler=to_date('%Y%m%d')),
		field('Preço de exercício', width=15, handler=to_numeric(dec='Número de casas decimais')),
		field('Prêmio de referência', width=15, handler=to_numeric(dec='Número de casas decimais')),
		field('Número de casas decimais', width=1)
	)
})

MarketData$register(Premio)
