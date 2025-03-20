
ifnull <- function(x, value) {
  if (!is.null(x)) x else value
}

new_template <- function(id, description = "") {
  obj <- list(id = id, description = description)
  obj$readers <- list()
  structure(obj, class = "template")
}

new_downloader <- function(downloader) {
  obj <- list()
  # - function
  # - url
  # - ext
  # - encoding
  # - if-has-multiple-files-use
  obj$function <- getFromNamespace(downloader$function, "rb3")
  obj$url <- downloader$url
  obj$ext <- downloader$ext
  obj$encoding <- ifnull(downloader$encoding, "UTF-8")
  obj[["if-has-multiple-files-use"]] <- downloader[["if-has-multiple-files-use"]]
  structure(obj, class = "downloader")
}

new_reader <- function(reader) {
  obj <- list()
  # - function
  # - partition
  # - locale
  # - encoding
  obj$function <- getFromNamespace(reader$function, "rb3")
  obj$partition <- reader$partition
  obj$locale <- if (!is.null(reader$locale)) do.call(readr::locale, reader$locale) else readr::locale()
  obj$encoding <- ifnull(reader$encoding, "UTF-8")
  structure(obj, class = "reader")
}

`template_downloader<-` <- function(template, value) {
  template$downloader <- new_downloader(value)
  template
}

`template_add_reader<-` <- function(template, value) {
  if (!is(value, "list")) stop("value must be a list")
  if (length(value) > 1) stop("value must have length equal to 1")
  template$readers[[names(value[1])]] <- new_reader(value[[1]])
  template
}