
SupVol <- MarketDataMultiPartCSV$proto(expr={
  filename <- 'SupVol.txt'
  separator <- ';'

  parts <- list(
    'Cabeçalho'=list(
      lines=1,
      fields=fields(
        field('data_geracao_arquivo', 'Data de geração do arquivo', to_date('%Y%m%d')),
        field('id_arquivo', 'Identificação do arquivo')
      )
    ),
    'Corpo'=list(
      lines=-1,
      fields=fields(
        field('cod_curva_volatilidade', 'Código da Curva de Volatilidade'),
        field('descricao_curva_volatilidade', 'Descrição da Curva de Volatilidade'),
        field('num_dias_saque', 'Prazo (dias de Saque)'),
        field('num_dias_corridos', 'Prazo (dias Corridos)'),
        field('valor_volatilidade', 'Valor da volatilidade', to_numeric(dec=7))
      )
    )
  )
})

MarketData$register(SupVol)

