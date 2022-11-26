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
    do_cache
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
#' and theoretical positions.
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
    do_cache
  )
  ds <- df$Results[, c("code", "part", "theoricalQty")]
  colnames(ds) <- c("symbol", "weight", "position")
  ds$weight <- ds$weight / 100
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
  f <- download_marketdata("GetStockIndex",
    cache_folder = cache_folder, do_cache = do_cache
  )
  df <- read_marketdata(f, "GetStockIndex", do_cache = do_cache)
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
  f <- download_marketdata("GetStockIndex",
    cache_folder = cache_folder, do_cache = do_cache
  )
  df <- read_marketdata(f, "GetStockIndex", do_cache = do_cache)
  str_split(df$Results$indexes, ",") |>
    unlist() |>
    unique() |>
    sort()
}

#' Get B3 indexes available
#'
#' Gets B3 indexes available.
#'
#' @param index_name a string with the index name
#' @param cache_folder Location of cache folder (default = cachedir())
#' @param do_cache Whether to use cache or not (default = TRUE)
#'
#' @return
#' A dataframe with the index stocks, their weights, segments and positions.
#'
#' @examples
#' \dontrun{
#' index_by_segment_get("IBOV")
#' }
#' @export
index_by_segment_get <- function(index_name,
                                 cache_folder = cachedir(),
                                 do_cache = TRUE) {
  f <- download_marketdata("GetPortfolioDay",
    cache_folder = cache_folder,
    do_cache = do_cache,
    index_name = index_name
  )
  pp <- read_marketdata(f, "GetPortfolioDay", do_cache = do_cache)
  df <- pp$Results[, c("code", "segment", "part", "part_acum", "theoricalQty")]
  colnames(df) <- c("symbol", "segment", "weight", "segment_weight", "position")
  df$weight <- df$weight / 100
  df$segment_weight <- df$segment_weight / 100
  df$refdate <- pp$Header$date

  df
}

#' Fetches indexes data from B3
#'
#' Downloads index data from B3 website
#' <https://www.b3.com.br/pt_br/market-data-e-indices/servicos-de-dados/market-data/historico/boletins-diarios/pesquisa-por-pregao/pesquisa-por-pregao/>.
#'
#' @param refdate Specific date ("YYYY-MM-DD") to `yc_get` single curve
#' @param first_date First date ("YYYY-MM-DD") to `yc_mget` multiple curves
#' @param last_date Last date ("YYYY-MM-DD") to `yc_mget` multiple curves
#' @param by Number of days in between fetched dates (default = 1) in `yc_mget`
#' @param cache_folder Location of cache folder (default = cachedir())
#' @param do_cache Whether to use cache or not (default = TRUE)
#'
#' @details
#' `indexreport_get` returns index data for the given date and
#' `indexreport_mget` returns index data for a given range of dates.
#'
#' @return
#' A dataframe with index data (OHLC, average and daily oscillation)
#'
#' @name indexreport_get
#'
#' @examples
#' \dontrun{
#' df_ir <- indexreport_mget(Sys.Date() - 5, Sys.Date())
#' head(df_ir)
#' }
#' @export
indexreport_mget <- function(first_date = Sys.Date() - 5,
                             last_date = Sys.Date(),
                             by = 1,
                             cache_folder = cachedir(),
                             do_cache = TRUE) {
  first_date <- as.Date(first_date)
  last_date <- as.Date(last_date)
  tpl <- .retrieve_template(NULL, "IndexReport")
  date_vec <- bizseq(first_date, last_date, tpl$calendar)
  date_vec <- date_vec[seq(1, length(date_vec), by = by)]

  bind_rows(
    log_map_process_along(date_vec, get_single_indexreport,
      "Fetching data points",
      date_vec = date_vec,
      cache_folder = cache_folder,
      do_cache = do_cache
    )
  )
}

#' @rdname indexreport_get
#' @examples
#' \dontrun{
#' df_ir <- indexreport_get(Sys.Date())
#' head(df_ir)
#' }
#' @export
indexreport_get <- function(refdate = Sys.Date(),
                            cache_folder = cachedir(),
                            do_cache = TRUE) {
  get_single_indexreport(1, as.Date(refdate), cache_folder, do_cache)
}

