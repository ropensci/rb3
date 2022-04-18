
query_cdi <- function() {
  fname <- download_data("CDIIDI")

  if (!is.null(fname)) {
    read_marketdata(fname, "CDIIDI")
  } else {
    cli::cli_alert_danger("Failed CDIIDI download")
    NULL
  }
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
#' \dontrun{
#' df <- cdi_get()
#' df <- idi_get()
#' }
#' @export
cdi_get <- function() {
  dx <- query_cdi()
  tibble(
    refdate = dx$dataTaxa,
    CDI = dx$taxa
  )
}

#' @rdname cdi-idi
#' @export
idi_get <- function() {
  dx <- query_cdi()
  tibble(
    refdate = dx$dataIndice,
    IDI = dx$indice
  )
}