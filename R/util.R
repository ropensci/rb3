

read_fwf <- function(fname, widths, colnames=NULL, skip=0, text) {
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

	lines <- if (missing(text)) readLines(fname) else text

	if (skip)
		lines <- lines[-seq(skip),]

	t <- list()
	for (i in seq_along(colnames)) {
		dx <- colpositions[[i]]
		t[[colnames[i]]] <- substr(lines, dx[1], dx[2])
	}

	as.data.frame(t, stringsAsFactors=FALSE, optional=TRUE, check.names=FALSE)
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

