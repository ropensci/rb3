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
yc_mget <- function(first_date = Sys.Date() - 5,
                    last_date = Sys.Date(),
                    by = 1,
                    cache_folder = cachedir(),
                    do_cache = TRUE) {
  first_date <- as.Date(first_date)
  last_date <- as.Date(last_date)

  # find biz days in between
  tpl <- .retrieve_template(NULL, "TaxasReferenciais")

  date_vec <- bizseq(first_date, last_date, tpl$calendar)

  # use by to separate dates
  date_vec <- date_vec[seq(1, length(date_vec), by = by)]

  # get data!
  df_yc <- bind_rows(
    log_map_process_along(date_vec, get_single_yc,
      "Fetching data points",
      date_vec = date_vec,
      cache_folder = cache_folder,
      do_cache = do_cache
    )
  )

  return(df_yc)
}

#' @rdname yc_get
#' @examples
#' \dontrun{
#' df_yc <- yc_get(Sys.Date())
#' head(df_yc)
#' }
#' @export
yc_get <- function(refdate = Sys.Date(),
                   cache_folder = cachedir(),
                   do_cache = TRUE) {
  get_single_yc(1, as.Date(refdate), cache_folder, do_cache)
}

#' Fetches a single data
#'
#' @param idx_date index of data (1.. n_dates)
#' @param date_vec Vector of dates
#' @inheritParams yc_get
#'
#' @return A dataframe
#' @noRd
get_single_yc <- function(idx_date,
                          date_vec,
                          cache_folder,
                          do_cache) {
  tpl_name <- "TaxasReferenciais"
  tpl <- .retrieve_template(NULL, tpl_name)
  refdate <- date_vec[idx_date]
  fname <- download_marketdata(tpl_name, cache_folder, do_cache,
    refdate = refdate,
    curve_name = "PRE"
  )
  if (!is.null(fname)) {
    df <- read_marketdata(fname, tpl_name, TRUE, do_cache)
    if (!is.null(df)) {
      tibble(
        refdate = df$refdate,
        cur_days = df$cur_days,
        biz_days = bizdayse(refdate, .data$cur_days, tpl$calendar),
        forward_date = add.bizdays(
          refdate,
          .data$biz_days, tpl$calendar
        ),
        r_252 = df$col1 / 100,
        r_360 = df$col2 / 100
      )
    } else {
      NULL
    }
  } else {
    alert("danger", "Error: no data found for date {refdate}",
      refdate = refdate
    )
    return(NULL)
  }
}

#' @details
#' `yc_ipca_get` returns the yield curve of real interest rates
#' for the given date and `yc_ipca_mget` returns
#' multiple yield curves of real interest rates for a given range of dates.
#' These real interest rates consider IPCA as its inflation index.
#'
#' @rdname yc_get
#' @examples
#' \dontrun{
#' df_yc_ipca <- yc_ipca_mget(
#'   first_date = Sys.Date() - 5,
#'   last_date = Sys.Date()
#' )
#' head(df_yc_ipca)
#' }
#' @export
yc_ipca_mget <- function(first_date = Sys.Date() - 5,
                         last_date = Sys.Date(),
                         by = 1,
                         cache_folder = cachedir(),
                         do_cache = TRUE) {
  first_date <- as.Date(first_date)
  last_date <- as.Date(last_date)

  # find biz days in between
  tpl <- .retrieve_template(NULL, "TaxasReferenciais")

  date_vec <- bizseq(first_date, last_date, tpl$calendar)

  # use by to separate dates
  date_vec <- date_vec[seq(1, length(date_vec), by = by)]

  # get data!
  df_yc <- bind_rows(
    log_map_process_along(date_vec, get_single_yc_ipca,
      "Fetching data points",
      date_vec = date_vec,
      cache_folder = cache_folder,
      do_cache = do_cache
    )
  )

  return(df_yc)
}

#' @rdname yc_get
#' @examples
#' \dontrun{
#' df_yc_ipca <- yc_ipca_get(Sys.Date())
#' head(df_yc_ipca)
#' }
#' @export
yc_ipca_get <- function(refdate = Sys.Date(),
                        cache_folder = cachedir(),
                        do_cache = TRUE) {
  get_single_yc_ipca(1, as.Date(refdate), cache_folder, do_cache)
}

