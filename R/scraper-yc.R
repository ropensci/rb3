yield_curve_get <- function(refdate, curve_name) {
  template <- template_retrieve("b3-reference-rates")
  .curve_name <- curve_name
  .refdate <- refdate
  template_dataset(template) |>
    filter(.data$refdate %in% .refdate, .data$curve_name == .curve_name) |>
    collect() |>
    mutate(
      biz_days = bizdayse(refdate, .data$cur_days, template$calendar),
      forward_date = .data$refdate + .data$cur_days,
      r_252 = .data$r_252 / 100,
      r_360 = .data$r_360 / 100
    ) |>
    select(
      "curve_name",
      "refdate",
      "forward_date",
      "biz_days",
      "r_252",
      "cur_days",
      "r_360",
    )
}
#' Fetches Yield Curve Data from B3
#'
#' Downloads yield curve data from B3 website
#' <https://www2.bmf.com.br/pages/portal/bmfbovespa/lumis/lum-taxas-referenciais-bmf-ptBR.asp>.
#' Particularly, we import data for
#' - DI X Pre (`yc_get`)
#' - Cupom limpo (`yc_usd_get`)
#' - DI x IPCA (`yc_ipca_get`)
#'
#' See <https://www.b3.com.br/data/files/8B/F5/11/68/5391F61043E561F6AC094EA8/Manual_de_Curvas.pdf>
#' for more details.
#'
#' @param refdate Specific date ("YYYY-MM-DD") to `yc_get` single curve
#' @param first_date First date ("YYYY-MM-DD") to `yc_mget` multiple curves
#' @param last_date Last date ("YYYY-MM-DD") to `yc_mget` multiple curves
#' @param by Number of days in between fetched dates (default = 1) in `yc_mget`
#' @param cache_folder Location of cache folder (default = cachedir())
#' @param do_cache Whether to use cache or not (default = TRUE)
#'
#' @details
#' `yc_get` returns the yield curve for the given date and `yc_mget` returns
#' multiple yield curves for a given range of dates.
#'
#' @return A dataframe/tibble with yield curve data
#'
#' @name yc_get
#'
#' @examples
#' \dontrun{
#' df_yc <- yc_mget(first_date = Sys.Date() - 5, last_date = Sys.Date())
#' head(df_yc)
#' }
#' @export
NULL

#' @rdname yc_get
#' @examples
#' \dontrun{
#' df_yc <- yc_get(Sys.Date())
#' head(df_yc)
#' }
#' @export
yc_get <- function(refdate) {
  yield_curve_get(refdate, "PRE")
}

#' Fetches a single data
#'
#' @param idx_date index of data (1.. n_dates)
#' @param date_vec Vector of dates
#' @inheritParams yc_get
#'
#' @return A dataframe
#' @noRd
NULL

#' @rdname yc_get
#' @examples
#' \dontrun{
#' df_yc_ipca <- yc_ipca_get(Sys.Date())
#' head(df_yc_ipca)
#' }
#' @export
yc_ipca_get <- function(refdate) {
  yield_curve_get(refdate, "DIC")
}

#' @rdname yc_get
#' @examples
#' \dontrun{
#' df_yc_usd <- yc_usd_get(Sys.Date())
#' head(df_yc_usd)
#' }
#' @export
yc_usd_get <- function(refdate = Sys.Date(),
                       cache_folder = cachedir(),
                       do_cache = TRUE) {
  yield_curve_get(refdate, "DOC")
}

#' Creates superset with yield curves and futures
#'
#' Creates superset with yield curves and future contracts indicating the
#' terms that match with futures contracts maturities.
#'
#' @param yc yield curve dataset
#' @param fut futures dataset
#'
#' @return
#' A dataframe with yield curve flagged with futures maturities.
#'
#' @name yc_superset
#'
#' @examples
#' \dontrun{
#' fut <- futures_get(Sys.Date() - 1)
#'
#' yc <- yc_get(Sys.Date() - 1)
#' yc_superset(yc, fut)
#'
#' yc_usd <- yc_usd_get(Sys.Date() - 1)
#' yc_usd_superset(yc_usd, fut)
#'
#' yc_ipca <- yc_ipca_get(Sys.Date() - 1)
#' yc_ipca_superset(yc_ipca, fut)
#' }
#' @export
yc_superset <- function(yc, fut) {
  fut_di1 <- fut |>
    filter(.data$commodity == "DI1") |>
    mutate(
      forward_date = maturity2date(.data$maturity_code) |> following("Brazil/ANBIMA")
    ) |>
    select("refdate", "forward_date", "symbol")

  yc |>
    left_join(fut_di1, by = c("refdate", "forward_date"))
}

#' @rdname yc_superset
#' @export
yc_usd_superset <- function(yc, fut) {
  fut_di1 <- fut |>
    filter(.data$commodity == "DDI") |>
    mutate(
      forward_date = maturity2date(.data$maturity_code) |> following("Brazil/ANBIMA")
    ) |>
    select("refdate", "forward_date", "symbol")

  yc |>
    left_join(fut_di1, by = c("refdate", "forward_date"))
}

#' @rdname yc_superset
#' @export
yc_ipca_superset <- function(yc, fut) {
  fut_di1 <- fut |>
    filter(.data$commodity == "DAP") |>
    mutate(
      forward_date = maturity2date(.data$maturity_code, "15th day") |> following("Brazil/ANBIMA")
    ) |>
    select("refdate", "forward_date", "symbol")

  yc |>
    left_join(fut_di1, by = c("refdate", "forward_date"))
}
