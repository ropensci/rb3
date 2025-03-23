process_yc <- function(ds) {
  template <- template_retrieve("b3-reference-rates")
  ds <- ds |>
    mutate(
      dur = lubridate::ddays(.data$cur_days),
      forward_date = lubridate::as_date(.data$refdate + .data$dur),
      r_252 = .data$r_252 / 100,
      r_360 = .data$r_360 / 100
    ) |>
    collect() |>
    mutate(
      biz_days = bizdays::bizdayse(.data$refdate, .data$cur_days, template$calendar)
    ) |>
    select(
      "curve_name",
      "refdate",
      "forward_date",
      "cur_days",
      "biz_days",
      "r_252",
      "r_360",
    )
  ds
}

.yield_curve_get <- function(.curve_name = NULL) {
  template <- template_retrieve("b3-reference-rates")
  if (is.null(.curve_name)) {
    template_dataset(template, layer = 2)
  } else {
    template_dataset(template, layer = 2) |> filter(curve_name == .curve_name)
  }
}

#' @title Retrieve Yield Curve Data
#'
#' @description
#' These functions retrieve yield curve data, either for all available curves (`yc_get`) or
#' specifically for:
#' - the nominal rates curve (`yc_brl_get`).
#' - the nominal rates curve for USD in Brazil - Cupom Cambial Limpo (`yc_usd_get`).
#' - the real rates curve (`yc_ipca_get`).
#'
#' @details 
#' The yield curve data is downloaded from the B3 website
#' <https://www2.bmf.com.br/pages/portal/bmfbovespa/lumis/lum-taxas-referenciais-bmf-ptBR.asp>.
#' See the Curve Manual in this link
#' <https://www.b3.com.br/data/files/8B/F5/11/68/5391F61043E561F6AC094EA8/Manual_de_Curvas.pdf>
#' for more details.
#'
#' @return An `arrow_dplyr_query` object. This object does not eagerly evaluate the query on the data. To run the query
#' and retrieve the data, use `collect()`, which returns a dataframe (R `tibble`). The returned data includes
#' `curve_name`, `refdate`, `forward_date`, `cur_days`, `r_252`, and `r_360` columns.
#'
#' @name yc_xxx_get
NULL

#' @examples
#' \dontrun{
#' df <- yc_get() |>
#'   filter(curve_name == "PRE") |>
#'   collect()
#' }
#' @rdname yc_xxx_get
#' @export 
yc_get <- function() {
  .yield_curve_get()
}

#' @rdname yc_xxx_get
#' @examples
#' \dontrun{
#' df_yc <- yc_brl_get() |>
#'   filter(refdate == Sys.Date()) |>
#'   collect()
#' head(df_yc)
#' }
#' @export
yc_brl_get <- function() {
  .yield_curve_get("PRE")
}

#' @rdname yc_xxx_get
#' @examples
#' \dontrun{
#' df_yc_ipca <- yc_ipca_get() |>
#'   filter(refdate == Sys.Date()) |>
#'   collect()
#' head(df_yc_ipca)
#' }
#' @export
yc_ipca_get <- function() {
  .yield_curve_get("DIC")
}

#' @rdname yc_xxx_get
#' @examples
#' \dontrun{
#' df_yc_usd <- yc_usd_get() |>
#'   filter(refdate == Sys.Date()) |>
#'   collect()
#' head(df_yc_usd)
#' }
#' @export
yc_usd_get <- function() {
  .yield_curve_get("DOC")
}

.yc_superset <- function(yc, fut, .commodity, .expr) {
  template <- template_retrieve("b3-reference-rates")
  fut_di1 <- fut |>
    filter(.data$commodity == .commodity) |>
    collect() |>
    mutate(
      forward_date = maturity2date(.data$maturity_code, .expr) |> following(template$calendar)
    ) |>
    select("refdate", "forward_date", "symbol")

  yc |>
    left_join(fut_di1, by = c("refdate", "forward_date")) |>
    collect() |>
    arrange(.data$forward_date)
}

#' @rdname superdataset
#'
#' @param fut futures dataset
#'
#' @details
#' `yc_brl_superset()`, `yc_usd_superset()`, and `yc_ipca_superset()` utilize information
#' from Reference Rates (`b3-reference-rates`) and Futures Settlement Prices
#' (`b3-futures-settlement-prices`) datasets to construct a yield curve dataset. This dataset
#' highlights key vertices and their corresponding underlying futures contracts, providing a
#' detailed view of the term structure of interest rate.
#'
#' @examples
#' \dontrun{
#' date_ <- preceding(Sys.Date() - 1, "Brazil/ANBIMA")
#' fut <- futures_get() |> filter(refdate == date_)
#' yc <- yc_brl_get() |> filter(refdate == date_)
#' yc_superset(yc, fut)
#' }
#'
#' @export
yc_brl_superset <- function(yc, fut) {
  .yc_superset(yc, fut, "DI1", "first day")
}

#' @rdname superdataset
#' @export
yc_usd_superset <- function(yc, fut) {
  .yc_superset(yc, fut, "DDI", "first day")
}

#' @rdname superdataset
#' @export
yc_ipca_superset <- function(yc, fut) {
  .yc_superset(yc, fut, "DAP", "15th day")
}
