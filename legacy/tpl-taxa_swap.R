

TaxaSwap <- MarketDataFWF$proto(expr = {
  id <- "TaxaSwap"
  filename <- "TaxaSwap.txt"
  description <- "Taxas de Mercado para Swaps"

  parser <- transmuter(
    match_regex("\\+|-", function(text, match) {
      idx <- text == "-"
      x <- rep(1, length(text))
      x[idx] <- -1
      x
    }),
    NUMERIC.TRANSMUTER
  )

  fields <- fields(
    field("id_transacao", "Identificação da transação", width(6)),
    field("compl_transacao", "Complemento da transação", width(3)),
    field("tipo_registro", "Tipo de registro", width(2)),
    field("data_geracao_arquivo", "Data de geração do arquivo", width(8), to_date("%Y%m%d")),
    field("cod_curvas", "Código das curvas a termo", width(2), to_factor()),
    field("cod_taxa", "Código da taxa", width(5), to_factor()),
    field("desc_taxa", "Descrição da taxa", width(15), to_factor()),
    field("num_dias_corridos", "Número de dias corridos da taxa de juro", width(5)),
    field("num_dias_saques", "Número de saques da taxa de juro", width(5)),
    field("sinal_taxa", "Sinal da taxa teórica", width(1)),
    field(
      "taxa_teorica", "Taxa teórica", width(14),
      to_numeric(dec = 7, sign = "sinal_taxa")
    ),
    field(
      "carat_vertice", "Característica do vértice", width(1),
      to_factor(levels = c("F", "M"), labels = c("Fixo", "Móvel"))
    ),
    field("cod_vertice", "Código do vértice", width(5))
  )
})

MarketData$register(TaxaSwap)