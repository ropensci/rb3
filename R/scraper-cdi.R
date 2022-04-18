
query_cdi <- function() {
  file <- download_data("CDIIDI")
  jsonlite::fromJSON(file)
}

#' Get CDI rate and IDI index value from B3 front page
#'
#' Scrape page <https://www.b3.com.br/> to get last available CDI rate and
#' IDI index values.
#'
#' @return `data.frame` with CDI rate or IDI index values.
#'
#' @name cdi-idi
#' @examples
#' df <- cdi_get()
#' df <- idi_get()
#' @export
cdi_get <- function() {
  .json <- query_cdi()
  refdate <- as.Date(.json$dataTaxa, "%d/%m/%Y")

  tibble(
    refdate = refdate,
    CDI = as_dbl(.json$taxa, ",", ".", TRUE)
  )
}

#' @rdname cdi-idi
#' @export
idi_get <- function() {
  .json <- query_cdi()
  refdate <- as.Date(.json$dataIndice, "%d/%m/%Y")

  tibble(
    refdate = refdate,
    IDI = as_dbl(.json$indice, ",", ".")
  )
}
