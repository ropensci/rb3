

BD_Arbit <- MarketDataFWF$proto(expr={
	filename <- 'BD_Arbit.txt'

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
		field('Identificação da transação', width=6, handler=to_numeric()),
		field('Complemento da transação', width=3, handler=to_numeric()),
		field('Tipo de registro', width=2, handler=to_numeric()),
		field('Data de geração do arquivo', width=8, handler=to_date(format='%Y%m%d')),
		field('Tipo de negociação', width=2, handler=to_factor(levels='PR', labels='Pregão')),
		field('Código da mercadoria', width=3),
		field('Código do mercado', width=1),
		field('Tipo da série', width=1, handler=to_factor(
			levels=c('C', 'V', '*'),
			labels=c('Opção de Compra', 'Opção de Venda', 'Futuro')
		)),
		field('Série (opç)/vencimento (fut)', width=4, handler=to_factor()),
		field('Hora de criação deste registro', width=6, handler=to_time(format='%H%M%S')),
		field('Data de vencimento (fut/opç)', width=8, handler=to_date(format='%Y%m%d')),
		field('Preço de exercício (opç)', width=13, handler=to_numeric(dec='Número de casas decimais dos campos com *')),
		field('Valor do ponto ou tamanho do contrato', width=13, handler=to_numeric(dec=7)),
		field('Volume do dia em R$', width=13, handler=to_numeric()),
		field('Volume do dia em US$', width=13, handler=to_numeric()),
		field('Qtd. de contratos em aberto', width=8),
		field('Qtd. de negócios efetuados no dia', width=8),
		field('Qtd. de contratos negociados no dia', width=8),
		field('Qtd. de contratos da última oferta compra do dia', width=5),
		field('Sinal da cot.da última oferta de compra do dia', width=1),
		field('Cotação da última oferta de compra do dia', width=8,
			handler=to_numeric(dec='Número de casas decimais dos campos com *', sign='Sinal da cot.da última oferta de compra do dia')),
		field('Qtd. de contratos da última oferta de venda do dia', width=5),
		field('Sinal da cot.da última oferta de venda do dia', width=1),
		field('Cotação da última oferta de venda do dia', width=8,
			handler=to_numeric(dec='Número de casas decimais dos campos com *', sign='Sinal da cot.da última oferta de venda do dia')),
		field('Sinal da cotação do primeiro negócio do dia', width=1),
		field('Cotação do primeiro negócio do dia', width=8,
			handler=to_numeric(dec='Número de casas decimais dos campos com *', sign='Sinal da cotação do primeiro negócio do dia')),
		field('Sinal da cotação do menor negócio do dia', width=1),
		field('Cotação do menor negócio do dia', width=8,
			handler=to_numeric(dec='Número de casas decimais dos campos com *', sign='Sinal da cotação do menor negócio do dia')),
		field('Sinal da cotação do maior negócio do dia', width=1),
		field('Cotação do maior negócio do dia', width=8,
			handler=to_numeric(dec='Número de casas decimais dos campos com *', sign='Sinal da cotação do maior negócio do dia')),
		field('Sinal da cotação média dos negócios do dia', width=1),
		field('Cotação média dos negócios do dia', width=8,
			handler=to_numeric(dec='Número de casas decimais dos campos com *', sign='Sinal da cotação média dos negócios do dia')),
		field('Qtd. de contratos do último negócio do dia', width=5),
		field('Sinal da cotação do último negócio do dia', width=1),
		field('Cotação do último negócio do dia', width=8,
			handler=to_numeric(dec='Número de casas decimais dos campos com *', sign='Sinal da cotação do último negócio do dia')),
		field('Hora do último negócio do dia', width=6,
			handler=to_time(format='%H%M%S')),
		field('Data do último negócio', width=8,
			handler=to_date(format='%Y%m%d')),
		field('Sinal da cotação do último negócio anterior', width=1),
		field('Cotação do último negócio anterior', width=8,
			handler=to_numeric(dec='Número de casas decimais dos campos com *', sign='Sinal da cotação do último negócio anterior')),
		field('Sinal da cotação de fechamento do dia', width=1),
		field('Cotação de fechamento do dia', width=8,
			handler=to_numeric(dec='Número de casas decimais dos campos com *', sign='Sinal da cotação de fechamento do dia')),
		field('Sinal da cotação ajuste (fut)', width=1),
		field('Cotação ajuste (fut)', width=13,
			handler=to_numeric(dec='Número de casas decimais dos campos com *', sign='Sinal da cotação ajuste (fut)')),
		field('Situação do ajuste do dia', width=1,
			handler=to_factor(levels=c('S', 'A'), labels=c('Ajuste Final', 'Ajuste Corrigido'))),
		field('Sinal da cotação de ajuste do dia anterior (fut)', width=1),
		field('Cotação de ajuste do dia anterior (fut)', width=13,
			handler=to_numeric(dec='Número de casas decimais dos campos com *', sign='Sinal da cotação de ajuste do dia anterior (fut)')),
		field('Situação do ajuste do dia anterior', width=1,
			handler=to_factor(levels=c('S', 'A'), labels=c('Ajuste Final', 'Ajuste Corrigido'))),
		field('Valor do ajuste por contrato', width=13, handler=to_numeric(dec=2)),
		field('Volume exercido no dia em R$', width=13, handler=to_numeric()),
		field('Volume exercido no dia em US$', width=13, handler=to_numeric()),
		field('Quantidade de negócios exercidos no dia', width=8),
		field('Quantidade de contratos exercidos no dia', width=8),
		field('Número de casas decimais dos campos com *', width=1),
		field('Número de casas decimais dos ajustes', width=1),
		field('Percentual de oscilação', width=8, handler=to_numeric(dec=1)),
		field('Sinal da oscilação', width=1),
		field('Valor da diferença (variação em pontos)', width=8),
		field('Sinal da diferença (variação em pontos)', width=1),
		field('Valor da equivalência', width=8, handler=to_numeric(dec=2)),
		field('Valor do dólar do dia anterior', width=13, handler=to_numeric(dec=7)),
		field('Valor do dólar do dia atual', width=13, handler=to_numeric(dec=7)),
		field('Valor do delta da opção (margem)', width=9, handler=to_numeric(dec=7)),
		field('Qtd. saques até data de vencimento', width=5, handler=to_numeric()),
		field('Qtd. dias corridos até data de vencimento', width=5, handler=to_numeric()),
		field('Qtd. dias úteis até data de vencimento', width=5, handler=to_numeric()),
		field('Vencimento do contrato-objeto', width=4, handler=to_factor()),
		field('Margem para clientes normais', width=13, handler=to_numeric(dec=2)),
		field('Margem para clientes hedgers', width=13, handler=to_numeric(dec=2)),
		field('Data de início do período de entrega (agrícolas)', width=8, handler=to_date(format='%Y%m%d')),
		field('Seqüência do vencimento futuro', width=3),
		field('Código de negociação viva voz', width=20),
		field('Código de negociação GTS', width=20),
		field('Canais de negociação permitidos', width=1,
			handler=to_factor(levels=c('V', 'E', 'A'), labels=c('Viva-Voz', 'Eletrônico', 'Ambos'))),
		field('Referência deste resumo de negócios', width=4, handler=to_factor(levels='MERC')),
		field('Data-limite para negociação', width=8, handler=to_date(format='%Y%m%d')),
		field('Data de liquidação financeira', width=8, handler=to_date(format='%Y%m%d')),
		field('Sinal do limite mínimo para negociação', width=1),
		field('Limite mínimo para negociação (fut)', width=13),
		field('Sinal do limite máximo para negociação', width=1),
		field('Limite máximo para negociação (fut)', width=13)
	)
})

BDPrevia <- BD_Arbit$proto(filename='BDPrevia.txt')
BDAtual <- BD_Arbit$proto(filename='BDAtual.txt')
BDAjuste <- BD_Arbit$proto(filename='BDAjuste.txt')
BDAfterHour <- BD_Arbit$proto(filename='BDAfterHour.txt')
BD_Final <- BD_Arbit$proto(filename='BD_Final.txt')

MarketData$register(BD_Arbit)
MarketData$register(BDPrevia)
MarketData$register(BDAtual)
MarketData$register(BDAjuste)
MarketData$register(BDAfterHour)
MarketData$register(BD_Final)
