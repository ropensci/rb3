
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
	classes <- sapply(parms, function(x) {
		if (is(x, 'width'))
			'width'
		else if (is(x, 'handler'))
			'handler'
		else
			NULL
	})

	print(unname(unlist(classes)))
	if (any(classes == 'width'))
		attr(name, 'width')   <- parms[[ which(classes == 'width')[1] ]]
	else
		attr(name, 'width') <- 0

	if (any(classes == 'handler'))
		attr(name, 'handler')   <- parms[[ which(classes == 'handler')[1] ]]
	else
		attr(name, 'handler') <- identity
	
	class(name) <- 'field'
	name
}

print.field <- function(x, ...) {
	cat(as.character(x), '\n')
}

