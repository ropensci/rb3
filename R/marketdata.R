#' @title Read files from Brazilian Financial Market
#' 
#' @description 
#' Read the many files used in Brazilian Financial Market and 
#' convert them into useful formats and data structures.
#' 
#' @name marketdataBR
#' 
#' @docType package
#' 
#' @import proto
#' @import stringr
#' @import textparser
NULL

.retrieve_template <- function(filename, template) {
	template <- if (is.null(template))
		MarketData$retrieve_template( basename(filename) )
	else
		MarketData$retrieve_template(template)
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

.PARSER <- textparser::textparser(
	parse_numeric=textparser::parser('^\\d+$', function(text, match) {
		as.numeric(text)
	}),
	parse_decimal=textparser::parser('^\\d+\\.\\d+$', function(text, match) {
		as.numeric(text)
	}),
)

MarketData <- proto::proto(expr={
	
	..registry <- registry
	
	register <- function(., .class) {
		filename <- try(.class$filename)
		if (! is(filename, 'try-error'))
			.$..registry$put(filename, .class)
		.$..registry$put(.class$name, .class)
	}
	
	parser <- .PARSER
	
	retrieve_template <- function(., key) .$..registry$get(key)
	
	transform <- function(., df) identity(df)
})

MarketDataFWF <- MarketData$proto(expr={
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
			df <- .$parser$parse(df)
		}
		df
	}
})

