
ContrCad <- MarketDataFWF$proto(expr={
  id <- 'CONTRCAD'
  filename <- 'CONTRCAD.TXT'
  description <- 'Contratos Cadastrados'

  parser <- transmute::transmuter(
    transmute::match_regex('^(S|N)$', function(text, match) {
      text == 'S'
    }),
    NUMERIC.TRANSMUTER
  )

  fields <- fields(
    field('id_transacao', 'Identificação da Transação', width(6)),
    field('compl_transacao', 'Complemento da Transação', width(3)),
    field('tipo_registros', 'Tipo de Registro', width(2)),
    field('data_referencia', 'Data de Referência', width(8), to_date(format='%Y%m%d')),
    field('cod_mercadoria', 'Código da Mercadoria', width(3), to_factor()),
    field('tipo_mercado', 'Tipo de Mercado', width(1), to_factor(levels=1:5, labels=c('spot', 'future', 'option-on-spot', 'option-on-future', 'forward'))),
    field('serie', 'Série (Opções) / Vencimento (Futuro)', width(4)),
    field('tipo_opcao', 'Tipo de Opção', width(1), to_factor(levels=c('C', 'V'), labels=c('call', 'put'))),
    field('tipo_exercicio', 'Tipo de exercício', width(1), to_factor(levels=c('A', 'E'), labels=c('american', 'european'))),
    field('data_vencimento', 'Data de Vencimento do Contrato', width(8), to_date(format='%Y%m%d')),
    field('data_inicio_negociacao', 'Data de Inicio de Negociação', width(8), to_date(format='%Y%m%d')),
    field('data_inicio_exercicio', 'Data de Inicio de Exercício', width(8), to_date(format='%Y%m%d')),
    field('data_limite_negociacao', 'Data Limite de Negociação', width(8), to_date(format='%Y%m%d')),
    field('data_limite_abertura_posicoes', 'Data Limite de Abertura de Posições', width(8), to_date(format='%Y%m%d')),
    field('preco_exercicio', 'Preço de Exercício (Opções)', width(15), to_numeric(dec='num_casas_decimais')),
    field('num_casas_decimais', 'Número de Casas Decimais', width(1)),
    field('cod_viva_vaz', 'Código de Negociação Viva-Voz', width(20)),
    field('cod_gts', 'Código de Negociação GTS', width(20)),
    field('cod_isin', 'Código ISIN', width(12)),
    field('contr_objeto_vencimento', 'Contrato Objeto (no Vencimento)', width(4)),
    field('tipo_cotacao', 'Tipo de Cotação', width(1), to_factor(levels=1:2, labels=c('price', 'rate'))),
    field('tipo_mercadoria', 'Tipo de Mercadoria', width(1), to_factor(levels=1:3, labels=c('money', 'agro', 'energy'))),
    field('variacao_minima', 'Variação Mínima de Apregoação', width(15), to_numeric(dec='num_casas_decimais')),
    field('indicador_opcao_ajuste', 'Indicador de Opção com Ajuste', width(1)),
    field('indicador_mercadoria_internacional', 'Indicador de Mercadoria Internacional', width(1)),
    field('cod_moeda', 'Código da Moeda', width(2), to_factor(levels=1:2, labels=c('USD', 'BRL'))),
    field('indicador_operacao_estruturada', 'Indicador de Operação Estruturada', width(1)),
    field('num_dias_saques', 'Quantidade de dias Saques', width(5)),
    field('num_dias_corridos', 'Quantidade de dias Corridos', width(5)),
    field('num_dias_uteis', 'Quantidade de dias Úteis', width(5)),
    field('descricao_mercadoria', 'Descrição da mercadoria', width(15))
  )
})

ContrCadIPN <- ContrCad$proto(filename='CONTRCAD-IPN.TXT', description = 'Contratos Cadastrados Nova Clearing')

MarketData$register(ContrCad)
MarketData$register(ContrCadIPN)

