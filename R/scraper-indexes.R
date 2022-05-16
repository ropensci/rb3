#' Get composition of B3 indexes
#'
#' Gets the composition of listed B3 indexes.
#'
#' @param index_name a string with the index name
#' @param cache_folder Location of cache folder (default = cachedir())
#' @param do_cache Whether to use cache or not (default = TRUE)
#'
#' @return a character vector with symbols that belong to the given index name
#'
#' @examples
#' index_comp_get("IBOV")
#' @export
index_comp_get <- function(index_name,
                           cache_folder = cachedir(),
                           do_cache = TRUE) {
  f <- download_marketdata("GetStockIndex", cache_folder, do_cache)
  df <- read_marketdata(f, "GetStockIndex", TRUE, cache_folder, do_cache)
  idx <- str_detect(df$indexes, index_name)
  df[idx, ]$code
}

#' Get the date of indexes composition last update
#'
#' Gets the date where the indexes have been updated lastly.
#'
#' @param cache_folder Location of cache folder (default = cachedir())
#' @param do_cache Whether to use cache or not (default = TRUE)
#'
#' @return the Date when the indexes have been updated
#'
#' @examples
#' indexes_last_update()
#' @export
indexes_last_update <- function(cache_folder = cachedir(),
                                do_cache = TRUE) {
  f <- download_marketdata("GetStockIndex")
  df <- read_marketdata(f, "GetStockIndex")
  df$update[1]
}

#' Get B3 indexes available
#'
#' Gets B3 indexes available.
#'
#' @param cache_folder Location of cache folder (default = cachedir())
#' @param do_cache Whether to use cache or not (default = TRUE)
#'
#' @return a character vector with symbols of indexes available
#'
#' @examples
#' indexes_get()
#' @export
indexes_get <- function(cache_folder = cachedir(),
                        do_cache = TRUE) {
  f <- download_marketdata("GetStockIndex")
  df <- read_marketdata(f, "GetStockIndex")
  str_split(df$indexes, ",") |>
    unlist() |>
    unique() |>
    sort()
}