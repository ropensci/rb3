

read_fwf <- function(fname, widths, colnames=NULL, skip=0) {
    colpositions <- list()
    x <- 1
    i <- 1
    for (y in widths) {
        colpositions[[i]] <- c(x, x+y-1)
        x <- x + y
        i <- i + 1
    }
    
    if (is.null(colnames))
        colnames <- paste0('V', seq_along(widths))
    
    lines <- readLines(fname)
    if (skip)
        lines <- lines[-seq(skip),]
    
    t <- list()
    for (i in seq_along(colnames)) {
        dx <- colpositions[[i]]
        t[[colnames[i]]] <- substr(lines, dx[1], dx[2])
    }
    
    # lapply(colpositions, function(positions) {
    #     substr(lines, dx[1], dx[2])
    # })
    
    as.data.frame(t, stringsAsFactors=FALSE, optional=TRUE)
}


trim_fields <- function(x) {
	fields <- lapply(x, function(z) {
		if (is(z, 'character'))
			stringr::str_trim(z)
		else
			z
	})
	do.call('data.frame', c(fields, stringsAsFactors=FALSE, check.names=FALSE))
}

fields <- function(...) {
	that <- list(...)
	class(that) <- 'fields'
	that
}

fields_names <- function(x) UseMethod('fields_names', x)

fields_widths <- function(x) UseMethod('fields_widths', x)

fields_handlers <- function(x) UseMethod('fields_handlers', x)

fields_names.fields <- function(fields) {
	unname(sapply(fields, function(x) as.character(x)))
}

fields_widths.fields <- function(fields) {
	unname(sapply(fields, function(x) attr(x, 'width')))
}

fields_handlers.fields <- function(fields) {
	handlers <- lapply(fields, function(x) attr(x, 'handler'))
	names(handlers) <- fields_names(fields)
	handlers
}

field <- function(name, ...) {
	parms <- list(...)
	attr(name, 'width')   <- if (!is.null(parms[['width']]))   parms[['width']]   else 0
	attr(name, 'handler') <- if (!is.null(parms[['handler']])) parms[['handler']] else identity
	class(name) <- 'field'
	name
}

print.field <- function(x, ...) {
	cat(as.character(x), '\n')
}

to_date <- function(format=NULL) {
	if (is.null(format))
		format <- '%Y-%m-%d'
	function(x) {
		as.Date(x, format=format)
	}
}

to_time <- function(format=NULL) {
	if (is.null(format))
		format <- '%H:%M:%S'
	function(x) {
		strptime(x, format=format)
	}
}

to_factor <- function(levels=NULL, labels=levels) {
	function(x) {
		if (is.null(levels))
			factor(x)
		else
			factor(x, levels=levels, labels=labels)
	}
}

to_numeric <- function(dec=0, sign='') {
	function(x) {
		if (is(dec, 'character'))
			dec <- get(dec, envir=parent.frame())
		if (! sign %in% c('+', '-', ''))
			sign <- get(sign, envir=parent.frame())
		x <- paste0(sign, x)
		as.numeric(x)/(10^as.numeric(dec))
	}
}