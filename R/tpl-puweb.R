
PUWEB <- MarketDataMultiPartCSV$proto(expr={
  id <- 'PUWEB'
  filename <- 'PUWEB.TXT'
  separator <- ';'

  parts <- list(
    'Cabeçalho'=list(
      pattern='^01',
      fields=fields(
        field('tipo_registro', 'Tipo de registro'),
        field('data_geracao_arquivo', 'Data de geração do arquivo', to_date('%Y%m%d')),
        field('nome_arquivo', 'Nome do arquivo')
      )
    ),
    'Corpo'=list(
      pattern='^02',
      fields=fields(
        field('tipo_registro', 'Tipo de registro'),
        field('cod_titulo', 'Código do título'),
        field('desc_titulo', 'Descrição do título', to_factor(
          levels=c('LTN', 'NTN-F', 'LFT', 'NTNB', 'NTNC', 'NTN-A3'),
          labels=c('LTN', 'NTNF', 'LFT', 'NTNB', 'NTNC', 'NTNA3')
        )),
        field('data_emissao', 'Data de emissão do título', to_date('%Y%m%d')),
        field('data_vencimento', 'Data de vencimento do título', to_date('%Y%m%d')),
        field('valor_mercado', 'Valor de mercado em PU'),
        field('valor_estressado', 'Valor do PU em cenário de estresse'),
        field('valor_mercado_d1', 'Valor de mercado em PU para D+1')
      )
    )
  )
})

MarketData$register(PUWEB)

