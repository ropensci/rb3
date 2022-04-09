#' Fetches Yield Curve Data from B3
#' 
#' Downloads yield curve data from B3 website <https://www2.bmf.com.br/pages/portal/bmfbovespa/lumis/lum-taxas-referenciais-bmf-ptBR.asp>. 
#' Particularly, we import data for DI X Pre. 
#' See <https://www.b3.com.br/data/files/8B/F5/11/68/5391F61043E561F6AC094EA8/Manual_de_Curvas.pdf>
#' for more details.
#'
#' @param first_date First date ("YYYY-MM-DD")
#' @param last_date Last date ("YYYY-MM-DD")
#' @param by Number of days inbetween fetched dates (default = 1)
#' @param cache_folder Location of cache folder (default = tempdir())
#' @param do_cache Whether to use cache or not (default = TRUE)
#'
#' @return A dataframe/tibble with yield curve data
#' @export
#'
#' @examples
#' 
#' @import cli
#' 
#' @examples 
#' df_yc <- yc_get()
#' head(df_yc)
yc_get <- function(first_date = Sys.Date() - 5, 
                   last_date = Sys.Date(), 
                   by = 1,
                   cache_folder =  file.path(tempdir(), 'yc-cache'),
                   do_cache = TRUE) {
  
  first_date <- as.Date(first_date)
  last_date <- as.Date(last_date)
  
  # find biz days in between
  br_cal <- get_calendar()
  
  date_vec <- bizdays::bizseq(first_date, last_date, br_cal)
  
  # use by to separate dates
  date_vec <- date_vec[seq(1, length(date_vec), by = by)]
  
  # get data!
  df_yc <- dplyr::bind_rows(
    purrr::map(cli::cli_progress_along(
      date_vec, 
      format = "{pb_spin} Fetching data points {cli::pb_current}/{cli::pb_total} | {pb_bar} {pb_percent} | {pb_eta_str}"
    ), 
    get_single_yc,
    date_vec = date_vec,
    cache_folder = cache_folder,
    do_cache = do_cache)
  )
  
  return(df_yc)
  
}

#' Returns default calendar
#'
#' @noRd
get_calendar <- function() {
  br_cal <- bizdays::create.calendar("Brazil/ANBIMA", 
                                     bizdays::holidaysANBIMA, 
                                     weekdays=c("saturday", "sunday"))
  
  return(br_cal)
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
  
  ref_date <- date_vec[idx_date]
  #cli::cli_alert_info('Fetching Yield Curve for {ref_date}'  )
  
  f_cache <- file.path(cache_folder,
                       paste0(format(ref_date, "%Y%m%d"), '_',
                              'yc-cache.rds'))
  
  
  
  if (do_cache) {
    if (!dir.exists(cache_folder)) dir.create(cache_folder, recursive = TRUE)
    
    if (file.exists(f_cache)) {
      
      #cli::cli_alert_success("\tfound cache file at {f_cache}")
      df_yc <- readr::read_rds(f_cache)
      
      return(df_yc)
    }
  } 
  
  base_url <- stringr::str_glue(
    "https://www2.bmf.com.br/pages/portal/bmfbovespa/lumis/lum-taxas-referenciais-bmf-ptBR.asp?",
    "Data={format(ref_date, '%d/%m/%Y')}&Data1={format(ref_date,'%Y%m%d')}&slcTaxa=PRE"
  )
  
  char_vec <- rvest::read_html(base_url) |>
    rvest::html_nodes("td") |>
    rvest::html_text()
  
  len_char_vec <- length(char_vec)
  
  if (len_char_vec == 0) {
    
    cli::cli_alert_danger('Error: no data found for date {ref_date}')
    return(dplyr::tibble())
    
  } 
  
  idx1 <- seq(1, length(char_vec), by = 3)
  idx2 <- seq(2, length(char_vec), by = 3)
  idx3 <- seq(3, length(char_vec), by = 3)
  
  biz_days <- char_vec[idx1]
  r_252 <- char_vec[idx2]
  r_360 <- char_vec[idx3]
  
  my_locale <- readr::locale(decimal_mark = ',')
  br_cal <- get_calendar()
  
  df_single_yc <- dplyr::tibble(
    ref_date,
    biz_days = as.integer(biz_days),
    forward_date =  bizdays::add.bizdays(ref_date, biz_days, br_cal),
    r_252 = readr::parse_double(r_252, locale = my_locale)/100,
    r_360 = readr::parse_double(r_360, locale = my_locale)/100
  )
  
  if (do_cache) {
    
    readr::write_rds(df_single_yc, f_cache)
    
  }
  
  return(df_single_yc)
}

