#' Read and parses files delivered by B3
#'
#' B3, and previously BMF&Bovespa, used to deliver many files with a diverse
#' set of valuable data and informations that can be used to study of can
#' be called of marketdata.
#' There are files with informations about futures, option, interest
#' rates, currency rates, bonds and many other subjects.
#'
#' @param filename a string containing a path for the file.
#' @param template a string with the template name.
#' @param parse_fields a logical indicating if the fields must be parsed.
#' @param do_cache Whether to use cache or not (default = TRUE)
#'
#' Each `template` has a default value for the `filename`, if the given
#' file name equals one template filename attribute, the matched template
#' is used to parse the file.
#' Otherwise the template must be provided.
#'
#' The function `show_templates` can be used to view the available templates
#' and their default filenames.
#'
#' @return `data.frame` of a list of `data.frame` containing data parsed from
#' files.
#'
#' @seealso show_templates display_template
#'
#' @examples
#' \dontrun{
#' # Eletro.txt matches the filename of Eletro template
#' path <- "Eletro.txt"
#' df <- read_marketdata(path)
#' path <- "Indic.txt"
#' df <- read_marketdata(path, template = "Indic")
#' path <- "PUWEB.TXT"
#' df <- read_marketdata(path, template = "PUWEB")
#' }
#' @export
read_marketdata <- function(filename, template = NULL,
                            parse_fields = TRUE,
                            do_cache = TRUE) {
  if (file.size(filename) <= 2) {
    msg <- str_glue("File is empty: {b}", b = filename)
    stop(empty_file_error(msg))
  }
  template <- template_retrieve(template)
  basename_ <- str_replace(basename(filename), "\\.[^\\.]+$", "") |>
    str_replace("\\.", "_")
  parsed_ <- if (parse_fields) "parsed" else "strict"
  cache_folder <- dirname(filename)
  f_cache <- file.path(
    cache_folder, str_glue("{b}-{p}.rds", b = basename_, p = parsed_)
  )

  if (file.exists(f_cache) && do_cache) {
    df_ <- read_rds(f_cache)
    if (is.null(df_)) {
      alert("warning", "Removed cached file {f_cache} that returns NULL.",
        f_cache = f_cache
      )
      unlink(f_cache)
    }
    return(df_)
  }
  df <- template$read_file(template, filename, parse_fields)
  if (is.null(df)) {
    rb3_clear_cache <- getOption("rb3.clear.cache")
    if (!is.null(rb3_clear_cache) && isTRUE(rb3_clear_cache)) {
      alert(
        "warning",
        "Removed {filename} - It hasn't valid content.",
        filename = filename
      )
      unlink(filename)
    } else {
      alert(
        "warning",
        "{filename} hasn't valid content, consider removing if it is cached.",
        filename = filename
      )
    }
  }
  if (do_cache && !is.null(df)) {
    write_rds(df, f_cache)
  }
  df
}

empty_file_error <- function(message) {
  structure(
    class = c("empty_file_error", "condition"),
    list(message = message, call = sys.call(-1))
  )
}
