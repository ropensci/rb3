
Premio <- MarketDataFWF$proto(expr={
  id <- 'Premio'
  filename <- 'Premio.txt'
  description <- 'Prêmio de Referência para Opções sobre Derivativos'

  fields <- fields(
    field('id_transacao','Identificação da transação', width(6)),
    field('compl_transacao','Complemento da transação', width(3)),
    field('tipo_registro','Tipo de registro', width(2)),
    field('data_geracao_arquivo','Data de geração do arquivo', width(8), to_date('%Y%m%d')),
    field('cod_mercadoria', 'Código da mercadoria', width(3), to_factor()),
    field('tipo_mercado', 'Tipo de mercado', width(1), to_factor(levels=1:5, labels=c('spot', 'future', 'option-on-spot', 'option-on-future', 'forward'))),
    field('serie', 'Série', width(4)),
    field('tipo_opcao', 'Tipo de opção', width(1), to_factor(levels=c('C', 'V'), labels=c('call', 'put'))),
    field('tipo_exercicio', 'Tipo de exercício', width(1), to_factor(levels=c('A', 'E'), labels=c('american', 'european'))),
    field('data_vencimento', 'Data de vencimento', width(8), to_date('%Y%m%d')),
    field('preco_exercicio', 'Preço de exercício', width(15), to_numeric(dec='num_casas_decimais')),
    field('premio_referencia', 'Prêmio de referência', width(15), to_numeric(dec='num_casas_decimais')),
    field('num_casas_decimais', 'Número de casas decimais', width(1))
  )
})

MarketData$register(Premio)
