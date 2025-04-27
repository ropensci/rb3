process_yc <- function(ds) {
  template <- template_retrieve("b3-reference-rates")
  ds <- ds |>
    mutate(
      dur = lubridate::ddays(.data$cur_days),
      forward_date = lubridate::as_date(.data$refdate + .data$dur),
      col1 = .data$col1 / 100,
      col2 = .data$col2 / 100
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
      "col1",
      "col2",
    )
  ds
}

.yield_curve_get <- function(.curve_name = NULL) {
  template <- template_retrieve("b3-reference-rates")
  if (is.null(.curve_name)) {
    template_dataset(template, layer = 2)
  } else {
    template_dataset(template, layer = 2) |> filter(.data$curve_name == .curve_name)
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
#' @return
#' An `arrow_dplyr_query` or `ArrowObject`, representing a lazily evaluated query. The underlying data is not
#' collected until explicitly requested, allowing efficient manipulation of large datasets without immediate
#' memory usage.  
#' To trigger evaluation and return the results as an R `tibble`, use `collect()`.
#' 
#' The returned data includes the following columns:
#' - `curve_name`: Identifier of the yield curve (e.g., "PRE", "DOC", "DIC").
#' - `refdate`: Reference date of the curve.
#' - `forward_date`: Maturity date associated with the interest rate.
#' - `biz_days`: Number of business days between `refdate` and `forward_date`.
#' - `cur_days`: Number of calendar days between `refdate` and `forward_date`.
#' - `r_252`: Annualized interest rate based on 252 business days.
#' - `r_360`: Annualized interest rate based on 360 calendar days.
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
  .yield_curve_get("PRE") |>
    dplyr::rename(r_252 = "col1", r_360 = "col2") |>
    select(
      "curve_name",
      "refdate",
      "forward_date",
      "cur_days",
      "biz_days",
      "r_252",
      "r_360",
    )
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
  .yield_curve_get("DIC") |>
    dplyr::rename(r_252 = "col1") |>
    select(
      "curve_name",
      "refdate",
      "forward_date",
      "cur_days",
      "biz_days",
      "r_252"
    )
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
  .yield_curve_get("DOC") |>
    dplyr::rename(r_360 = "col1") |>
    select(
      "curve_name",
      "refdate",
      "forward_date",
      "cur_days",
      "biz_days",
      "r_360"
    )
}

.yc_with_futures <- function(yc, .refdate, .commodity, .expr) {
  template <- template_retrieve("b3-reference-rates")
  fut <- futures_get()
  fut_di1 <- fut |>
    filter(.data$commodity == .commodity, .data$refdate == .refdate) |>
    collect() |>
    mutate(
      forward_date = maturitycode2date(.data$maturity_code, .expr) |> following(template$calendar)
    ) |>
    select("refdate", "forward_date", "symbol")

  yc |>
    filter(.data$refdate == .refdate) |>
    dplyr::left_join(fut_di1, by = c("refdate", "forward_date")) |>
    collect() |>
    dplyr::arrange(.data$forward_date)
}

#' @details
#' These functions retrieve yield curve data merged with corresponding futures contract information:
#' - `yc_brl_with_futures_get()`: BRL nominal rates with DI1 futures contracts
#' - `yc_usd_with_futures_get()`: USD rates (Cupom Cambial) with DDI futures contracts
#' - `yc_ipca_with_futures_get()`: Real (inflation-indexed) rates with DAP futures contracts
#'
#' These functions combine data from B3 Reference Rates (`b3-reference-rates`) and
#' Futures Settlement Prices (`b3-futures-settlement-prices`) to create comprehensive yield curve datasets.
#' The resulting data highlights key vertices along the curve with their corresponding futures contracts,
#' providing insight into the term structure of interest rates.
#'
#' Each function requires a specific reference date to prevent excessive memory usage and
#' ensure optimal performance.
#'
#' @param refdate A Date object specifying the reference date for which to retrieve data
#'
#' @return
#' The functions `yc_brl_with_futures_get()`, `yc_usd_with_futures_get()` and `yc_ipca_with_futures_get()` return
#' a `data.frame` containing the yield curve data merged with futures contract information.
#' The data is pre-collected (not lazy) and includes all columns from the respective yield curve
#' function plus a `symbol` column identifying the corresponding futures contract.
#'
#' @examples
#' \dontrun{
#' # Get data for the last business day
#' date <- preceding(Sys.Date() - 1, "Brazil/ANBIMA")
#' 
#' # Retrieve BRL yield curve with DI1 futures
#' brl_curve <- yc_brl_with_futures_get(date)
#' head(brl_curve)
#' 
#' # Retrieve USD yield curve with DDI futures
#' usd_curve <- yc_usd_with_futures_get(date)
#' 
#' # Retrieve inflation-indexed yield curve with DAP futures
#' ipca_curve <- yc_ipca_with_futures_get(date)
#' }
#'
#' @rdname superdataset
#' @export
yc_brl_with_futures_get <- function(refdate) {
  .yc_with_futures(yc_brl_get(), refdate, "DI1", "first day")
}

#' @rdname superdataset
#' @export
yc_usd_with_futures_get <- function(refdate) {
  .yc_with_futures(yc_usd_get(), refdate, "DDI", "first day")
}

#' @rdname superdataset
#' @export
yc_ipca_with_futures_get <- function(refdate) {
  .yc_with_futures(yc_ipca_get(), refdate, "DAP", "15th day")
}
