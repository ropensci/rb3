
Indic <- MarketDataFWF$proto(expr={
  id <- 'Indic'
  filename <- 'Indic.txt'

  parser <- transmute::transmuter(
    transmute::match_regex('^\\+\\d+$', as.numeric, priority=1),
    NUMERIC.TRANSMUTER
  )

  fields <- fields(
    field('id_transacao', 'Identificação da transação', width(6), to_numeric()),
    field('compl_transacao', 'Complemento da transação', width(3), to_numeric()),
    field('tipo_registro', 'Tipo de registro', width(2), to_numeric()),
    field('data_geracao_arquivo', 'Data de geração do arquivo', width(8), to_date(format='%Y%m%d')),
    field('grupo_indicador', 'Grupo do indicador', width(2), to_factor(levels=c('IA', 'DE', 'RT', 'BV', 'ME', 'ID'), labels=c('indicadores-agro', 'titulos-divida-externa', 'indicadores-gerais', 'ibovespa', 'moeda-estrangeira', 'indice-idi'))),
    field('cod_indicador', 'Código do indicador', width(25)),
    field('valor_indicador', 'Valor do indicador na data', width(25), to_numeric(dec='num_casas_decimais')),
    field('num_casas_decimais', 'Número de decimais do valor', width(2), to_numeric()),
    field('reserva', 'Filler', width(36))
  )
})

Indica <- Indic$proto(filename='Indica.txt')

MarketData$register(Indic)
MarketData$register(Indica)

