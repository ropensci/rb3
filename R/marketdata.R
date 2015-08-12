

read_marketdata <- function(filename, template=NULL, format=TRUE) {
  template <- if (is.null(template))
    marketdata$retrieve_template( basename(filename) )
  else
    marketdata$retrieve_template(template)
  if (is.null(template))
    stop('Unknown template.')
  template$read_file(filename, format)
}

registry <- proto(expr={
  ..container <- list()
  put <- function(., key, value) {
    .$..container[[key]] <- value
    invisible(NULL)
  }

  get <- function(., key) {
    val <- try(base::get(key, .$..container), TRUE)
    if (is(val, 'try-error')) NULL else val
  }
})

marketdata <- proto(expr={
  read_file <- function(., filename, format=TRUE) {
    if (.$format == 'fwf')
      df <- read_fwf(filename, .$widths, colnames=.$colnames)
    else
      return(NULL)
    if (format) .$format_data(df=df) else df
  }

  ..registry <- registry

  register <- function(., .class) {
    filename <- try(.class$filename)
    if (! is(filename, 'try-error'))
      .$..registry$put(filename, .class)
    .$..registry$put(.class$..template, .class)
  }

  retrieve_template <- function(., key) .$..registry$get(key)
})


indic <- marketdata$proto(expr={
  ..template <- 'indic'
  filename <- 'Indic.txt'
  format <- 'fwf'
  widths <- c(6, 3, 2, 8, 2, 25, 25, 2, 36)
  colnames <- c('id_trans', 'comp_trans', 'tp_reg', 'dt_ger', 'grupo_ind',
                'cd_ind', 'dc_ind', 'nm_dec', 'filler')
  format_data <- function(., df) {
    within(df, {
      nm_dec <- as.numeric(nm_dec)
      dc_ind <- as.numeric(dc_ind)/(10^nm_dec)
      dt_ger <- as.Date(dt_ger, format='%Y%m%d')
      cd_ind <- str_trim(cd_ind)
    })
  }
})

marketdata$register(indic)
