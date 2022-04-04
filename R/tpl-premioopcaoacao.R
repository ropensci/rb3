
PremioOpcaoAcao <- MarketDataMultiPartCSV$proto(expr = {
  filename <- "PExxxxxx.txt"
  id <- "PremioOpcaoAcao"
  separator <- ";"
  description <- "Prêmio de Referência para Opções sobre Ações"

  parts <- list(
    "Cabeçalho" = list(
      lines = 1,
      fields = fields(
        field("data_geracao_arquivo", "Data de geração do arquivo", to_date("%Y%m%d"))
      )
    ),
    "Corpo" = list(
      lines = -1,
      fields = fields(
        field("cod_opcao", "Código da Opção"),
        field("tipo_opcao", "Tipo de Opção", to_factor(levels = c("C", "V"), labels = c("call", "put"))),
        field("tipo_exercicio", "Tipo de exercício", to_factor(levels = c("A", "E"), labels = c("american", "european"))),
        field("data_vencimento", "Data de vencimento", to_date("%Y%m%d")),
        field("preco_exercicio", "Preço de exercício"),
        field("premio_referencia", "Prêmio de referência"),
        field("valor_volatilidade", "Volatilidade da opção")
      )
    )
  )
})

MarketData$register(PremioOpcaoAcao)