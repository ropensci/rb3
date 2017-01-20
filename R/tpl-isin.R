
ISIND <- MarketDataFWF$proto(expr={
  filename <- 'CodISIND.txt'
  id <- 'ISIND'
  description <- 'Relação de Códigos ISIN para Contratos Derivativos'

  fields <- fields(
    field('data_cadastro', 'Data de cadastro', width(8), to_date('%Y%m%d')),
    field('cod_mercadoria', 'Código da mercadoria', width(3)),
    field('tipo_mercado', 'Tipo de mercado', width(3)),
    field('serie', 'Vencimento/série/prazo', width(4)),
    field('cod_isin', 'Código ISIN', width(12))
  )
})

MarketData$register(ISIND)

ISINS <- MarketDataFWF$proto(expr={
  filename <- 'CodISINS.txt'
  id <- 'ISINS'
  description <- 'Relação de Códigos ISIN para Contratos de Swap'

  fields <- fields(
    field('data_cadastro', 'Data de cadastro', width(8), to_date('%Y%m%d')),
    field('contrato', 'Contrato', width(5)),
    field('nome_contr', 'Nome do contrato', width(50)),
    field('cod_isin', 'Código ISIN', width(12))
  )
})

MarketData$register(ISINS)

