#' Get B3 indexes available
#'
#' Gets B3 indexes available.
#'
#' @return a character vector with symbols of indexes available
#'
#' @examples
#' \dontrun{
#' indexes_get()
#' }
#' @export
indexes_get <- function() {
  max_date <- template_dataset("b3-indexes-composition") |>
    dplyr::summarise(update_date = max(.data$update_date)) |>
    collect() |>
    dplyr::pull(.data$update_date)

  template_dataset("b3-indexes-composition") |>
    filter(.data$update_date == max_date) |>
    select("indexes") |>
    collect() |>
    dplyr::pull(.data$indexes) |>
    str_split(",") |>
    unlist() |>
    unique() |>
    sort()
}

#' Retrieve Composition of B3 Indexes
#'
#' This function fetches the composition of B3 indexes.
#' It uses the template dataset "b3-indexes-composition" to retrieve the data.
#'
#' @return A data frame containing the columns:
#'   \describe{
#'     \item{update_date}{The date when the data was last updated.}
#'     \item{symbol}{The symbol of the asset.}
#'     \item{indexes}{The indexes associated with the asset.}
#'   }
#' 
#' An `arrow_dplyr_query` or `ArrowObject`, representing a lazily evaluated query. The underlying data is not
#' collected until explicitly requested, allowing efficient manipulation of large datasets without immediate
#' memory usage.  
#' To trigger evaluation and return the results as an R `tibble`, use `collect()`.
#' 
#' @examples
#' \dontrun{
#'   indexes_composition <- indexes_composition_get()
#'   head(indexes_composition)
#' }
#' @export
indexes_composition_get <- function() {
  template_dataset("b3-indexes-composition") |>
    select("update_date", "symbol", "indexes")
}

process_indexes_current_portfolio <- function(ds) {
  ds |>
    collect() |>
    mutate(
      sector = stringr::str_extract(.data$segment, "^[^/]+") |> stringr::str_trim(),
      sector = .data$sector |>
        stringr::str_to_lower() |>
        stringi::stri_trans_general("Latin-ASCII") |>
        stringr::str_replace_all("\\s+", " ") |>
        stringr::str_trim() |>
        stringr::str_replace_all("petroleo, gas e biocombustiveis", "Petr\u00f3leo, G\u00e1s e Biocombust\u00edveis") |>
        stringr::str_replace_all("mats basicos", "Materiais B\u00e1sicos") |>
        stringr::str_replace_all("bens indls|bens industriais", "Bens Industriais") |>
        stringr::str_replace_all("cons n ciclico", "Consumo N\u00e3o C\u00edclico") |>
        stringr::str_replace_all("cons n basico|consumo ciclico|diversos", "Consumo C\u00edclico") |>
        stringr::str_replace_all("saude", "Sa\u00fade") |>
        stringr::str_replace_all("comput e equips|tec.informacao", "Tecnologia da Informa\u00e7\u00e3o") |>
        stringr::str_replace_all("telecomunicacao|midia", "Comunica\u00e7\u00f5es") |>
        stringr::str_replace_all("utilidade publ", "Utilidade P\u00fablica") |>
        stringr::str_replace_all("financ e outros|financeiro e outros", "Financeiro") |>
        stringr::str_replace_all("outros", "Outros") |>
        stringr::str_replace_all("n classificados", "N\u00e3o Classificados") |>
        identity(),
      weight = .data$weight / 100,
    ) |>
    select("refdate", "portfolio_date", "index", "symbol", "weight", "theoretical_quantity",
      "total_theoretical_quantity", "reductor", "sector") |>
    identity()
}

#' Retrieve Portfolio of B3 Indexes
#'
#' These functions fetch the current and theoretical portfolio of B3 indexes using predefined
#' dataset templates.
#' The data is retrieved from the datasets "b3-indexes-current-portfolio" and "b3-indexes-theoretical-portfolio".
#'
#' @return
#' An `arrow_dplyr_query` or `ArrowObject`, representing a lazily evaluated query. The underlying data is not
#' collected until explicitly requested, allowing efficient manipulation of large datasets without immediate
#' memory usage.  
#' To trigger evaluation and return the results as an R `tibble`, use `collect()`.
#' 
#' @examples
#' \dontrun{
#' template_dataset("b3-indexes-current-portfolio", layer = 2) |>
#'   filter(index %in% c("SMLL", "IBOV", "IBRA")) |>
#'   collect()
#' }
#'
#' @name indexes-portfolio
#' 
#' @export
indexes_current_portfolio_get <- function() {
  template_dataset("b3-indexes-current-portfolio", layer = 2)
}

process_indexes_theoretical_portfolio <- function(ds) {
  ds |>
    collect() |>
    mutate(
      weight = .data$weight / 100,
    ) |>
    select("refdate", "index", "symbol", "weight", "theoretical_quantity", "total_theoretical_quantity", "reductor") |>
    identity()
}

#' @examples
#' \dontrun{
#' template_dataset("b3-indexes-theoretical-portfolio", layer = 2) |>
#'   filter(index == "IBOV") |>
#'   collect()
#' }
#' @rdname indexes-portfolio
#' @export
indexes_theoretical_portfolio_get <- function() {
  template_dataset("b3-indexes-theoretical-portfolio", layer = 2) 
}

process_index_historical_data <- function(ds) {
  ds |>
    collect() |>
    tidyr::pivot_longer(-c("index", "day", "year"), names_to = "month", values_to = "value") |>
    mutate(
      month = as.integer(str_replace(.data$month, "month", "")),
      refdate = lubridate::make_date(.data$year, .data$month, .data$day),
    ) |>
    select("index", "refdate", "value") |>
    dplyr::rename(symbol = "index") |>
    filter(!is.na(.data$value)) |>
    dplyr::arrange("refdate")
}

#' Get historical data from B3 indexes
#'
#' Fetches historical data from B3 indexes.
#'
#' @return
#' An `arrow_dplyr_query` or `ArrowObject`, representing a lazily evaluated query. The underlying data is not
#' collected until explicitly requested, allowing efficient manipulation of large datasets without immediate
#' memory usage.  
#' To trigger evaluation and return the results as an R `tibble`, use `collect()`.
#'
#' @examples
#' \dontrun{
#' fetch_marketdata("b3-indexes-historical-data", index = "IBOV", year = 2001:2010)
#' indexes_historical_data_get() |>
#'  filter(index == "IBOV", refdate >= as.Date("2001-01-01"), refdate <= as.Date("2010-12-31"))
#' }
#'
#' @export
indexes_historical_data_get <- function() {
  template_dataset("b3-indexes-historical-data", layer = 2)
}
