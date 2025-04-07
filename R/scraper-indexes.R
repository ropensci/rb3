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
    summarise(update_date = max(update_date)) |>
    collect() |>
    pull(update_date)

  template_dataset("b3-indexes-composition") |>
    filter(update_date == max_date) |>
    select(indexes) |>
    collect() |>
    pull(indexes) |>
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
    select(update_date, symbol, indexes)
}

process_indexes_current_portfolio <- function(ds) {
  ds |>
    collect() |>
    mutate(
      sector = str_extract(segment, "^[^/]+") |> str_trim(),
      sector = sector |>
        str_to_lower() |> # Converte para minúsculas
        stringi::stri_trans_general("Latin-ASCII") |> # Remove acentos
        str_replace_all("\\s+", " ") |> # Remove espaços extras
        str_trim() |> # Remove espaços no início e no fim
        str_replace_all("petroleo, gas e biocombustiveis", "Petróleo, Gás e Biocombustíveis") |> # petróleo, gás e biocombustíveis
        str_replace_all("mats basicos", "Materiais Básicos") |> # materiais básicos
        str_replace_all("bens indls|bens industriais", "Bens Industriais") |> # bens industriais
        str_replace_all("cons n ciclico", "Consumo Não Cíclico") |> # consumo não cíclico
        str_replace_all("cons n basico|consumo ciclico|diversos", "Consumo Cíclico") |> # consumo cíclico
        str_replace_all("saude", "Saúde") |> # saúde
        str_replace_all("comput e equips|tec.informacao", "Tecnologia da Informação") |> # tecnologia da informação
        str_replace_all("telecomunicacao|midia", "Comunicações") |> # comunicações
        str_replace_all("utilidade públ|utilidade publ", "Utilidade Pública") |> # utilidade pública
        str_replace_all("financ e outros|financeiro e outros", "Financeiro") |> # financeiro
        str_replace_all("outros", "Outros") |> # outros
        str_replace_all("n classificados", "Não Classificados") |> # não classificados
        identity(),
      weight = weight / 100, # Converte a participação para porcentagem
    ) |>
    select(refdate, portfolio_date, index, symbol, weight, theoretical_quantity, total_theoretical_quantity, reductor, sector) |>
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
      weight = weight / 100, # Converte a participação para porcentagem
    ) |>
    select(refdate, index, symbol, weight, theoretical_quantity, total_theoretical_quantity, reductor) |>
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

ibovespa_index_get <- function(first_date, last_date = as.Date("1997-12-31")) {
  f <- system.file("extdata/IBOV.rds", package = "rb3")
  read_rds(f) |> filter(.data$refdate >= first_date, .data$refdate <= last_date)
}

process_index_historical_data <- function(ds) {
  ds |>
    collect() |>
    tidyr::pivot_longer(-c(index, day, year), names_to = "month", values_to = "value") |>
    mutate(
      month = as.integer(str_replace(month, "month", "")),
      refdate = lubridate::make_date(year, month, day),
    ) |>
    select(index, refdate, value) |>
    rename(symbol = index) |>
    filter(!is.na(value)) |>
    arrange(refdate)
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
#'  filter(index == "IBOV", refdate >= as.Date("2001-01-01"), refdate <= as.Date("2010-12-31")) |>
#' }
#'
#' @export
indexes_historical_data_get <- function() {
  template_dataset("b3-indexes-historical-data", layer = 2)
}