get_single_indexreport <- function(idx_date,
                                   date_vec,
                                   cache_folder,
                                   do_cache) {
  df <- get_single_marketdata(
    "IndexReport", idx_date, date_vec, cache_folder, do_cache
  )
  if (!is.null(df)) {
    cols <- c(
      "refdate", "symbol", "open", "high", "low", "close", "average",
      "oscillation"
    )
    df[, cols]
  } else {
    NULL
  }
}

index_get_from_file <- function(year) {
  index_data <- read_excel("./examples/IBOVDIA.XLS",
    sheet = as.character(year), skip = 1, range = "A3:M33",
    col_names = c("day", 1:12),
  )

  pivot_longer(index_data, "1":"12", names_to = "month") |>
    mutate(
      month = as.integer(.data$month),
      year = year,
      refdate = ISOdate(.data$year, .data$month, .data$day) |> as.Date(),
      index_name = "IBOV"
    ) |>
    filter(!is.na(.data$value)) |>
    arrange("refdate") |>
    select("refdate", "index_name", "value")
}

ibovespa_index_get <- function(first_date, last_date = as.Date("1997-12-31")) {
  f <- system.file("extdata/IBOV.rds", package = "rb3")
  read_rds(f) |> filter(.data$refdate >= first_date, .data$refdate <= last_date)
}

single_index_get <- function(index_name, year, cache_folder, do_cache) {
  template <- "GetPortfolioDay_IndexStatistics"
  f <- download_marketdata(template,
    index_name = index_name, year = year,
    cache_folder = cache_folder, do_cache = do_cache
  )
  index_data <- read_marketdata(f, template, do_cache = do_cache)

  if (is.null(index_data)) {
    return(NULL)
  }

  index_data <- pivot_longer(index_data$Results, "month01":"month12",
    names_to = "month"
  ) |>
    mutate(
      month = str_match(.data$month, "\\d\\d$") |> as.integer(),
      year = year,
      refdate = ISOdate(.data$year, .data$month, .data$day) |> as.Date(),
      index_name = index_name
    ) |>
    filter(!is.na(.data$value)) |>
    arrange("refdate")

  index_data |> select("refdate", "index_name", "value")
}

#' Get index historical data
#'
#' Gets historical data from B3 indexes
#'
#' @param index_name a string with the index name
#' @param first_date First date
#' @param last_date Last date
#' @param cache_folder Location of cache folder (default = cachedir())
#' @param do_cache Whether to use cache or not (default = TRUE)
#'
#' @return A data.frame/tibble with index data
#'
#' @examples
#' \dontrun{
#' index_get("IBOV", as.Date("1977-01-01"), as.Date("1999-12-31"))
#' }
#'
#' @export
index_get <- function(index_name, first_date,
                      last_date = Sys.Date(),
                      cache_folder = cachedir(),
                      do_cache = TRUE) {
  start_year <- format(first_date, "%Y") |> as.integer()
  end_year <- format(last_date, "%Y") |> as.integer()
  if (index_name == "IBOV") {
    if (start_year > 1997) {
      year <- seq(start_year, end_year)
      map_dfr(year, \(year) single_index_get(
        index_name, year, cache_folder,
        do_cache
      ))
    } else {
      if (end_year <= 1997) {
        df <- ibovespa_index_get(first_date, last_date)
      } else {
        df1 <- ibovespa_index_get(first_date, as.Date("1997-12-31"))
        year <- seq(1998, end_year)
        df2 <- map_dfr(year, \(year) single_index_get(
          index_name, year,
          cache_folder, do_cache
        )) |>
          filter(.data$refdate <= last_date)
        df <- bind_rows(df1, df2) |> arrange("refdate")
      }
    }
  } else {
    year <- seq(start_year, end_year)
    df <- map_dfr(year, \(year) single_index_get(
      index_name, year,
      cache_folder, do_cache
    ))
    if (any(dim(df) == 0)) {
      return(NULL)
    } else {
      df |>
        filter(.data$refdate <= last_date, .data$refdate >= first_date)
    }
  }
}
