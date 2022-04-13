
as.list.field <- function(x, ...) {
  list(
    name = as.character.default(x),
    description = attr(x, "description"),
    width = as.character(attr(x, "width")),
    handler = as.list.handler(attr(x, "handler"))
  )
}

as.list.handler <- function(x, ...) {
  handler <- list(
    type = attr(x, "type")
  )

  if (handler$type == "numeric") {
    handler[["dec"]] <- attr(handler, "dec")
    handler[["sign"]] <- attr(handler, "sign")
  } else if (handler$type == "factor") {
    handler[["levels"]] <- attr(handler, "levels")
    handler[["labels"]] <- attr(handler, "labels")
  } else if (handler$type == "Date" || handler$type == "POSIXct") {
    handler[["format"]] <- attr(handler, "format")
  }

  handler
}

as.character.width <- function(x, ...) {
  as.character(unclass(x))
}

as.character.field <- function(x, ...) {
  as.list(x) |> jsonlite::toJSON(auto_unbox = TRUE)
}

print.field <- function(x, ...) {
  cat(as.character(x), "\n")
  invisible(x)
}

f <- field("id_transacao", "Identificação da transação", width(6), to_numeric())
as.list(f)