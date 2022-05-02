#' Fetches Yield Curve Data from B3
#'
#' Downloads yield curve data from B3 website 
#' <https://www2.bmf.com.br/pages/portal/bmfbovespa/lumis/lum-taxas-referenciais-bmf-ptBR.asp>.
#' Particularly, we import data for DI X Pre.
#' See <https://www.b3.com.br/data/files/8B/F5/11/68/5391F61043E561F6AC094EA8/Manual_de_Curvas.pdf>
#' for more details.
#'
#' @param first_date First date ("YYYY-MM-DD")
#' @param last_date Last date ("YYYY-MM-DD")
#' @param by Number of days in between fetched dates (default = 1)
#' @param cache_folder Location of cache folder (default = cachedir())
#' @param do_cache Whether to use cache or not (default = TRUE)
#'
#' @return A dataframe/tibble with yield curve data
#'
#' @export
#'
#' @examples
#' \dontrun{
#' df_yc <- yc_get()
#' head(df_yc)
#' }
yc_get <- function(first_date = Sys.Date() - 5,
                   last_date = Sys.Date(),
                   by = 1,
                   cache_folder = cachedir(),
                   do_cache = TRUE) {
  first_date <- as.Date(first_date)
  last_date <- as.Date(last_date)

  # find biz days in between
  tpl <- .retrieve_template(NULL, "TaxasReferenciais")

  date_vec <- bizdays::bizseq(first_date, last_date, tpl$calendar)

  # use by to separate dates
  date_vec <- date_vec[seq(1, length(date_vec), by = by)]

  # get data!
  df_yc <- dplyr::bind_rows(
    purrr::map(cli::cli_progress_along(
      date_vec,
      format = paste0("{pb_spin} Fetching data points ", 
                      " {cli::pb_current}/{cli::pb_total} ", 
                      " | {pb_bar} {pb_percent} | {pb_eta_str}")
    ),
    get_single_yc,
    date_vec = date_vec,
    cache_folder = cache_folder,
    do_cache = do_cache
    )
  )

  return(df_yc)
}

#' Fetches a single data
#'
#' @param idx_date index of data (1.. n_dates)
#' @param date_vec Vector of dates
#' @inheritParams yc_get
#'
#' @importFrom rvest read_html html_nodes html_text
#' @return A dataframe
#' @noRd
get_single_yc <- function(idx_date,
                          date_vec,
                          cache_folder,
                          do_cache) {
  tpl_name <- "TaxasReferenciais"
  tpl <- .retrieve_template(NULL, tpl_name)
  refdate <- date_vec[idx_date]
  fname <- download_data(tpl_name, cache_folder, do_cache,
    refdate = refdate,
    curve_name = "PRE"
  )
  if (!is.null(fname)) {
    df <- read_marketdata(fname, tpl_name, TRUE, cache_folder, do_cache)
    if (!is.null(df)) {
      dplyr::tibble(
        refdate = df$refdate,
        cur_days = df$cur_days,
        biz_days = bizdays::bizdayse(refdate, .data$cur_days, tpl$calendar),
        forward_date = bizdays::add.bizdays(
          refdate,
          .data$biz_days, tpl$calendar
        ),
        r_252 = df$r_252 / 100,
        r_360 = df$r_360 / 100
      )
    } else {
      NULL
    }
  } else {
    cli::cli_alert_danger("Error: no data found for date {refdate}")
    return(NULL)
  }
}