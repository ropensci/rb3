#' Returns rb3 package cache directory
#'
#' Returns rb3 package cache directory
#'
#' @return a string with the file path of rb3 cache directory
#'
#' @examples
#' cachedir()
#' @export
cachedir <- function() {
  cache_folder <- file.path(tempdir(), "rb3-cache")
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
#' clearcache()
#' @export
clearcache <- function() {
  cache_folder <- cachedir()
  unlink(cache_folder, recursive = TRUE)
}