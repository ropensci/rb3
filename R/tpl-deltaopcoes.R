
DeltaOpcoes <- MarketDataFWF$proto(expr={
  filename <- 'DeltaOpcoes.txt'

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
    field('data_pregao', 'Data de Pregão', width(8), to_date('%Y%m%d')),
    field('cod_mercadoria', 'Código da Mercadoria', width(3)),
    field('tipo_mercado', 'Tipo de Mercado', width(1), to_factor(levels=1:5, labels=c('spot', 'future', 'options on spot', 'options on future', 'forward'))),
    field('serie', 'Série do Contrato', width(4)),
    field('data_vencimento', 'Data de Vencimento do Contrato', width(8)),
    field('cod_gts', 'Código de Negociação do GTS', width(20)),
    field('tipo_opcao', 'Tipo de Opção', width(1), to_factor(levels=c('C', 'V'), labels=c('call', 'put'))),
    field('tipo_exercicio', 'Tipo de exercício', width(1), to_factor(levels=c('A', 'E'), labels=c('american', 'european'))),
    field('indicador_opcao_ajuste', 'Indicador de Opção com Ajuste', width(1), to_factor()),
    field('cod_moeda', 'Código da Moeda', width(2), to_numeric()),
    field('preco_exercicio', 'Preço de Exercício', width(15), to_numeric(dec=3)),
    field('valor_volatilidade', 'Valor da Volatilidade', width(19), to_numeric(dec=7)),
    field('sinal_delta', 'Sinal do Valor do Delta', width(1)),
    field('valor_delta', 'Valor do Delta', width(19), to_numeric(dec=7, sign='sinal_delta'))
  )
})

MarketData$register(DeltaOpcoes)
