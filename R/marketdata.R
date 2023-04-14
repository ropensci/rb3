
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
  template <- .retrieve_template(filename, template)
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
  df <- template$read_file(filename, parse_fields)
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

.retrieve_template <- function(filename, template) {
  template <- if (is.null(template)) {
    MarketData$retrieve_template(basename(filename))
  } else {
    MarketData$retrieve_template(template)
  }
  if (is.null(template)) {
    stop("Unknown template.")
  }
  template
}

registry <- proto(expr = {
  .container <- list()
  put <- function(., key, value) {
    if (!is.null(key)) {
      .$.container[[key]] <- value
    }
    invisible(NULL)
  }

  get <- function(., key) {
    val <- try(base::get(key, .$.container), TRUE)
    if (is(val, "try-error")) NULL else val
  }

  keys <- function(.) {
    names(.$.container)
  }
})

parser_generic <- transmuter(
  match_regex("^(-|\\+)?\\d{1,8}$", to_int(), priority = 1, apply_to = "all"),
  match_regex("^(-|\\+)?\\d{1,8}$", to_int()),
  match_regex("^\\+|-$", function(text, match) {
    idx <- text == "-"
    x <- rep(1, length(text))
    x[idx] <- -1
    x
  }, apply_to = "all"),
  match_regex("^(S|N)$", function(text, match) {
    text == "S"
  }, apply_to = "all")
)

parsers <- list(
  generic = parser_generic,
  en = transmuter(
    match_regex("^(-|\\+)?(\\d+,)*\\d+(\\.\\d+)?$",
      to_dbl(dec = ".", thousands = ","),
      apply_to = "all", priority = 2
    ),
    match_regex(
      "^(-|\\+)?(\\d+,)*\\d+(\\.\\d+)?$",
      to_dbl(dec = ".", thousands = ",")
    ), parser_generic
  ),
  pt = transmuter(
    match_regex("^(-|\\+)?(\\d+\\.)*\\d+(,\\d+)?$",
      to_dbl(dec = ",", thousands = "."),
      apply_to = "all", priority = 2
    ),
    match_regex(
      "^(-|\\+)?(\\d+\\.)*\\d+(,\\d+)?$",
      to_dbl(dec = ",", thousands = ".")
    ), parser_generic
  )
)

MarketData <- proto(expr = {
  description <- ""

  ..registry.id <- registry$proto()
  ..registry.filename <- registry$proto()

  register <- function(., .class) {
    .class$init()

    # if the class is super (i.e has "name") then add to index
    if (any(.class$ls() == "id")) {
      .$..registry.id$put(.class$id, .class)
    }

    filename <- try(.class$filename)
    if (!is(filename, "try-error")) {
      .$..registry.filename$put(filename, .class)
    }
  }

  retrieve_template <- function(., key) {
    .$..registry.id$get(key)
  }

  show_templates <- function(.) {
    map_dfr(.$..registry.id$keys(), function(cls) {
      tpl_ <- .$..registry.id$get(cls)
      tibble(
        "Description" = tpl_$description,
        "Template" = tpl_$id,
        "Reader" = ifelse(tpl_$has_reader, "\U2705", "\U274C"),
        "Downloader" = ifelse(tpl_$has_downloader, "\U2705", "\U274C")
      )
    })
  }

  transform <- function(., df) identity(df)

  print <- function(.) {
    cat("Template ID:", .$id, "\n")
    cat("Expected filename:", .$filename, "\n")
    cat("File type:", .$filetype, "\n")
    if (is(.$fields, "fields")) {
      cat("\n")
      print.fields(.$fields)
    } else {
      parts_names <- names(.$parts)
      ix <- 0
      for (nx in parts_names) {
        ix <- ix + 1
        cat("\n")
        cat(sprintf("Part %d: %s\n", ix, nx))
        cat("\n")
        print.fields(.$parts[[nx]]$fields)
      }
    }
    invisible(NULL)
  }

  .parser <- function(.) {
    locale <- try(.$locale, TRUE)
    if (is(locale, "try-error") || !is(locale, "character")) {
      parsers[["generic"]]
    } else {
      parsers[[locale]]
    }
  }

  .separator <- function(., .part = NULL) {
    if (is.null(.part)) {
      .$separator
    } else {
      sep <- try(.part$separator, TRUE)
      if (is(sep, "try-error") || is.null(sep)) {
        .$separator
      } else {
        sep
      }
    }
  }

  .detect_lines <- function(., .part, lines) {
    if (!is.null(.part$pattern)) {
      str_detect(lines, .part$pattern)
    } else if (!is.null(.part$index)) {
      .part$index
    } else {
      stop("MultiPart file with no index defined")
    }
  }

  init <- function(.) {
    .$colnames <- fields_names(.$fields)
    .$widths <- fields_widths(.$fields)
    .$handlers <- fields_handlers(.$fields)
  }
})
