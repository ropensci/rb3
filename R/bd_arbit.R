

BD_Arbit <- MarketDataFWF$proto(expr={
	name <- 'bd_arbit'
	filename <- 'BD_Final.txt'
	
	parser <- textparser::textparser(
		parse_sign=textparser::parser('^(\\+|-)$', function(text, match) {
			idx <- text == '-'
			x <- rep(1, length(text))
			x[idx] <- -1
			x
		})
	)
	
	fields <- fields(
		fwf_field('Identificação da transação', width=6),
		fwf_field('Complemento da transação', width=3),
		fwf_field('Tipo de registro', width=2),
		fwf_field('Data de geração do arquivo', width=8, handler=to_date(format='%Y%m%d')),
		fwf_field('Tipo de negociação', width=2, handler=to_factor(levels='PR', labels='Pregão')),
		fwf_field('Código da mercadoria', width=3),
		fwf_field('Código do mercado', width=1),
		fwf_field('Tipo da série', width=1,
			handler=to_factor(levels=c('C', 'V', '*'), labels=c('Opção de Compra', 'Opção de Venda', 'Futuro'))),
		fwf_field('Série (opç)/vencimento (fut)', width=4),
		fwf_field('Hora de criação deste registro', width=6, handler=to_time(format='%H%M%S')),
		fwf_field('Data de vencimento (fut/opç)', width=8, handler=to_date(format='%Y%m%d')),
		fwf_field('Preço de exercício (opç)', width=13, handler=to_numeric(dec='Número de casas decimais dos campos com *')),
		fwf_field('Valor do ponto ou tamanho do contrato', width=13, handler=to_numeric(dec=7)),
		fwf_field('Volume do dia em R$', width=13, handler=to_numeric()),
		fwf_field('Volume do dia em US$', width=13, handler=to_numeric()),
		fwf_field('Qtd. de contratos em aberto', width=8),
		fwf_field('Qtd. de negócios efetuados no dia', width=8),
		fwf_field('Qtd. de contratos negociados no dia', width=8),
		fwf_field('Qtd. de contratos da última oferta compra do dia', width=5),
		fwf_field('Sinal da cot.da última oferta de compra do dia', width=1),
		fwf_field('Cotação da última oferta de compra do dia', width=8,
			handler=to_numeric(dec='Número de casas decimais dos campos com *', sign='Sinal da cot.da última oferta de compra do dia')),
		fwf_field('Qtd. de contratos da última oferta de venda do dia', width=5),
		fwf_field('Sinal da cot.da última oferta de venda do dia', width=1),
		fwf_field('Cotação da última oferta de venda do dia', width=8,
			handler=to_numeric(dec='Número de casas decimais dos campos com *', sign='Sinal da cot.da última oferta de venda do dia')),
		fwf_field('Sinal da cotação do primeiro negócio do dia', width=1),
		fwf_field('Cotação do primeiro negócio do dia', width=8,
			handler=to_numeric(dec='Número de casas decimais dos campos com *', sign='Sinal da cotação do primeiro negócio do dia')),
		fwf_field('Sinal da cotação do menor negócio do dia', width=1),
		fwf_field('Cotação do menor negócio do dia', width=8,
			handler=to_numeric(dec='Número de casas decimais dos campos com *', sign='Sinal da cotação do menor negócio do dia')),
		fwf_field('Sinal da cotação do maior negócio do dia', width=1),
		fwf_field('Cotação do maior negócio do dia', width=8,
			handler=to_numeric(dec='Número de casas decimais dos campos com *', sign='Sinal da cotação do maior negócio do dia')),
		fwf_field('Sinal da cotação média dos negócios do dia', width=1),
		fwf_field('Cotação média dos negócios do dia', width=8,
			handler=to_numeric(dec='Número de casas decimais dos campos com *', sign='Sinal da cotação média dos negócios do dia')),
		fwf_field('Qtd. de contratos do último negócio do dia', width=5),
		fwf_field('Sinal da cotação do último negócio do dia', width=1),
		fwf_field('Cotação do último negócio do dia', width=8,
			handler=to_numeric(dec='Número de casas decimais dos campos com *', sign='Sinal da cotação do último negócio do dia')),
		fwf_field('Hora do último negócio do dia', width=6,
			handler=to_time(format='%H%M%S')),
		fwf_field('Data do último negócio', width=8,
			handler=to_date(format='%Y%m%d')),
		fwf_field('Sinal da cotação do último negócio anterior', width=1),
		fwf_field('Cotação do último negócio anterior', width=8,
			handler=to_numeric(dec='Número de casas decimais dos campos com *', sign='Sinal da cotação do último negócio anterior')),
		fwf_field('Sinal da cotação de fechamento do dia', width=1),
		fwf_field('Cotação de fechamento do dia', width=8,
			handler=to_numeric(dec='Número de casas decimais dos campos com *', sign='Sinal da cotação de fechamento do dia')),
		fwf_field('Sinal da cotação ajuste (fut)', width=1),
		fwf_field('Cotação ajuste (fut)', width=13,
			handler=to_numeric(dec='Número de casas decimais dos campos com *', sign='Sinal da cotação ajuste (fut)')),
		fwf_field('Situação do ajuste do dia', width=1,
			handler=to_factor(levels=c('S', 'A'), labels=c('Ajuste Final', 'Ajuste Corrigido'))),
		fwf_field('Sinal da cotação de ajuste do dia anterior (fut)', width=1),
		fwf_field('Cotação de ajuste do dia anterior (fut)', width=13,
			handler=to_numeric(dec='Número de casas decimais dos campos com *', sign='Sinal da cotação de ajuste do dia anterior (fut)')),
		fwf_field('Situação do ajuste do dia anterior', width=1,
			handler=to_factor(levels=c('S', 'A'), labels=c('Ajuste Final', 'Ajuste Corrigido'))),
		fwf_field('Valor do ajuste por contrato', width=13, handler=to_numeric(dec=2)),
		fwf_field('Volume exercido no dia em R$', width=13, handler=to_numeric()),
		fwf_field('Volume exercido no dia em US$', width=13, handler=to_numeric()),
		fwf_field('Quantidade de negócios exercidos no dia', width=8),
		fwf_field('Quantidade de contratos exercidos no dia', width=8),
		fwf_field('Número de casas decimais dos campos com *', width=1),
		fwf_field('Número de casas decimais dos ajustes', width=1),
		fwf_field('Percentual de oscilação', width=8, handler=to_numeric(dec=1)),
		fwf_field('Sinal da oscilação', width=1),
		fwf_field('Valor da diferença (variação em pontos)', width=8),
		fwf_field('Sinal da diferença (variação em pontos)', width=1),
		fwf_field('Valor da equivalência', width=8, handler=to_numeric(dec=2)),
		fwf_field('Valor do dólar do dia anterior', width=13, handler=to_numeric(dec=7)),
		fwf_field('Valor do dólar do dia atual', width=13, handler=to_numeric(dec=7)),
		fwf_field('Valor do delta da opção (margem)', width=9, handler=to_numeric(dec=7)),
		fwf_field('Qtd. saques até data de vencimento', width=5, handler=to_numeric()),
		fwf_field('Qtd. dias corridos até data de vencimento', width=5, handler=to_numeric()),
		fwf_field('Qtd. dias úteis até data de vencimento', width=5, handler=to_numeric()),
		fwf_field('Vencimento do contrato-objeto', width=4),
		fwf_field('Margem para clientes normais', width=13, handler=to_numeric(dec=2)),
		fwf_field('Margem para clientes hedgers', width=13, handler=to_numeric(dec=2)),
		fwf_field('Data de início do período de entrega (agrícolas)', width=8, handler=to_date(format='%Y%m%d')),
		fwf_field('Seqüência do vencimento futuro', width=3),
		fwf_field('Código de negociação viva voz', width=20),
		fwf_field('Código de negociação GTS', width=20),
		fwf_field('Canais de negociação permitidos', width=1,
			handler=to_factor(levels=c('V', 'E', 'A'), labels=c('Viva-Voz', 'Eletrônico', 'Ambos'))),
		fwf_field('Referência deste resumo de negócios', width=4, handler=to_factor(levels='MERC')),
		fwf_field('Data-limite para negociação', width=8, handler=to_date(format='%Y%m%d')),
		fwf_field('Data de liquidação financeira', width=8, handler=to_date(format='%Y%m%d')),
		fwf_field('Sinal do limite mínimo para negociação', width=1),
		fwf_field('Limite mínimo para negociação (fut)', width=13),
		fwf_field('Sinal do limite máximo para negociação', width=1),
		fwf_field('Limite máximo para negociação (fut)', width=13)
	)
	
	colnames <- fields_names(fields)
	widths <- fields_widths(fields)
	handlers <- fields_handlers(fields)
})

MarketData$register(BD_Arbit)
