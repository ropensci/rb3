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
