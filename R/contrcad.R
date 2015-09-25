
ContrCad <- MarketDataFWF$proto(expr={
	name <- 'contrcad'
	filename <- 'CONTRCAD.TXT'
	widths <- c(6, 3, 2, 8, 3, 1, 4, 1, 1, 8, 8, 8, 8, 8, 15, 1, 20, 20, 12, 4, 1,
		1, 15, 1, 1, 2, 1, 5, 5, 5, 15
	)
	colnames <- c('Identificação da Transação', 'Complemento da Transação',
		'Tipo de Registro', 'Data de Referência', 'Código da Mercadoria',
		'Tipo de Mercado', 'Série (Opções) / Vencimento (Futuro)',
		'Indicador de Tipo de Opção', 'Tipo de Opção',
		'Data de Vencimento do Contrato', 'Data de Inicio de Negociação',
		'Data de Inicio de Exercício', 'Data Limite de Negociação',
		'Data Limite de Abertura de Posições', 'Preço de Exercício (Opções)',
		'Número de Casas Decimais', 'Código de Negociação Viva-Voz',
		'Código de Negociação GTS', 'Código ISIN',
		'Contrato Objeto (no Vencimento)', 'Tipo de Cotação', 'Tipo de Mercadoria',
		'Variação Mínima de Apregoação', 'Indicador de Opção com Ajuste',
		'Indicador de Mercadoria Internacional', 'Código da Moeda',
		'Indicador de Operação Estruturada', 'Quantidade de dias Saques',
		'Quantidade de dias Corridos', 'Quantidade de dias Úteis',
		'Descrição da mercadoria'
	)
	
	parser <- textparser::textparser(
		parse_SN=textparser::parser('^(S|N)$', function(text, match) {
			text == 'S'
		}),
		.PARSER
	)
	
	transform <- function(., df) {
		base::within(df, {
			`Código da Mercadoria` <- factor(`Código da Mercadoria`)
			`Preço de Exercício (Opções)` <- `Preço de Exercício (Opções)`/(10^`Número de Casas Decimais`)
			`Tipo de Mercado` <- factor(`Tipo de Mercado`,
				levels=1:5,
				labels=c('Disponível', 'Futuro', 'Opções sobre Disponível', 'Opções sobre Futuro', 'Termo')
			)
			`Indicador de Tipo de Opção` <- factor(`Indicador de Tipo de Opção`,
				levels=c('C', 'V'),
				labels=c('Compra', 'Venda')
			)
			`Tipo de Opção` <- factor(`Tipo de Opção`,
				levels=c('A', 'E'),
				labels=c('Americana', 'Europeia')
			)
			`Tipo de Cotação` <- factor(`Tipo de Cotação`,
				levels=1:2,
				labels=c('Preço', 'Taxa')
			)
			`Tipo de Mercadoria` <- factor(`Tipo de Mercadoria`,
				levels=1:3,
				labels=c('Financeiro', 'Agropecuário', 'Energia')
			)
			`Código da Moeda` <- factor(`Código da Moeda`,
				levels=1:2,
				labels=c('Dólar', 'Reais')
			)
		})
	}
})

ContrCadIPN <- ContrCad$proto(expr={
	filename <- 'CONTRCAD-IPN.TXT'
})

MarketData$register(ContrCad)
MarketData$register(ContrCadIPN)

# TODO: implement summary for templates
# tratar os campos de lookup como factor
# configurar o tratamento de casas decimais
# fazer trim nos campos texto
# debug de campos texto: substituir espaços por .
# implementar textparser para R
