
ContrCad <- MarketDataFWF$proto(expr={
	filename <- 'CONTRCAD.TXT'

	parser <- transmute::transmuter(
		transmute::match_regex('^(S|N)$', function(text, match) {
			text == 'S'
		}),
		NUMERIC.TRANSMUTER
	)

	fields <- fields(
		field('Identificação da Transação', width(6)),
		field('Complemento da Transação', width(3)),
		field('Tipo de Registro', width(2)),
		field('Data de Referência', width(8), to_date(format='%Y%m%d')),
		field('Código da Mercadoria', width(3), to_factor()),
		field('Tipo de Mercado', width(1), to_factor(
			levels=1:5,
			labels=c('Disponível', 'Futuro', 'Opções sobre Disponível', 'Opções sobre Futuro', 'Termo')
		)),
		field('Série (Opções) / Vencimento (Futuro)', width(4)),
		field('Indicador de Tipo de Opção', width(1), to_factor(
			levels=c('C', 'V'),
			labels=c('Compra', 'Venda')
		)),
		field('Tipo de Opção', width(1), to_factor(
			levels=c('A', 'E'),
			labels=c('Americana', 'Europeia')
		)),
		field('Data de Vencimento do Contrato', width(8), to_date(format='%Y%m%d')),
		field('Data de Inicio de Negociação', width(8), to_date(format='%Y%m%d')),
		field('Data de Inicio de Exercício', width(8), to_date(format='%Y%m%d')),
		field('Data Limite de Negociação', width(8), to_date(format='%Y%m%d')),
		field('Data Limite de Abertura de Posições', width(8), to_date(format='%Y%m%d')),
		field('Preço de Exercício (Opções)', width(15), to_numeric(dec='Número de Casas Decimais')),
		field('Número de Casas Decimais', width(1)),
		field('Código de Negociação Viva-Voz', width(20)),
		field('Código de Negociação GTS', width(20)),
		field('Código ISIN', width(12)),
		field('Contrato Objeto (no Vencimento)', width(4)),
		field('Tipo de Cotação', width(1), to_factor(
			levels=1:2,
			labels=c('Preço', 'Taxa')
		)),
		field('Tipo de Mercadoria', width(1), to_factor(
			levels=1:3,
			labels=c('Financeiro', 'Agropecuário', 'Energia')
		)),
		field('Variação Mínima de Apregoação', width(15), to_numeric(dec='Número de Casas Decimais')),
		field('Indicador de Opção com Ajuste', width(1)),
		field('Indicador de Mercadoria Internacional', width(1)),
		field('Código da Moeda', width(2), to_factor(
			levels=1:2,
			labels=c('Dólar', 'Reais')
		)),
		field('Indicador de Operação Estruturada', width(1)),
		field('Quantidade de dias Saques', width(5)),
		field('Quantidade de dias Corridos', width(5)),
		field('Quantidade de dias Úteis', width(5)),
		field('Descrição da mercadoria', width(15))
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
