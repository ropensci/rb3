#' Returns rb3 package cache directory
#'
#' Returns rb3 package cache directory
#'
#' @details
#' In order to set a default directory for cache, which is a good idea for those
#' who want to increase data historically, the option `rb3.cachedir` can be
#' set.
#' Once it is set, the defined directory will be used as the default cachedir.
#'
#' @return a string with the file path of rb3 cache directory
#'
#' @examples
#' cachedir()
#' @export
cachedir <- function() {
  cache_folder <- getOption("rb3.cachedir")
  cache_folder <- if (is.null(cache_folder)) {
    file.path(tempdir(), "rb3-cache")
  } else {
    cache_folder
  }

  if (!dir.exists(cache_folder)) {
    dir.create(cache_folder, recursive = TRUE)
  }

  cache_folder
}

#' Clear cache directory
#'
#' Clear cache directory
#'
#' @return Has no return
#'
#' @examples
#' \dontrun{
#' clearcache()
#' }
#' @export
clearcache <- function() {
  cache_folder <- cachedir()
  unlink(cache_folder, recursive = TRUE)
}

#' Fetches a single marketdata
#'
#' @param idx_date index of data (1.. n_dates)
#' @param date_vec Vector of dates
#' @param cache_folder Location of cache folder (default = cachedir())
#' @param do_cache Whether to use cache or not (default = TRUE)
#' @param ... orther arguments
#'
#' @return
#' A dataframe or `NULL`
#'
#' @noRd
get_single_marketdata <- function(template,
                                  idx_date,
                                  date_vec,
                                  cache_folder,
                                  do_cache, ...) {
  refdate <- date_vec[idx_date]
  fname <- download_marketdata(template, cache_folder, do_cache,
    refdate = refdate, ...
  )
  if (!is.null(fname)) {
    read_marketdata(fname, template, TRUE, do_cache)
  } else {
    alert("danger", "Error: no data found for date {refdate}",
      refdate = refdate
    )
    return(NULL)
  }
}

#' cli_progress_along wrapper
#'
#' @param x data to iterate through
#' @param func function to call
#' @param msg message to display
#' @param ... orther arguments
#'
#' @return
#' A list with `func` returned values
#'
#' @noRd
log_map_process_along <- function(x, func, msg, ...) {
  f_ <- paste(
    "{pb_spin}",
    "{msg}",
    "{pb_current}/{pb_total}",
    "|",
    "{pb_bar}",
    "{pb_percent}",
    "|",
    "{pb_eta_str}"
  )
  rb3_hide_progressbar <- getOption("rb3.silent")
  if (!is.null(rb3_hide_progressbar) && isTRUE(rb3_hide_progressbar)) {
    map(seq_along(x), func, ...)
  } else {
    map(cli_progress_along(x, format = f_), func, ...)
  }
}

#' cli_alert_* wrapper
#'
#' @param x type
#' @param text message to display
#' @param ... orther arguments
#'
#' @return
#' A list with `func` returned values
#'
#' @noRd
alert <- function(x = c("info", "success", "danger", "warning"), text, ...) {
  x <- match.arg(x)
  rb3_silent <- getOption("rb3.silent")
  if (!is.null(rb3_silent) && isTRUE(rb3_silent)) {
    # do nothing
  } else {
    f_ <- alert_fun(x)
    if (! is.null(f_)) {
      f_(str_glue(text, .envir = list(...)))
    }
  }
}

alert_fun <- function(x) {
  funcs <- list(
    info = cli_alert_info,
    danger = cli_alert_danger,
    success = cli_alert_success,
    warning = cli_alert_warning
  )
  func <- funcs[[x]]
  if (is.null(func)) {
    warning(paste0("Invalid call to alert function ", x))
    return(NULL)
  } else {
    func
  }
}
