
Indic <- MarketDataFWF$proto(expr={
  name <- 'indic'
  filename <- 'Indic.txt'
  widths <- c(6, 3, 2, 8, 2, 25, 25, 2, 36)
  colnames <- c('Identificação da transação', 'Complemento da transação',
    'Tipo de registro', 'Data de geração do arquivo', 'Grupo do indicador',
    'Código do indicador', 'Valor do indicador na data',
    'Número de decimais do valor', 'Filler'
  )

  format_data <- function(., df) {
    within(df, {
      `Número de decimais do valor` <- as.numeric(`Número de decimais do valor`)
      `Valor do indicador na data` <- as.numeric(`Valor do indicador na data`)/(10^`Número de decimais do valor`)
      `Data de geração do arquivo` <- as.Date(`Data de geração do arquivo`, format='%Y%m%d')
      `Código do indicador` <- stringr::str_trim(`Código do indicador`)
    })
  }
  
  print <- function(.) {
    .$name
  }
})

MarketData$register(Indic)

# TODO: implement summary for templates