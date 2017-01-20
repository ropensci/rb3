
Eletro <- MarketDataFWF$proto(expr={
  id <- 'Eletro'
  filename <- 'Eletro.txt'
  description <- 'Negócios Realizados no Mercado de Balcão'

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
    field('id_transacao', "Identificação da transação", width(6)),
    field('compl_transacao', "Complemento da transação", width(3)),
    field('tipo_registro', "Tipo de tegistro", width(2)),
    field('data_geracao_arquivo', "Data de geração do arquivo", width(8), to_date('%Y%m%d')),
    field('tipo_negociacao', "Tipo de negociação", width(2), to_factor(levels=c('SW', 'AG', 'TO'), labels=c('swaps', 'teleagro', 'teleouro'))),
    field('cod_mercadoria', "Código da mercadoria", width(3)),
    field('cod_mercado', "Código do mercado", width(1)),
    field('data_referencia', "Data-base", width(8), to_date('%Y%m%d')),
    field('data_vencimento', "Data de vencimento", width(8), to_date('%Y%m%d')),
    field('volume_real', "Volume do dia em R$", width(13)),
    field('volume_dolar', "Volume do dia em US$", width(13)),
    field('qtd_contr_abertos_apos_liquidacao', "Qtd. contratos em aberto após liquidação", width(8)),
    field('qtd_negocios', "Qtd. de negócios efetuados", width(8)),
    field('qtd_contr_negociados', "Qtd. de contratos negociados", width(8)),
    field('qtd_contr_abertos_antes_liquidacao', "Qtd. de contratos aberto antes da liquidação", width(8)),
    field('qtd_contr_liquidados', "Qtd. de contratos liquidados", width(8)),
    field('qtd_contr_aberto_final', "Qtd. de contratos aberto final", width(8)),
    field('valor_medio', "Taxa média (swp)/prêmio médio (opç flex)", width(9), to_numeric(dec=4)),
    field('sinal_valor_medio', "Sinal da taxa média/prêmio médio", width(1)),
    field('tipo_valor_medio', "Tipo de taxa média", width(1), to_factor(levels=c('D', 'P'), labels=c('daily', 'period'))),
    field('preco_exercicio_medio', "Preço de exercício médio (opç flex)", width(22), to_numeric(dec=7)),
    field('sinal_preco_exercicio_medio', "Sinal do preço médio de exercício", width(1)),
    field('volume_aberto_real', "Volume aberto em R$", width(13)),
    field('volume_aberto_dolar', "Volume aberto em US$", width(13))
  )
})

MarketData$register(Eletro)
