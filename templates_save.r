
devtools::load_all()
library(yaml)

as_list_field <- function(x, ...) {
  l <- list(
    name = as.character.default(x),
    description = enc2utf8(attr(x, "description")),
    handler = as_list_handler(attr(x, "handler"))
  )

  if (!is.null(attr(x, "width")) && as.integer(attr(x, "width")) > 0) {
    l[["width"]] <- as.integer(attr(x, "width"))
  }

  l
}

as_list_handler <- function(x, ...) {
  handler <- list(type = as.character(attr(x, "type")))

  if (handler$type == "numeric") {
    handler[["dec"]] <- attr(x, "dec")
    handler[["sign"]] <- attr(x, "sign")
  } else if (handler$type == "factor") {
    handler[["levels"]] <- if (!is.null(attr(x, "levels"))) {
      lvl <- attr(x, "levels")
      if (is.numeric(lvl))
        lvl
      else {
        enc2utf8(lvl)
      }
    } else {
      NULL
    }
    handler[["labels"]] <- if (!is.null(attr(x, "labels"))) {
      enc2utf8(attr(x, "labels"))
    } else {
      NULL
    }
  } else if (handler$type == "Date" || handler$type == "POSIXct") {
    handler[["format"]] <- attr(x, "format")
  } else if (handler$type == "character") {
  } else {
    stop("as_list_handler: None type", handler)
  }

  handler
}

set_if_exists <- function(x, l, name) {
  if (exists(name, x)) {
    l[[name]] <- x[[name]]
  }
  l
}

to_list <- function(x) {
  l <- list(
    id = enc2utf8(x$id),
    filename = enc2utf8(x$filename),
    filetype = x$file_type,
    description = enc2utf8(x$description)
  )

  l <- set_if_exists(x, l, "separator")

  if (is(x$fields, "fields")) {
    l[["fields"]] <- lapply(x$fields, as_list_field)
  } else {
    l[["parts"]] <- list()
    parts_names <- names(x$parts)
    for (nx in parts_names) {
      lx <- list()
      lx[["pattern"]] <- x$parts[[nx]][["pattern"]]
      lx[["fields"]] <- lapply(x$parts[[nx]][["fields"]], as_list_field)
      l[["parts"]][[enc2utf8(nx)]] <- lx
    }
  }
  l
}

save_yaml <- function(x) {
  tpl <- to_list(x)
  fname <- str_glue("inst/extdata/templates/{tpl$id}.yaml")
  fcon <- file(fname, "w+", encoding = "utf8")
  writeLines(as.yaml(tpl), fcon)
  close(fcon)
}

# to_list(BDPrevia) |> as.yaml() |> cat()

save_yaml(BD_Arbit)
save_yaml(BDIN)
save_yaml(ContrCad)
save_yaml(COTAHIST)
save_yaml(DeltaOpcoes)
save_yaml(Eletro)
save_yaml(Indic)
save_yaml(ISIND)
save_yaml(ISINS)
save_yaml(Premio)
save_yaml(PremioOpcaoAcao)
save_yaml(PUWEB)
save_yaml(SupVol)
save_yaml(TaxaSwap)
