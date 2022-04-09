
query_cdi <- function() {
  url <- "https://www2.cetip.com.br/ConsultarTaxaDi/ConsultarTaxaDICetip.aspx"
  res <- httr::GET(url)
  jsonlite::fromJSON(httr::content(res, as = "text"))
}

#' @export
cdi_get <- function() {
  .json <- query_cdi()
  refdate <- as.Date(.json$dataTaxa, "%d/%m/%Y")

  tibble(
    refdate = refdate,
    CDI = as_dbl(.json$taxa, ",", ".", TRUE)
  )
}

#' @export
idi_get <- function() {
  .json <- query_cdi()
  refdate <- as.Date(.json$dataIndice, "%d/%m/%Y")

  tibble(
    refdate = refdate,
    IDI = as_dbl(.json$indice, ",", ".")
  )
}
