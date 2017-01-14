#' @title Read files from Brazilian Financial Market
#'
#' @description
#' Read the many files used in Brazilian Financial Market and
#' convert them into useful formats and data structures.
#'
#' @name rbmfbovespa
#'
#' @docType package
#'
#' @import proto
#' @import stringr
#' @import transmute
NULL

.retrieve_template <- function(filename, template) {
  template <- if (is.null(template))
    MarketData$retrieve_template( tolower(basename(filename)) )
  else
    MarketData$retrieve_template( tolower(template) )
  if (is.null(template))
    stop('Unknown template.')
  template
}

registry <- proto::proto(expr={
  ..container <- list()
  put <- function(., key, value) {
    .$..container[[key]] <- value
    invisible(NULL)
  }

  get <- function(., key) {
    val <- try(base::get(key, .$..container), TRUE)
    if (is(val, 'try-error')) NULL else val
  }
})

NUMERIC.TRANSMUTER <- transmute::transmuter(
  match_regex('^\\d+$', as.integer),
  match_regex('^\\d+\\.\\d+$', as.numeric)
)

#' @export
MarketData <- proto::proto(expr={

  ..registry <- registry

  register <- function(., .class) {
    name <- deparse(substitute(.class))
    .class$init()
    .$..registry$put(tolower(name), .class)

    filename <- try(.class$filename)
    if (! is(filename, 'try-error'))
      .$..registry$put(tolower(filename), .class)
  }

  parser <- NUMERIC.TRANSMUTER

  retrieve_template <- function(., key) {
    .$..registry$get(key)
  }

  transform <- function(., df) identity(df)

  print <- function(.) {
    cat('Expected filename:', .$filename, '\n')
    cat('File type:', .$file_type, '\n')
    if (is(.$fields, 'fields')) {
      cat('\n')
      print.fields(.$fields)
    } else {
      parts_names <- names(.$parts)
      ix <- 0
      for (nx in parts_names) {
        ix <- ix + 1
        cat('\n')
        cat(sprintf('Part %d: %s\n', ix, nx))
        # if (! is.null(.$parts[[nx]]$lines))
        #   cat('Lines:', .$parts[[nx]]$lines, '\n')
        # else
        #   cat('Pattern:', .$parts[[nx]]$pattern, '\n')
        cat('\n')
        print.fields(.$parts[[nx]]$fields)
      }
    }
  }
})

#' @export
MarketDataFWF <- MarketData$proto(expr={
  file_type <- 'Fixed Width'
  read_file <- function(., filename, parse_fields=TRUE) {
    df <- read_fwf(filename, .$widths, colnames=.$colnames)
    if (parse_fields) {
      df <- trim_fields(df)
      e <- evalq(environment(), df, NULL)
      df <- lapply(.$colnames, function(x) {
        fun <- .$handlers[[x]]
        x <- df[[x]]
        do.call(fun, list(x), envir=e)
      })
      names(df) <- .$colnames
      df <- do.call('data.frame', c(df, stringsAsFactors=FALSE, check.names=FALSE))
      df <- transmute(.$parser, df)
    }
    df
  }

  init <- function(.) {
    .$colnames <- fields_names(.$fields)
    .$widths <- fields_widths(.$fields)
    .$handlers <- fields_handlers(.$fields)
  }
})

#' @export
MarketDataCSV <- MarketData$proto(expr={
  file_type <- 'Comma-separated Values'
  read_file <- function(., filename, parse_fields=TRUE) {
    df <- read.table(filename, col.names=.$colnames, sep=.$separator,
                     as.is=TRUE, stringsAsFactors=FALSE)
    if (parse_fields) {
      df <- trim_fields(df)
      e <- evalq(environment(), df, NULL)
      df <- lapply(.$colnames, function(x) {
        fun <- .$handlers[[x]]
        x <- df[[x]]
        do.call(fun, list(x), envir=e)
      })
      names(df) <- .$colnames
      df <- do.call('data.frame', c(df, stringsAsFactors=FALSE, check.names=FALSE))
      df <- transmute(.$parser, df)
    }
    df
  }
})

#' @export
MarketDataMultiPart <- MarketData$proto(expr={

  .detect_lines <- function(., .part, lines) {
    if (is.null(.part$pattern))
      .part$lines
    else
      stringr::str_detect(lines, .part$pattern)
  }

  init <- function(.) {
    for (idx in seq_along(.$parts)) {
      .$parts[[idx]]$colnames <- fields_names(.$parts[[idx]]$fields)
      .$parts[[idx]]$handlers <- fields_handlers(.$parts[[idx]]$fields)
      .$parts[[idx]]$widths <- fields_widths(.$parts[[idx]]$fields)
    }
  }
})

#' @export
MarketDataMultiPartCSV <- MarketDataMultiPart$proto(expr={
  file_type <- 'Comma-separated Values (with Multiple Parts)'
  .separator <- function(., .part=NULL) {
    if (is.null(.part))
      .$separator
    else {
      sep <- try(.part$separator)
      if (is(sep, 'try-error') || is.null(sep))
        .$separator
      else
        sep
    }
  }

  read_file <- function(., filename, parse_fields=TRUE) {
    lines <- readLines(filename)
    l <- list()
    for (part_name in names(.$parts)) {
      part <- .$parts[[part_name]]
      idx <- .$.detect_lines(part, lines) # stringr::str_detect(lines, part$pattern)
      df <- read.table(text=lines[idx], col.names=part$colnames, sep=.$.separator(part),
                       as.is=TRUE, stringsAsFactors=FALSE, check.names=FALSE, colClasses='character')
      if (parse_fields) {
        df <- trim_fields(df)
        e <- evalq(environment(), df, NULL)
        df <- lapply(part$colnames, function(x) {
          fun <- part$handlers[[x]]
          x <- df[[x]]
          do.call(fun, list(x), envir=e)
        })
        names(df) <- part$colnames
        df <- do.call('data.frame', c(df, stringsAsFactors=FALSE, check.names=FALSE))
        df <- transmute(.$parser, df)
      }
      l[[part_name]] <- df
    }
    l
  }
})

#' @export
MarketDataMultiPartFWF <- MarketDataMultiPart$proto(expr={
  file_type <- 'Fixed Width (with Multiple Parts)'
  read_file <- function(., filename, parse_fields=TRUE) {
    lines <- readLines(filename)
    l <- list()
    for (part_name in names(.$parts)) {
      part <- .$parts[[part_name]]
      idx <- .$.detect_lines(part, lines)
      # print(part)
      df <- read_fwf(text=lines[idx], widths=part$widths, colnames=part$colnames)
      if (parse_fields) {
        df <- trim_fields(df)
        e <- evalq(environment(), df, NULL)
        df <- lapply(part$colnames, function(x) {
          fun <- part$handlers[[x]]
          x <- df[[x]]
          do.call(fun, list(x), envir=e)
        })
        names(df) <- part$colnames
        df <- do.call('data.frame', c(df, stringsAsFactors=FALSE, check.names=FALSE))
        df <- transmute(.$parser, df)
      }
      l[[part_name]] <- df
    }
    l
  }
})

#' @export
describe_template <- function(template) {
  MarketData$retrieve_template(template)$print()
}
