
read_fwf <- function(fname, widths, col.names=NULL, skip=0) {
    l <- list()
    x <- 1
    i <- 1
    for (y in widths) {
        l[[i]] <- c(x, x+y-1)
        x <- x + y
        i <- i + 1
    }
    
    if (is.null(col.names))
        col.names <- paste0('V', seq_along(widths))
    
    lines <- readLines(fname)
    t <- list()
    for (i in seq_along(widths)) {
        dx <- l[[i]]
        t[[col.names[i]]] <- substr(lines, dx[1], dx[2])
    }
    
    if (skip)
        as.data.frame(t, stringsAsFactors=FALSE)[-seq(skip),]
    else
        as.data.frame(t, stringsAsFactors=FALSE)
}


