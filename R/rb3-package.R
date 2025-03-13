#' @title Read files from Brazilian Financial Market
#'
#' @description
#' Read the many files used in Brazilian Financial Market and
#' convert them into useful formats and data structures.
#'
#' @details
#' ## rb3 options
#'
#' rb3 uses `base::options` to allow user set global options that affect the
#' way the package works and display its alerts.
#'
#' \describe{
#'   \item{rb3.cachedir}{
#'     rb3 cache folder is named `rb3-cache` and it is created inside the
#'     directory returned by `base::tempdir`.
#'     Since it is changed for every new session it is interesting to use the
#'     same directory for cache across sessions.
#'     Once the option `rb3.cachedir` is set the files are always cached in
#'     the same directory.
#'     This is very useful to build a historical data.
#'     Historical time series can be loaded directly from cached files.
#'   }
#'   \item{rb3.clear.cache}{
#'     Some files have invalid content returning NULL data.
#'     Every downloaded file is stored in the cache folder.
#'     If `rb3.clear.cache` is TRUE these invalid files are remove once they
#'     are detected.
#'     It helps with keeping only files with valid content in the cache folder.
#'   }
#'   \item{rb3.silent}{
#'     rb3 default behavior on communicating users what's going on is total
#'     transparency.
#'     So, it displays many alert messages to inform users many of the details.
#'     On the other hand, this behavior can be sometimes annoying.
#'     The option `rb3.silent` can be set to `TRUE` in order to avoid that the
#'     alerts be displayed.
#'   }
#' }
#'
#' @name rb3-package
#'
#' @importFrom base64enc base64encode
#' @importFrom stats na.omit
#' @importFrom bizdays following preceding load_builtin_calendars
#' @importFrom bizdays add.bizdays bizdayse bizseq getdate
#' @importFrom cli cli_alert_info cli_alert_danger cli_alert_success
#' @importFrom cli cli_alert_warning
#' @importFrom cli cli_progress_along pb_spin pb_current pb_total pb_bar
#' @importFrom cli pb_percent pb_eta_str
#' @importFrom digest digest
#' @importFrom dplyr tibble inner_join mutate select filter left_join as_tibble
#' @importFrom dplyr bind_rows arrange rename group_by summarise collect
#' @importFrom httr GET POST parse_url status_code headers content config
#' @importFrom jsonlite toJSON fromJSON
#' @importFrom purrr map_dfr map_lgl map_chr map_int map
#' @importFrom readr write_rds read_rds read_csv read_file
#' @importFrom rlang .data
#' @importFrom stringr str_replace_all str_starts str_match str_sub str_split
#' @importFrom stringr str_to_lower str_detect str_pad str_replace str_trim
#' @importFrom stringr str_ends str_replace str_c
#' @importFrom stringr str_glue str_length
#' @importFrom yaml yaml.load_file
#' @importFrom methods is new slot
#' @importFrom utils write.table unzip getFromNamespace hasName read.table
#' @importFrom XML xmlInternalTreeParse getNodeSet xmlValue
#' @importFrom XML htmlTreeParse xmlSApply
#' @keywords internal
"_PACKAGE"

rb3_registry <- create_registry()

rb3_bootstrap <- function(cache_folder = cachedir()) {
  if (!dir.exists(cache_folder)) {
    dir.create(cache_folder, recursive = TRUE)
  }

  raw_folder <- file.path(cache_folder, "raw")
  if (!dir.exists(raw_folder)) {
    dir.create(raw_folder, recursive = TRUE)
  }

  meta_folder <- file.path(cache_folder, "meta")
  if (!dir.exists(meta_folder)) {
    dir.create(meta_folder, recursive = TRUE)
  }

  db_folder <- file.path(cache_folder, "db")
  if (!dir.exists(db_folder)) {
    dir.create(db_folder, recursive = TRUE)
  }

  .reg <- rb3_registry$get_instance()
  .reg[["rb3_folder"]] <- cache_folder
  .reg[["raw_folder"]] <- raw_folder
  .reg[["meta_folder"]] <- meta_folder
  .reg[["db_folder"]] <- db_folder
  invisible(NULL)
}