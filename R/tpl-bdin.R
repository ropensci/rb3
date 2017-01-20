
BDIN <- MarketDataMultiPartFWF$proto(expr={
  id <- 'BDIN'
  filename <- 'BDIN'
  description <- 'Cotações do Horário Regular do Pregão de Ações'

  parts <- list(
    'Header'=list(
      pattern='^00',
      fields=fields(
        field('tipo_registro', 'Tipo de registro', width(2)),
        field('cod_arquivo', 'Código do arquivo', width(4)),
        field('cod_usuario', 'Código do usuário', width(4)),
        field('cod_origem', 'Código da origem', width(8)),
        field('cod_destino', 'Código do destino', width(4)),
        field('data_geracao_arquivo', 'Data de geração do arquivo', width(8), to_date('%Y%m%d')),
        field('data_pregao', 'Data do pregão', width(8), to_date('%Y%m%d')),
        field('hora_geracao', 'Hora de geração', width(4), to_time(format='%H%M')),
        field('reserva', 'Reserva', width(308))
      )
    ),
    'Resumo Diário dos Índices'=list(
      pattern='^01',
      fields=fields(
        field('tipo_registro', 'Tipo de registro', width(2)),
        field('id_indice', 'Identificação do índice', width(2)),
        field('nome_indice', 'Nome do índice', width(30)),
        field('indice_abertura', 'Índice de abertura do pregão', width(6)),
        field('indice_min', 'Índice mínimo do pregão', width(6)),
        field('indice_max', 'Índice máximo do pregão', width(6)),
        field('indice_med', 'Índice da média aritmética dos índices do pregão', width(6)),
        field('indice_liquidacao', 'Índice para liquidação', width(6)),
        field('indice_max_ano', 'Índice máximo do ano', width(6)),
        field('data_indice_max_ano', 'Data do índice máximo do ano', width(8), to_date('%Y%m%d')),
        field('indice_min_ano', 'Índice mínimo do ano', width(6)),
        field('data_indice_min_ano', 'Data do índice mínimo do ano', width(8), to_date('%Y%m%d')),
        field('indice_fechamento', 'Índice de fechamento', width(6)),
        field('sinal_evolucao_perc_indice_fechamento', 'Sinal da evolução percentual do índice de fechamento', width(1)),
        field('evolucao_perc_indice_fechamento', 'Evolução percentual do índice de fechamento', width(5), to_numeric(dec=2)),
        field('sinal_evolucao_perc_indice_ontem', 'Sinal da evolução percentual do índice de ontem', width(1)),
        field('evolucao_perc_indice_ontem', 'Evolução percentual do índice de ontem', width(5), to_numeric(dec=2)),
        field('sinal_evolucao_perc_indice_semana', 'Sinal da evolução percentual do índice da semana', width(1)),
        field('evolucao_perc_indice_semana', 'Evolução percentual do índice da semana', width(5), to_numeric(dec=2)),
        field('sinal_evolucao_perc_indice_semanal', 'Sinal da evolução percentual do índice em uma semana', width(1)),
        field('evolucao_perc_indice_semanal', 'Evolução percentual do índice em uma semana', width(5), to_numeric(dec=2)),
        field('sinal_evolucao_perc_indice_mes', 'Sinal da evolução percentual do índice no mês', width(1)),
        field('evolucao_perc_indice_mes', 'Evolução percentual do índice no mês', width(5), to_numeric(dec=2)),
        field('sinal_evolucao_perc_indice_mensal', 'Sinal da evolução percentual do índice em um mês', width(1)),
        field('evolucao_perc_indice_mensal', 'Evolução percentual do índice em um mês', width(5), to_numeric(dec=2)),
        field('sinal_evolucao_perc_indice_ano', 'Sinal da evolução percentual do índice no ano', width(1)),
        field('evolucao_perc_indice_ano', 'Evolução percentual do índice no ano', width(5), to_numeric(dec=2)),
        field('sinal_evolucao_perc_indice_anual', 'Sinal da evolução percentual do índice em um ano', width(1)),
        field('evolucao_perc_indice_anual', 'Evolução percentual do índice em um ano', width(5), to_numeric(dec=2)),
        field('num_acoes_alta', 'Número de ações pertencentes ao índice que tiveram alta', width(3)),
        field('num_acoes_baixa', 'Número de ações pertencentes ao índice que tiveram baixa', width(3)),
        field('num_acoes_estaveis', 'Número de ações pertencentes ao índice que permaneceram estáveis', width(3)),
        field('num_acoes_indice', 'Número de total de ações pertencentes ao índice', width(3)),
        field('num_negocios_acoes_indice', 'Número de negócios com ações pertencentes ao índice', width(6)),
        field('qtd_negocios_acoes_indice', 'Quantidade de títulos negociados com ações pertencentes ao índice', width(15)),
        field('volume_negocios_acoes_indice', 'Volume dos negócios com ações pertencentes ao índice', width(17), to_numeric(dec=2)),
        field('indice_med_ponderada', 'Índice da média ponderada', width(6)),
        field('reserva', 'Reserva', width(148))
      )
    ),
    'Resumo Diário de Negociações por Papel'=list(
      pattern='^02',
      fields=fields(
        field('tipo_registro', 'Tipo de registro', width(2)),
        field('cod_bdi', 'Código BDI', width(2)),
        field('descricao_cod_bdi', 'Descrição do código de BDI', width(30)),
        field('nome_empresa', 'Nome resumido da empresa emissora do papel', width(12)),
        field('especificacao', 'Especificação do papel', width(10)),
        field('indicador_caracteristica', 'Indicador de característica do papel', width(1)),
        field('cod_negociacao', 'Código de negociação', width(12)),
        field('tipo_mercado', 'Tipo de mercado', width(3)),
        field('descricao_tipo_mercado', 'Descrição do tipo de mercado', width(15)),
        field('num_dias_mercado_termo', 'Prazo em dias do mercado a termo', width(3)),
        field('preco_abertura', 'Preço de abertura do papel', width(11), to_numeric(dec=2)),
        field('preco_max', 'Preço máximo do papel', width(11), to_numeric(dec=2)),
        field('preco_min', 'Preço mínimo do papel', width(11), to_numeric(dec=2)),
        field('preco_med', 'Preço médio do papel', width(11), to_numeric(dec=2)),
        field('preco_ult', 'Preço último negócio efetuado com o papel', width(11), to_numeric(dec=2)),
        field('sinal_oscilacao_preco', 'Sinal da oscilação do preço do papel em relação ao pregão anterior', width(1)),
        field('oscilacao_preco', 'Oscilação do preço do papel em relação ao pregão anterior', width(5), to_numeric(dec=2)),
        field('preco_melhor_oferta_compra', 'Preço da melhor oferta de compra do papel', width(11), to_numeric(dec=2)),
        field('preco_melhor_oferta_venda', 'Preço da melhor oferta de venda do papel', width(11), to_numeric(dec=2)),
        field('qtd_negocios', 'Número de negócios efetuados com o papel', width(5)),
        field('qtd_titulos_negociados', 'Quantidade total de títulos negociados neste papel', width(15)),
        field('volume_titulos_negociados', 'Volume total de títulos negociados neste papel', width(17), to_numeric(dec=2)),
        field('preco_exercicio', 'Preço de exercício para o mercado de opções ou valor do contrato para o mercado de termo secundário', width(11), to_numeric(dec=2)),
        field('data_vencimento', 'Data do vencimento para os mercados de opções, termo secundário ou futuro', width(8), to_date('%Y%m%d')),
        field('indicador_correcao_preco_exercicio', 'Indicador de correção de preços de exercícios ou valores de contrato para os mercados de opções, termo secundário ou futuro', width(1)),
        field('descricao_indicador_correcao_preco_exercicio', 'Descrição do indicador de correção de preços de exercícios ou valores de contrato para os mercados de opções, termo secundário ou futuro', width(15)),
        field('fator_cot', 'Fator de cotação do papel', width(7)),
        field('preco_exercicio_pontos', 'Preço de exercício em pontos para opções referenciadas em dólar ou valor de contrato em pontos para termo secundário', width(13), to_numeric(dec=6)),
        field('cod_isin', 'Código do papel no sistema ISIN', width(12)),
        field('num_dist', 'Número de distribuição do papel', width(3)),
        field('tipo_exercicio', 'Estilo adotado para o exercício de opções de compra/venda', width(1)),
        field('descricao_tipo_exercicio', 'Descrição do estilo', width(15)),
        field('indicador_correcao_preco_exercicio_2', 'Indicador de correção de preços de exercícios ou valores de contrato para os mercados de opções, termo secundário ou futuro 2', width(3)),
        field('oscilacao_preco_2', 'Oscilação do preço do papel em relação ao pregão anterior 2', width(7), to_numeric(dec=2)),
        field('reserva', 'Reserva', width(44))
      )
    ),
    'Resumo Diário de Negociações por Código BDI'=list(
      pattern='^03',
      fields=fields(
        field('tipo_registro', 'Tipo de registro', width(2)),
        field('cod_bdi', 'Código BDI', width(2)),
        field('descricao_cod_bdi', 'Descrição do código de BDI', width(30)),
        field('qtd_negocios', 'Número de negócios efetuados no pregão corrente', width(5)),
        field('qtd_titulos_negociados', 'Quantidade total de títulos negociados', width(15)),
        field('volume_titulos_negociados', 'Volume geral transacionado no pregão corrente', width(15), to_numeric(dec=2)),
        field('qtd_negocios_2', 'Número de negócios efetuados no pregão corrente 2', width(9)),
        field('reserva', 'Reserva', width(270))
      )
    ),
    'Maiores Oscilações do Mercado a Vista'=list(
      pattern='^04',
      fields=fields(
        field('tipo_registro', 'Tipo de registro', width(2)),
        field('sinal_oscilacao', 'Indica se é oscilação positiva ou negativa', width(1), to_factor(levels=c('A', 'B'), labels=c('ALTA (POSITIVA)', 'BAIXA (NEGATIVA)'))),
        field('nome_empresa', 'Nome resumido da empresa emissora do papel', width(12)),
        field('especificacao', 'Especificação do papel', width(10)),
        field('preco_ult', 'Preço último negócio efetuado com o papel-mercado durante o pregão corrente', width(11), to_numeric(dec=2)),
        field('qtd_negocios', 'Número negócios efetuados com o papel-mercado durante o pregão corrente', width(5)),
        field('oscilacao_preco', 'Oscilação do preço do papel-mercado em relação ao pregão anterior', width(5), to_numeric(dec=2)),
        field('cod_negociacao', 'Código de negociação', width(12)),
        field('oscilacao_preco_2', 'Oscilação do preço do papel-mercado em relação ao pregão anterior 2', width(7), to_numeric(dec=2)),
        field('reserva', 'Reserva', width(285))
      )
    ),
    'Maiores Oscilação das Ações do IBOVESPA'=list(
      pattern='^05',
      fields=fields(
        field('tipo_registro', 'Tipo de registro', width(2)),
        field('sinal_oscilacao', 'Indica se é oscilação positiva ou negativa', width(1), to_factor(levels=c('A', 'B'), labels=c('ALTA (POSITIVA)', 'BAIXA (NEGATIVA)'))),
        field('nome_empresa', 'Nome resumido da empresa emissora do papel', width(12)),
        field('especificacao', 'Especificação do papel', width(10)),
        field('preco_ult', 'Preço último negócio efetuado com o papel-mercado durante o pregão corrente', width(11), to_numeric(dec=2)),
        field('qtd_negocios', 'Número negócios efetuados com o papel-mercado durante o pregão corrente', width(5)),
        field('oscilacao_preco', 'Oscilação do preço do papel-mercado em relação ao pregão anterior', width(5), to_numeric(dec=2)),
        field('cod_negociacao', 'Código de negociação', width(12)),
        field('oscilacao_preco_2', 'Oscilação do preço do papel-mercado em relação ao pregão anterior 2', width(7), to_numeric(dec=2)),
        field('reserva', 'Reserva', width(285))
      )
    ),
    'As Mais Negociadas no Mercado a Vista'=list(
      pattern='^06',
      fields=fields(
        field('tipo_registro', 'Tipo de registro', width(2)),
        field('nome_empresa', 'Nome resumido da empresa emissora do papel', width(12)),
        field('especificacao', 'Especificação do papel', width(10)),
        field('qtd_titulos_negociados', 'Quantidade de títulos negociados no pregão', width(15)),
        field('volume_titulos_negociados', 'Volume geral no pregão deste papel-mercado', width(17), to_numeric(dec=2)),
        field('cod_negociacao', 'Código de negociação', width(12)),
        field('reserva', 'Reserva', width(282))
      )
    ),
    'As Mais Negociadas'=list(
      pattern='^07',
      fields=fields(
        field('tipo_registro', 'Tipo de registro', width(2)),
        field('tipo_mercado', 'Tipo de mercado', width(3)),
        field('descricao_tipo_mercado', 'Descrição do tipo de mercado', width(20)),
        field('nome_empresa', 'Nome resumido da empresa emissora do papel', width(12)),
        field('especificacao', 'Especificação do papel', width(10)),
        field('indicador_correcao_preco_exercicio', 'Indicador de correção de preços de exercícios ou valores de contrato para os mercados de opções, termo secundário ou futuro, respectivamente', width(2)),
        field('descricao_indicador_correcao_preco_exercicio', 'Descrição do indicador de correção de preços de exercícios ou valores de contrato para os mercados de opções, termo secundário ou futuro, respectivamente', width(15)),
        field('preco_exercicio', 'Preço de exercício para o mercado de opções ou valor de contrato para os mercados de termo secundário', width(11), to_numeric(dec=2)),
        field('data_vencimento', 'Data do vencimento para os mercados de opções, termo secundário ou futuro', width(8), to_date('%Y%m%d')),
        field('num_dias_mercado_termo', 'Prazo em dias do mercado a termo', width(3)),
        field('qtd_titulos_negociados', 'Quantidade de títulos negociados no pregão', width(15)),
        field('volume_titulos_negociados', 'Volume geral no pregão deste papel mercado', width(17), to_numeric(dec=2)),
        field('participacao_volume_mercado', 'Participação do volume do papel no volume total do mercado', width(5), to_numeric(dec=2)),
        field('cod_negociacao', 'Código de negociação', width(12)),
        field('indicador_correcao_preco', 'Indicador de correção de preços de ativos', width(3)),
        field('reserva', 'Reserva', width(212))
      )
    ),
    "Resumo Diário dos IOPV's"=list(
      pattern='^08',
      fields=fields(
        field('tipo_registro', 'Tipo de registro', width(2)),
        field('id_iopv', 'Identificação do IOPV', width(2)),
        field('sigla_iopv', 'Sigla do IOPV', width(4)),
        field('nome_resumido_iopv', 'Nome resumido do IOPV', width(12)),
        field('nome_iopv', 'Nome do IOPV', width(30)),
        field('iopv_abertura', 'IOPV de abertura do pregão', width(7), to_numeric(dec=2)),
        field('iopv_min', 'IOPV mínimo do pregão', width(7), to_numeric(dec=2)),
        field('iopv_max', 'IOPV máximo do pregão', width(7), to_numeric(dec=2)),
        field('iopv_med', "IOPV da média aritmética dos IOPV's do pregão", width(7), to_numeric(dec=2)),
        field('iopv_fechamento', 'IOPV de fechamento', width(7), to_numeric(dec=2)),
        field('sinal_evolucao_iopv_fechamento', 'Sinal da evolução percentual do IOPV de fechamento', width(1)),
        field('evolucao_iopv_fechamento', 'Evolução percentual do IOPV de fechamento', width(5), to_numeric(dec=2)),
        field('reserva', 'Reserva', width(259))
      )
    ),
    "BDR's Não Patrocinadas - Valor de Referência"=list(
      pattern='^09',
      fields=fields(
        field('tipo_registro', 'Tipo de registro', width(2)),
        field('cod_negociacao', 'Código de negociação', width(15)),
        field('nome_empresa', 'Nome resumido da empresa emissora do papel', width(12)),
        field('especificacao', 'Especificação do papel', width(10)),
        field('valor_referencia', 'Valor de referência', width(11), to_numeric(dec=2)),
        field('reserva', 'Reserva', width(303))
      )
    ),
    "Trailer"=list(
      pattern='^99',
      fields=fields(
        field('tipo_registro', 'Tipo de registro', width(2)),
        field('cod_arquivo', 'Código do arquivo', width(4)),
        field('cod_usuario', 'Código do usuário', width(4)),
        field('cod_origem', 'Código da origem', width(8)),
        field('cod_destino', 'Código do destino', width(4)),
        field('data_geracao_arquivo', 'Data da geração do arquivo', width(8), to_date('%Y%m%d')),
        field('num_registros', 'Total de registros', width(9)),
        field('reserva', 'Reserva', width(311))
      )
    )
  )
})

MarketData$register(BDIN)

