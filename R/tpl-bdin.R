
BDIN <- MarketDataMultiPartFWF$proto(expr={
	filename <- 'BDIN'

	parts <- list(
		'Header'=list(
			pattern='^00',
			fields=fields(
				field('Tipo de registro', width(2)),
				field('Código do arquivo', width(4)),
				field('Código do usuário', width(4)),
				field('Código da origem', width(8)),
				field('Código do destino', width(4)),
				field('Data de geração do arquivo', width(8), to_date('%Y%m%d')),
				field('Data do pregão', width(8), to_date('%Y%m%d')),
				field('Hora de geração', width(4), to_time(format='%H%M')),
				field('Reserva', width(308))
			)
		),
		'Resumo Diário dos Índices'=list(
			pattern='^01',
			fields=fields(
				field('Tipo de registro', width(2)),
				field('Identificação do índice', width(2)),
				field('Nome do índice', width(30)),
				field('Índice de abertura do pregão', width(6)),
				field('Índice mínimo do pregão', width(6)),
				field('Índice máximo do pregão', width(6)),
				field('Índice da média aritmética dos índices do pregão', width(6)),
				field('Índice para liquidação', width(6)),
				field('Índice máximo do ano', width(6)),
				field('Data do índice máximo do ano', width(8), to_date('%Y%m%d')),
				field('Índice mínimo do ano', width(6)),
				field('Data do índice mínimo do ano', width(8), to_date('%Y%m%d')),
				field('Índice de fechamento', width(6)),
				field('Sinal da evolução percentual do índice de fechamento', width(1)),
				field('Evolução percentual do índice de fechamento', width(5), to_numeric(dec=2)),
				field('Sinal da evolução percentual do índice de ontem', width(1)),
				field('Evolução percentual do índice de ontem', width(5), to_numeric(dec=2)),
				field('Sinal da evolução percentual do índice da semana', width(1)),
				field('Evolução percentual do índice da semana', width(5), to_numeric(dec=2)),
				field('Sinal da evolução percentual do índice em uma semana', width(1)),
				field('Evolução percentual do índice em uma semana', width(5), to_numeric(dec=2)),
				field('Sinal da evolução percentual do índice no mês', width(1)),
				field('Evolução percentual do índice no mês', width(5), to_numeric(dec=2)),
				field('Sinal da evolução percentual do índice em um mês', width(1)),
				field('Evolução percentual do índice em um mês', width(5), to_numeric(dec=2)),
				field('Sinal da evolução percentual do índice no ano', width(1)),
				field('Evolução percentual do índice no ano', width(5), to_numeric(dec=2)),
				field('Sinal da evolução percentual do índice em um ano', width(1)),
				field('Evolução percentual do índice em um ano', width(5), to_numeric(dec=2)),
				field('Número de ações pertencentes ao índice que tiveram alta', width(3)),
				field('Número de ações pertencentes ao índice que tiveram baixa', width(3)),
				field('Número de ações pertencentes ao índice que permaneceram estáveis', width(3)),
				field('Número de total de ações pertencentes ao índice', width(3)),
				field('Número de negócios com ações pertencentes ao índice', width(6)),
				field('Quantidade de títulos negociados com ações pertencentes ao índice', width(15)),
				field('Volume dos negócios com ações pertencentes ao índice', width(17), to_numeric(dec=2)),
				field('Índice da média ponderada', width(6)),
				field('Reserva', width(148))
			)
		),
		'Resumo Diário de Negociações por Papel'=list(
			pattern='^02',
			fields=fields(
				field('Tipo de registro', width(2)),
				field('Código BDI', width(2)),
				field('Descrição do código de BDI', width(30)),
				field('Nome resumido da empresa emissora do papel', width(12)),
				field('Especificação do papel', width(10)),
				field('Indicador de característica do papel', width(1)),
				field('Código de negociação', width(12)),
				field('Tipo de mercado', width(3)),
				field('Descrição do tipo de mercado', width(15)),
				field('Prazo em dias do mercado a termo', width(3)),
				field('Preço de abertura do papel', width(11), to_numeric(dec=2)),
				field('Preço máximo do papel', width(11), to_numeric(dec=2)),
				field('Preço mínimo do papel', width(11), to_numeric(dec=2)),
				field('Preço médio do papel', width(11), to_numeric(dec=2)),
				field('Preço último negócio efetuado com o papel', width(11), to_numeric(dec=2)),
				field('Sinal da oscilação do preço do papel em relação ao pregão anterior', width(1)),
				field('Oscilação do preço do papel em relação ao pregão anterior', width(5), to_numeric(dec=2)),
				field('Preço da melhor oferta de compra do papel', width(11), to_numeric(dec=2)),
				field('Preço da melhor oferta de venda do papel', width(11), to_numeric(dec=2)),
				field('Número de negócios efetuados com o papel', width(5)),
				field('Quantidade total de títulos negociados neste papel', width(15)),
				field('Volume total de títulos negociados neste papel', width(17), to_numeric(dec=2)),
				field('Preço de exercício para o mercado de opções ou valor do contrato para o mercado de termo secundário', width(11), to_numeric(dec=2)),
				field('Data do vencimento para os mercados de opções, termo secundário ou futuro', width(8), to_date('%Y%m%d')),
				field('Indicador de correção de preços de exercícios ou valores de contrato para os mercados de opções, termo secundário ou futuro', width(1)),
				field('Descrição do indicador de correção de preços de exercícios ou valores de contrato para os mercados de opções, termo secundário ou futuro', width(15)),
				field('Fator de cotação do papel', width(7)),
				field('Preço de exercício em pontos para opções referenciadas em dólar ou valor de contrato em pontos para termo secundário', width(13), to_numeric(dec=6)),
				field('Código do papel no sistema ISIN', width(12)),
				field('Número de distribuição do papel', width(3)),
				field('Estilo adotado para o exercício de opções de compra/venda', width(1)),
				field('Descrição do estilo', width(15)),
				field('Indicador de correção de preços de exercícios ou valores de contrato para os mercados de opções, term secundário ou futuro', width(3)),
				field('Oscilação do preço do preço do papel em relação ao pregão anterior 2', width(7), to_numeric(dec=2)),
				field('Reserva', width(44))
			)
		),
		'Resumo Diário de Negociações por Código BDI'=list(
			pattern='^03',
			fields=fields(
				field('Tipo de registro', width(2)),
				field('Código BDI',  width(2)),
				field('Descrição do código de BDI', width(30)),
				field('Número de negócios efetuados no pregão corrente', width(5)),
				field('Quantidade total de títulos negociados', width(15)),
				field('Volume geral transacionado no pregão corrente', width(15), to_numeric(dec=2)),
				field('Número de negócios efetuados no pregão corrente 2', width(9)),
				field('Reserva', width(270))
			)
		),
		'Maiores Oscilações do Mercado a Vista'=list(
			pattern='^04',
			fields=fields(
				field('Tipo de registro', width(2)),
				field('Indica se é oscilação positiva ou negativa', width(1), to_factor(levels=c('A', 'B'), labels=c('ALTA (POSITIVA)', 'BAIXA (NEGATIVA)'))),
				field('Nome resumido da empresa emissora do papel', width(12)),
				field('Especificação do papel', width(10)),
				field('Preço último negócio efetuado com o papel-mercado durante o pregão corrente', width(11), to_numeric(dec=2)),
				field('Número negócios efetuados com o papel-mercado durante o pregão corrente', width(5)),
				field('Oscilação do preço do papel-mercado em relação ao pregão anterior', width(5), to_numeric(dec=2)),
				field('Código de negociação', width(12)),
				field('Oscilação do preço do papel-mercado em relação ao pregão anterior 2', width(7), to_numeric(dec=2)),
				field('Reserva', width(285))
			)
		),
		'Maiores Oscilação das Ações do IBOVESPA'=list(
			pattern='^05',
			fields=fields(
				field('Tipo de registro', width(2)),
				field('Indica se é oscilação positiva ou negativa', width(1), to_factor(levels=c('A', 'B'), labels=c('ALTA (POSITIVA)', 'BAIXA (NEGATIVA)'))),
				field('Nome resumido da empresa emissora do papel', width(12)),
				field('Especificação do papel', width(10)),
				field('Preço último negócio efetuado com o papel-mercado durante o pregão corrente', width(11), to_numeric(dec=2)),
				field('Número negócios efetuados com o papel-mercado durante o pregão corrente', width(5)),
				field('Oscilação do preço do papel-mercado em relação ao pregão anterior', width(5), to_numeric(dec=2)),
				field('Código de negociação', width(12)),
				field('Oscilação do preço do papel-mercado em relação ao pregão anterior 2', width(7), to_numeric(dec=2)),
				field('Reserva', width(285))
			)
		),
		'As Mais Negociadas no Mercado a Vista'=list(
			pattern='^06',
			fields=fields(
				field('Tipo de registro', width(2)),
				field('Nome resumido da empresa emissora do papel', width(12)),
				field('Especificação do papel', width(10)),
				field('Quantidade de títulos negociados no pregão', width(15)),
				field('Volume geral no pregão deste papel-mercado', width(17), to_numeric(dec=2)),
				field('Código de negociação', width(12)),
				field('Reserva', width(282))
			)
		),
		'As Mais Negociadas'=list(
			pattern='^07',
			fields=fields(
				field('Tipo de registro', width(2)),
				field('Tipo de mercado', width(3)),
				field('Descrição do tipo de mercado', width(20)),
				field('Nome resumido da empresa emissora do papel', width(12)),
				field('Especificação do papel', width(10)),
				field('Indicador de correção de preços de exercícios ou valores de contrato para os mercados de opções, termo secundário ou futuro, respectivamente', width(2)),
				field('Descrição do indicador de correção de preços de exercícios ou valores de contrato para os mercados de opções, termo secundário ou futuro, respectivamente', width(15)),
				field('Preço de exercício para o mercado de opções ou valor de contrato para os mercados de termo secundário', width(11), to_numeric(dec=2)),
				field('Data do vencimento para os mercados de opções, termo secundário ou futuro', width(8), to_date('%Y%m%d')),
				field('Prazo em dias do mercado a termo', width(3)),
				field('Quantidade de títulos negociados no pregão', width(15)),
				field('Volume geral no pregão deste papel mercado', width(17), to_numeric(dec=2)),
				field('Participação do volume do papel no volume total do mercado', width(5), to_numeric(dec=2)),
				field('Código de negociação', width(12)),
				field('Indicador de correção de preços de ativos', width(3)),
				field('Reserva', width(212))
			)
		),
		"Resumo Diário dos IOPV's"=list(
			pattern='^08',
			fields=fields(
				field('Tipo de registro', width(2)),
				field('Identificação do IOPV', width(2)),
				field('Sigla do IOPV', width(4)),
				field('Nome resumido do IOPV', width(12)),
				field('Nome do IOPV', width(30)),
				field('IOPV de abertura do pregão', width(7), to_numeric(dec=2)),
				field('IOPV mínimo do pregão', width(7), to_numeric(dec=2)),
				field('IOPV máximo do pregão', width(7), to_numeric(dec=2)),
				field("IOPV da média aritmética dos IOPV's do pregão", width(7), to_numeric(dec=2)),
				field('IOPV de fechamento', width(7), to_numeric(dec=2)),
				field('Sinal da evolução percentual do IOPV de fechamento', width(1)),
				field('Evolução percentual do iopv de fechamento', width(5), to_numeric(dec=2)),
				field('Reserva', width(259))
			)
		),
		"BDR's Não Patrocinadas - Valor de Referência"=list(
			pattern='^09',
			fields=fields(
				field('Tipo de registro', width(2)),
				field('Código de negociação', width(15)),
				field('Nome resumido da empresa emissora do papel', width(12)),
				field('Especificação do papel', width(10)),
				field('Valor de referência', width(11), to_numeric(dec=2)),
				field('Reserva', width(303))
			)
		),
		"Trailer"=list(
			pattern='^99',
			fields=fields(
				field('Tipo de registro', width(2)),
				field('Código do arquivo', width(4)),
				field('Código do usuário', width(4)),
				field('Código da origem', width(8)),
				field('Código do destino', width(4)),
				field('Data da geração do arquivo', width(8), to_date('%Y%m%d')),
				field('Total de registros', width(9)),
				field('Reserva', width(311))
			)
		)
	)
})

MarketData$register(BDIN)

