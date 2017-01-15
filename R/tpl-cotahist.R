

COTAHIST <- MarketDataMultiPartFWF$proto(expr = {
  id <- 'COTAHIST'
  filename <- 'COTAHIST'

  parts <- list(
    'Header' = list(
      pattern = '^00',
      fields = fields(
        field('tipo_registro', 'Tipo de registro', width(2)),
        field('nome_arquivo', 'Nome do arquivo', width(13)),
        field('cod_origem', 'Código da origem', width(8)),
        field('data_geracao_arquivo', 'Data de geração do arquivo', width(8), to_date('%Y%m%d')),
        field('reserva', 'Reserva', width(214))
      )
    ),
    'Cotações históricas por papel-mercado' = list(
      pattern = '^01',
      fields = fields(
        field('tipo_registro', 'Tipo de registro', width(2)),
        field('data_referencia', 'Data do pregão', width(8), to_date('%Y%m%d')),
        field('cod_bdi', 'Código BDI', width(2)),
        field('cod_negociacao', 'Código de negociação do papel', width(12)),
        field('tipo_mercado', 'Tipo de mercado', width(3)),
        field('nome_empresa', 'Nome resumido da empresa emissora do papel', width(12)),
        field('especificacao', 'Especificação do papel', width(10)),
        field('num_dias_mercado_termo', 'Prazo em dias do mercado a termo', width(3)),
        field('cod_moeda', 'Moeda de referência', width(4)),
        field('preco_abertura', 'Preço de abertura do papel', width(11), to_numeric(dec = 2)),
        field('preco_max', 'Preço máximo do papel', width(11), to_numeric(dec = 2)),
        field('preco_min', 'Preço mínimo do papel', width(11), to_numeric(dec = 2)),
        field('preco_med', 'Preço médio do papel', width(11), to_numeric(dec = 2)),
        field('preco_ult', 'Preço último negócio efetuado com o papel', width(11), to_numeric(dec = 2)),
        field('preco_melhor_oferta_compra', 'Preço da melhor oferta de compra do papel', width(11), to_numeric(dec = 2)),
        field('preco_melhor_oferta_venda', 'Preço da melhor oferta de venda do papel', width(11), to_numeric(dec = 2)),
        field('qtd_negocios', 'Número de negócios efetuados com o papel', width(5)),
        field('qtd_titulos_negociados', 'Quantidade total de títulos negociados neste papel', width(18)),
        field('volume_titulos_negociados', 'Volume total de títulos negociados neste papel', width(16), to_numeric(dec = 2)),
        field('preco_exercicio', 'Preço de exercício para o mercado de opções ou valor do contrato para o mercado de termo secundário', width(11), to_numeric(dec = 2)),
        field('indicador_correcao_preco_exercicio', 'Indicador de correção de preços de exercícios ou valores de contrato para os mercados de opções, termo secundário ou futuro', width(1)),
        field('data_vencimento', 'Data do vencimento para os mercados de opções, termo secundário ou futuro', width(8), to_date('%Y%m%d')),
        field('fator_cot', 'Fator de cotação do papel', width(7)),
        field('preco_exercicio_pontos', 'Preço de exercício em pontos para opções referenciadas em dólar ou valor de contrato em pontos para termo secundário', width(13), to_numeric(dec = 6)),
        field('cod_isin', 'Código do papel no sistema ISIN', width(12)),
        field('num_dist', 'Número de distribuição do papel', width(3))
      )
    ),
    "Trailer" = list(
      pattern = '^99',
      fields = fields(
        field('tipo_mercado', 'Tipo de registro', width(2)),
        field('nome_arquivo', 'Nome do arquivo', width(13)),
        field('cod_origem', 'Código da origem', width(8)),
        field('data_geracao_arquivo', 'Data da geração do arquivo', width(8), to_date('%Y%m%d')),
        field('num_registros', 'Total de registros', width(11)),
        field('reserva', 'Reserva', width(203))
      )
    )
  )
})

MarketData$register(COTAHIST)
