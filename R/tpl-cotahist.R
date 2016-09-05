

COTAHIST <- MarketDataMultiPartFWF$proto(expr = {
  filename <- 'COTAHIST'

  parts <- list(
    'Header' = list(
      pattern = '^00',
      fields = fields(
        field('Tipo de registro', width(2)),
        field('Nome do arquivo', width(13)),
        field('Código da origem', width(8)),
        field('Data de geração do arquivo', width(8), to_date('%Y%m%d')),
        field('Reserva', width(214))
      )
    ),
    'Cotações históricas por papel-mercado' = list(
      pattern = '^01',
      fields = fields(
        field('Tipo de registro', width(2)),
        field('Data do pregão', width(8), to_date('%Y%m%d')),
        field('Código BDI', width(2)),
        field('Código de negociação do papel', width(12)),
        field('Tipo de mercado', width(3)),
        field('Nome resumido da empresa emissora do papel', width(12)),
        field('Especificação do papel', width(10)),
        field('Prazo em dias do mercado a termo', width(3)),
        field('Moeda de referência', width(4)),
        field('Preço de abertura do papel', width(11), to_numeric(dec = 2)),
        field('Preço máximo do papel', width(11), to_numeric(dec = 2)),
        field('Preço mínimo do papel', width(11), to_numeric(dec = 2)),
        field('Preço médio do papel', width(11), to_numeric(dec = 2)),
        field(
          'Preço último negócio efetuado com o papel',
          width(11),
          to_numeric(dec = 2)
        ),
        field(
          'Preço da melhor oferta de compra do papel',
          width(11),
          to_numeric(dec = 2)
        ),
        field(
          'Preço da melhor oferta de venda do papel',
          width(11),
          to_numeric(dec = 2)
        ),
        field('Número de negócios efetuados com o papel', width(5)),
        field('Quantidade total de títulos negociados neste papel', width(18)),
        field(
          'Volume total de títulos negociados neste papel',
          width(16),
          to_numeric(dec = 2)
        ),
        field(
          'Preço de exercício para o mercado de opções ou valor do contrato para o mercado de termo secundário',
          width(11),
          to_numeric(dec = 2)
        ),
        field(
          'Indicador de correção de preços de exercícios ou valores de contrato para os mercados de opções, termo secundário ou futuro',
          width(1)
        ),
        field(
          'Data do vencimento para os mercados de opções, termo secundário ou futuro',
          width(8),
          to_date('%Y%m%d')
        ),
        field('Fator de cotação do papel', width(7)),
        field(
          'Preço de exercício em pontos para opções referenciadas em dólar ou valor de contrato em pontos para termo secundário',
          width(13),
          to_numeric(dec = 6)
        ),
        field('Código do papel no sistema ISIN', width(12)),
        field('Número de distribuição do papel', width(3))
      )
    ),
    "Trailer" = list(
      pattern = '^99',
      fields = fields(
        field('Tipo de registro', width(2)),
        field('Nome do arquivo', width(13)),
        field('Código da origem', width(8)),
        field('Data da geração do arquivo', width(8), to_date('%Y%m%d')),
        field('Total de registros', width(11)),
        field('Reserva', width(203))
      )
    )
  )
})

MarketData$register(COTAHIST)