#' Fetches a single data
#'
#' @param idx_date index of data (1.. n_dates)
#' @param date_vec Vector of dates
#' @inheritParams yc_get
#'
#' @return A dataframe
#' @noRd
get_single_yc_ipca <- function(idx_date,
                               date_vec,
                               cache_folder,
                               do_cache) {
  tpl_name <- "TaxasReferenciais"
  tpl <- .retrieve_template(NULL, tpl_name)
  refdate <- date_vec[idx_date]
  fname <- download_marketdata(tpl_name, cache_folder, do_cache,
    refdate = refdate,
    curve_name = "DIC"
  )
  if (!is.null(fname)) {
    df <- read_marketdata(fname, tpl_name, TRUE, do_cache)
    if (!is.null(df)) {
      tibble(
        refdate = df$refdate,
        cur_days = df$cur_days,
        biz_days = bizdayse(refdate, .data$cur_days, tpl$calendar),
        forward_date = add.bizdays(
          refdate,
          .data$biz_days, tpl$calendar
        ),
        r_252 = df$col1 / 100
      )
    } else {
      NULL
    }
  } else {
    alert("danger", "Error: no data found for date {refdate}",
      refdate = refdate
    )
    return(NULL)
  }
}

#' @rdname yc_get
#'
#' @details
#' `yc_usd_get` returns the yield curve of nominal interest rates for USD in
#' Brazil for the given date and `yc_usd_mget` returns
#' multiple yield curves of nominal interest rates for USD in Brazil for a
#' given range of dates.
#' These real interest rates consider IPCA as its inflation index.
#'
#' @examples
#' \dontrun{
#' df_yc_usd <- yc_usd_mget(
#'   first_date = Sys.Date() - 5,
#'   last_date = Sys.Date()
#' )
#' head(df_yc_usd)
#' }
#' @export
yc_usd_mget <- function(first_date = Sys.Date() - 5,
                        last_date = Sys.Date(),
                        by = 1,
                        cache_folder = cachedir(),
                        do_cache = TRUE) {
  first_date <- as.Date(first_date)
  last_date <- as.Date(last_date)

  # find biz days in between
  tpl <- .retrieve_template(NULL, "TaxasReferenciais")

  date_vec <- bizseq(first_date, last_date, tpl$calendar)

  # use by to separate dates
  date_vec <- date_vec[seq(1, length(date_vec), by = by)]

  # get data!
  df_yc <- bind_rows(
    log_map_process_along(date_vec, get_single_yc_usd,
      "Fetching data points",
      date_vec = date_vec,
      cache_folder = cache_folder,
      do_cache = do_cache
    )
  )

  return(df_yc)
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
  get_single_yc_usd(1, as.Date(refdate), cache_folder, do_cache)
}

#' Fetches a single data
#'
#' @param idx_date index of data (1.. n_dates)
#' @param date_vec Vector of dates
#' @inheritParams yc_get
#'
#' @return A dataframe
#' @noRd
get_single_yc_usd <- function(idx_date,
                              date_vec,
                              cache_folder,
                              do_cache) {
  tpl_name <- "TaxasReferenciais"
  tpl <- .retrieve_template(NULL, tpl_name)
  refdate <- date_vec[idx_date]
  fname <- download_marketdata(tpl_name, cache_folder, do_cache,
    refdate = refdate,
    curve_name = "DOC"
  )
  if (!is.null(fname)) {
    df <- read_marketdata(fname, tpl_name, TRUE, do_cache)
    if (!is.null(df)) {
      tibble(
        refdate = df$refdate,
        cur_days = df$cur_days,
        biz_days = bizdayse(refdate, .data$cur_days, tpl$calendar),
        forward_date = add.bizdays(
          refdate,
          .data$biz_days, tpl$calendar
        ),
        r_360 = df$col1 / 100
      )
    } else {
      NULL
    }
  } else {
    alert("danger", "Error: no data found for date {refdate}",
      refdate = refdate
    )
    return(NULL)
  }
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
    mutate(forward_date = maturity2date(.data$maturity_code) |>
      following("Brazil/ANBIMA")) |>
    select("refdate", "forward_date", "symbol")

  yc |>
    left_join(fut_di1, by = c("refdate", "forward_date"))
}

#' @rdname yc_superset
#' @export
yc_usd_superset <- function(yc, fut) {
  fut_di1 <- fut |>
    filter(.data$commodity == "DDI") |>
    mutate(forward_date = maturity2date(.data$maturity_code) |>
      following("Brazil/ANBIMA")) |>
    select("refdate", "forward_date", "symbol")

  yc |>
    left_join(fut_di1, by = c("refdate", "forward_date"))
}

#' @rdname yc_superset
#' @export
yc_ipca_superset <- function(yc, fut) {
  fut_di1 <- fut |>
    filter(.data$commodity == "DAP") |>
    mutate(forward_date = maturity2date(.data$maturity_code, "15th day") |>
      following("Brazil/ANBIMA")) |>
    select("refdate", "forward_date", "symbol")

  yc |>
    left_join(fut_di1, by = c("refdate", "forward_date"))
}
