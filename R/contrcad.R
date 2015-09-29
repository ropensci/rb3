
ContrCad <- MarketDataFWF$proto(expr={
	filename <- 'CONTRCAD.TXT'
	
	parser <- textparser::textparser(
		parse_SN=textparser::parser('^(S|N)$', function(text, match) {
			text == 'S'
		}),
		parse_numeric=textparser::parser('^\\d+$', function(text, match) {
			as.numeric(text)
		})
	)
	
	fields <- fields(
		fwf_field('Identificação da Transação', width=6),
		fwf_field('Complemento da Transação', width=3),
		fwf_field('Tipo de Registro', width=2),
		fwf_field('Data de Referência', width=8, handler=to_date(format='%Y%m%d')),
		fwf_field('Código da Mercadoria', width=3, handler=to_factor()),
		fwf_field('Tipo de Mercado', width=1, handler=to_factor(
			levels=1:5,
			labels=c('Disponível', 'Futuro', 'Opções sobre Disponível', 'Opções sobre Futuro', 'Termo')
		)),
		fwf_field('Série (Opções) / Vencimento (Futuro)', width=4),
		fwf_field('Indicador de Tipo de Opção', width=1, handler=to_factor(
			levels=c('C', 'V'),
			labels=c('Compra', 'Venda')
		)),
		fwf_field('Tipo de Opção', width=1, handler=to_factor(
			levels=c('A', 'E'),
			labels=c('Americana', 'Europeia')
		)),
		fwf_field('Data de Vencimento do Contrato', width=8, handler=to_date(format='%Y%m%d')),
		fwf_field('Data de Inicio de Negociação', width=8, handler=to_date(format='%Y%m%d')),
		fwf_field('Data de Inicio de Exercício', width=8, handler=to_date(format='%Y%m%d')),
		fwf_field('Data Limite de Negociação', width=8, handler=to_date(format='%Y%m%d')),
		fwf_field('Data Limite de Abertura de Posições', width=8, handler=to_date(format='%Y%m%d')),
		fwf_field('Preço de Exercício (Opções)', width=15, handler=to_numeric(dec='Número de Casas Decimais')),
		fwf_field('Número de Casas Decimais', width=1),
		fwf_field('Código de Negociação Viva-Voz', width=20),
		fwf_field('Código de Negociação GTS', width=20),
		fwf_field('Código ISIN', width=12),
		fwf_field('Contrato Objeto (no Vencimento)', width=4),
		fwf_field('Tipo de Cotação', width=1, handler=to_factor(
			levels=1:2,
			labels=c('Preço', 'Taxa')
		)),
		fwf_field('Tipo de Mercadoria', width=1, handler=to_factor(
			levels=1:3,
			labels=c('Financeiro', 'Agropecuário', 'Energia')
		)),
		fwf_field('Variação Mínima de Apregoação', width=15, handler=to_numeric(dec='Número de Casas Decimais')),
		fwf_field('Indicador de Opção com Ajuste', width=1),
		fwf_field('Indicador de Mercadoria Internacional', width=1),
		fwf_field('Código da Moeda', width=2, handler=to_factor(
			levels=1:2,
			labels=c('Dólar', 'Reais')
		)),
		fwf_field('Indicador de Operação Estruturada', width=1),
		fwf_field('Quantidade de dias Saques', width=5),
		fwf_field('Quantidade de dias Corridos', width=5),
		fwf_field('Quantidade de dias Úteis', width=5),
		fwf_field('Descrição da mercadoria', width=15)
	)
})

ContrCadIPN <- ContrCad$proto(filename='CONTRCAD-IPN.TXT')

MarketData$register(ContrCad)
MarketData$register(ContrCadIPN)

# TODO: implement summary for templates
# tratar os campos de lookup como factor
# configurar o tratamento de casas decimais
# fazer trim nos campos texto
# debug de campos texto: substituir espaços por .
# implementar textparser para R
