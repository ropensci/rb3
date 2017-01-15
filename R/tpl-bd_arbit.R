

BD_Arbit <- MarketDataFWF$proto(expr={
  id <- 'BD_Arbit'
  filename <- 'BD_Arbit.txt'

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
    field('id_transacao', 'Identificação da transação', width(6), to_numeric()),
    field('compl_transacao', 'Complemento da transação', width(3), to_numeric()),
    field('tipo_registro', 'Tipo de registro', width(2), to_numeric()),
    field('data_geracao_arquivo', 'Data de geração do arquivo', width(8), to_date(format='%Y%m%d')),
    field('tipo_negociacao', 'Tipo de negociação', width(2), to_factor(levels='PR', labels='Pregão')),
    field('cod_mercadoria', 'Código da mercadoria', width(3)),
    field('cod_mercado', 'Código do mercado', width(1)),
    field('tipo_serie', 'Tipo da série', width(1), to_factor(levels=c('C', 'V', '*'), labels=c('call', 'put', 'future'))),
    field('serie', 'Série (opç)/vencimento (fut)', width(4), to_factor()),
    field('hora_criacao_registro', 'Hora de criação deste registro', width(6), to_time(format='%H%M%S')),
    field('data_vencimento', 'Data de vencimento (fut/opç)', width(8), to_date(format='%Y%m%d')),
    field('preco_exercicio', 'Preço de exercício (opç)', width(13), to_numeric(dec='num_casas_decimais')),
    field('tamanho_contr', 'Valor do ponto ou tamanho do contrato', width(13), to_numeric(dec=7)),
    field('volume_real', 'Volume do dia em R$', width(13), to_numeric()),
    field('volume_dolar', 'Volume do dia em US$', width(13), to_numeric()),
    field('qtd_contr_aberto', 'Qtd. de contratos em aberto', width(8)),
    field('qtd_negocios', 'Qtd. de negócios efetuados no dia', width(8)),
    field('qtd_contr', 'Qtd. de contratos negociados no dia', width(8)),
    field('qtd_contr_ult_compra', 'Qtd. de contratos da última oferta compra do dia', width(5)),
    field('sinal_ult_oferta_compra', 'Sinal da cot.da última oferta de compra do dia', width(1)),
    field('cot_ult_oferta_compra', 'Cotação da última oferta de compra do dia', width(8), to_numeric(dec='num_casas_decimais', sign='sinal_ult_oferta_compra')),
    field('qtd_contr_ult_oferta_compra', 'Qtd. de contratos da última oferta de venda do dia', width(5)),
    field('sinal_ult_oferta_venda', 'Sinal da cot.da última oferta de venda do dia', width(1)),
    field('cot_ult_oferta_venda', 'Cotação da última oferta de venda do dia', width(8), to_numeric(dec='num_casas_decimais', sign='sinal_ult_oferta_venda')),
    field('sinal_cot_primeiro_negocio', 'Sinal da cotação do primeiro negócio do dia', width(1)),
    field('cot_primeiro_negocio', 'Cotação do primeiro negócio do dia', width(8), to_numeric(dec='num_casas_decimais', sign='sinal_cot_primeiro_negocio')),
    field('sinal_cot_menor_negocio', 'Sinal da cotação do menor negócio do dia', width(1)),
    field('cot_menor_negocio', 'Cotação do menor negócio do dia', width(8), to_numeric(dec='num_casas_decimais', sign='sinal_cot_menor_negocio')),
    field('sinal_cot_maior_negocio', 'Sinal da cotação do maior negócio do dia', width(1)),
    field('cot_maior_negocio', 'Cotação do maior negócio do dia', width(8), to_numeric(dec='num_casas_decimais', sign='sinal_cot_maior_negocio')),
    field('sinal_cot_med_negocios', 'Sinal da cotação média dos negócios do dia', width(1)),
    field('cot_med_negocios', 'Cotação média dos negócios do dia', width(8), to_numeric(dec='num_casas_decimais', sign='sinal_cot_med_negocios')),
    field('qtd_contr_ult_negocio', 'Qtd. de contratos do último negócio do dia', width(5)),
    field('sinal_cot_ult_negocio', 'Sinal da cotação do último negócio do dia', width(1)),
    field('cot_ult_negocio', 'Cotação do último negócio do dia', width(8), to_numeric(dec='num_casas_decimais', sign='sinal_cot_ult_negocio')),
    field('hora_ult_negocio', 'Hora do último negócio do dia', width(6), to_time(format='%H%M%S')),
    field('data_ult_negocio', 'Data do último negócio', width(8), to_date(format='%Y%m%d')),
    field('sinal_cot_ult_negocio_anterior', 'Sinal da cotação do último negócio anterior', width(1)),
    field('cot_ult_negocio_anterior', 'Cotação do último negócio anterior', width(8), to_numeric(dec='num_casas_decimais', sign='sinal_cot_ult_negocio_anterior')),
    field('sinal_cot_fechamento', 'Sinal da cotação de fechamento do dia', width(1)),
    field('cot_fechamento', 'Cotação de fechamento do dia', width(8), to_numeric(dec='num_casas_decimais', sign='sinal_cot_fechamento')),
    field('sinal_cot_ajuste', 'Sinal da cotação ajuste (fut)', width(1)),
    field('cot_ajuste', 'Cotação ajuste (fut)', width(13), to_numeric(dec='num_casas_decimais', sign='sinal_cot_ajuste')),
    field('situacao_ajuste', 'Situação do ajuste do dia', width(1), to_factor(levels=c('S', 'A'), labels=c('Ajuste Final', 'Ajuste Corrigido'))),
    field('sinal_cot_ajuste_anterior', 'Sinal da cotação de ajuste do dia anterior (fut)', width(1)),
    field('cot_ajuste_anterior', 'Cotação de ajuste do dia anterior (fut)', width(13), to_numeric(dec='num_casas_decimais', sign='sinal_cot_ajuste_anterior')),
    field('situacao_ajuste_anterior', 'Situação do ajuste do dia anterior', width(1), to_factor(levels=c('S', 'A'), labels=c('Ajuste Final', 'Ajuste Corrigido'))),
    field('valor_ajuste_contr', 'Valor do ajuste por contrato', width(13), to_numeric(dec=2)),
    field('volume_exercido_real', 'Volume exercido no dia em R$', width(13), to_numeric()),
    field('volume_exercido_dolar', 'Volume exercido no dia em US$', width(13), to_numeric()),
    field('qtd_negocios_exercidos', 'Quantidade de negócios exercidos no dia', width(8)),
    field('qtd_contr_exercidos', 'Quantidade de contratos exercidos no dia', width(8)),
    field('num_casas_decimais_2', 'Número de casas decimais dos campos com *', width(1)),
    field('num_casas_decimais', 'Número de casas decimais dos ajustes', width(1)),
    field('perc_oscilacao', 'Percentual de oscilação', width(8), to_numeric(dec=1)),
    field('sinal_oscilacao', 'Sinal da oscilação', width(1)),
    field('valor_diferenca', 'Valor da diferença (variação em pontos)', width(8)),
    field('sinal_diferenca', 'Sinal da diferença (variação em pontos)', width(1)),
    field('valor_equivalencia', 'Valor da equivalência', width(8), to_numeric(dec=2)),
    field('valor_dolar_anterior', 'Valor do dólar do dia anterior', width(13), to_numeric(dec=7)),
    field('valor_dolar', 'Valor do dólar do dia atual', width(13), to_numeric(dec=7)),
    field('valor_delta', 'Valor do delta da opção (margem)', width(9), to_numeric(dec=7)),
    field('num_dias_saques', 'Qtd. saques até data de vencimento', width(5), to_numeric()),
    field('num_dias_corridos', 'Qtd. dias corridos até data de vencimento', width(5), to_numeric()),
    field('num_dias_uteis', 'Qtd. dias úteis até data de vencimento', width(5), to_numeric()),
    field('data_vencimento_objeto', 'Vencimento do contrato-objeto', width(4), to_factor()),
    field('margem_clientes', 'Margem para clientes normais', width(13), to_numeric(dec=2)),
    field('margem_hedgers', 'Margem para clientes hedgers', width(13), to_numeric(dec=2)),
    field('data_inicio_entrega', 'Data de início do período de entrega (agrícolas)', width(8), to_date(format='%Y%m%d')),
    field('sequencia_vencimento', 'Seqüência do vencimento futuro', width(3)),
    field('cod_viva_voz', 'Código de negociação viva voz', width(20)),
    field('cod_gts', 'Código de negociação GTS', width(20)),
    field('canais_negociacao', 'Canais de negociação permitidos', width(1), to_factor(levels=c('V', 'E', 'A'), labels=c('Viva-Voz', 'Eletrônico', 'Ambos'))),
    field('ref_negocios', 'Referência deste resumo de negócios', width(4), to_factor(levels='MERC')),
    field('data_limite_negociacao', 'Data-limite para negociação', width(8), to_date(format='%Y%m%d')),
    field('data_liquidacao_financeira', 'Data de liquidação financeira', width(8), to_date(format='%Y%m%d')),
    field('sinal_limite_min_negociacao', 'Sinal do limite mínimo para negociação', width(1)),
    field('limite_min_negociacao', 'Limite mínimo para negociação (fut)', width(13)),
    field('sinal_limite_max_negociacao', 'Sinal do limite máximo para negociação', width(1)),
    field('limite_max_negociacao', 'Limite máximo para negociação (fut)', width(13))
  )
})

BDPrevia <- BD_Arbit$proto(filename='BDPrevia.txt')
BDAtual <- BD_Arbit$proto(filename='BDAtual.txt')
BDAjuste <- BD_Arbit$proto(filename='BDAjuste.txt')
BDAfterHour <- BD_Arbit$proto(filename='BDAfterHour.txt')
BD_Final <- BD_Arbit$proto(filename='BD_Final.txt')

MarketData$register(BD_Arbit)
MarketData$register(BDPrevia)
MarketData$register(BDAtual)
MarketData$register(BDAjuste)
MarketData$register(BDAfterHour)
MarketData$register(BD_Final)
