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
#' \dontrun{
#' index_comp_get("IBOV")
#' }
#' @export
index_comp_get <- function(index_name,
                           cache_folder = cachedir(),
                           do_cache = TRUE) {
  f <- download_marketdata("GetTheoricalPortfolio", cache_folder, do_cache,
    index_name = index_name
  )
  df <- read_marketdata(
    f, "GetTheoricalPortfolio", TRUE,
    cache_folder, do_cache
  )
  df$Results$code
}

#' Get the assets weights of B3 indexes
#'
#' Gets the assets weights of B3 indexes.
#'
#' @param index_name a string with the index name
#' @param cache_folder Location of cache folder (default = cachedir())
#' @param do_cache Whether to use cache or not (default = TRUE)
#'
#' @return
#' data.frame with symbols that belong to the given index name with its weights
#' and theorical positions.
#'
#' @examples
#' \dontrun{
#' index_weights_get("IBOV")
#' }
#' @export
index_weights_get <- function(index_name,
                              cache_folder = cachedir(),
                              do_cache = TRUE) {
  f <- download_marketdata("GetTheoricalPortfolio", cache_folder, do_cache,
    index_name = index_name
  )
  df <- read_marketdata(
    f, "GetTheoricalPortfolio", TRUE,
    cache_folder, do_cache
  )
  ds <- df$Results[, c("code", "part", "theoricalQty")]
  colnames(ds) <- c("symbols", "weights", "position")
  ds$weights <- ds$weights / 100
  ds
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
#' \dontrun{
#' indexes_last_update()
#' }
#' @export
indexes_last_update <- function(cache_folder = cachedir(),
                                do_cache = TRUE) {
  f <- download_marketdata("GetStockIndex")
  df <- read_marketdata(f, "GetStockIndex")
  df$Header$update
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
#' \dontrun{
#' indexes_get()
#' }
#' @export
indexes_get <- function(cache_folder = cachedir(),
                        do_cache = TRUE) {
  f <- download_marketdata("GetStockIndex")
  df <- read_marketdata(f, "GetStockIndex")
  str_split(df$Results$indexes, ",") |>
    unlist() |>
    unique() |>
    sort()
}