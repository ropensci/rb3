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
