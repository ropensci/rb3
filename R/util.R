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
    read_marketdata(fname, template, TRUE, cache_folder, do_cache)
  } else {
    cli::cli_alert_danger("Error: no data found for date {refdate}")
    return(NULL)
  }
}