#' @title Read files from Brazilian Financial Market
#'
#' @description
#' Read the many files used in Brazilian Financial Market and
#' convert them into useful formats and data structures.
#'
#' @name rb3-package
#' @docType package
#'
#' @importFrom ascii ascii
#' @importFrom proto proto
#' @importFrom base64enc base64encode
#' @importFrom bizdays following preceding load_builtin_calendars
#' @importFrom bizdays add.bizdays bizdayse bizseq getdate
#' @importFrom digest digest
#' @importFrom dplyr tibble inner_join mutate select filter left_join as_tibble
#' @importFrom dplyr bind_rows arrange
#' @importFrom tidyr pivot_longer
#' @importFrom httr GET POST parse_url status_code headers content
#' @importFrom jsonlite toJSON fromJSON
#' @importFrom purrr map_dfr map_lgl map_chr map_int map
#' @importFrom readr write_rds read_rds read_csv read_file
#' @importFrom readxl read_excel
#' @importFrom rlang .data
#' @importFrom stringr str_replace_all str_starts str_match str_sub str_split
#' @importFrom stringr str_to_lower str_detect str_pad str_replace str_trim
#' @importFrom stringr str_ends str_replace str_c
#' @importFrom stringr str_glue str_length
#' @importFrom yaml yaml.load_file
#' @importFrom methods is new slot
#' @importFrom utils write.table unzip getFromNamespace hasName read.table
#' @importFrom rvest read_html html_nodes html_text
#' @importFrom rvest html_table html_element read_html
#' @importFrom XML xmlInternalTreeParse getNodeSet xmlValue
NULL
