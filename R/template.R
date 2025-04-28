new_template <- function(id, description = "") {
  obj <- list(id = id, description = description)
  structure(obj, class = "template")
}

load_template_from_file <- function(fname) {
  tpl <- yaml::yaml.load_file(fname)
  obj <- new_template(tpl$id)
  for (n in names(tpl)) {
    if (n == "fields") {
      obj[["fields"]] <- do.call(fields, lapply(tpl$fields, new_field))
    } else if (n == "parts") {
      obj[["parts"]] <- lapply(tpl$parts, new_part)
    } else if (n == "reader") {
      obj[["reader"]] <- tpl$reader
      func_name <- tpl$reader[["function"]]
      obj[["read_file"]] <- utils::getFromNamespace(func_name, "rb3")
    } else if (n == "writers") {
      writers_names <- names(tpl$writers)
      writers <- lapply(writers_names, function(n) {
        w <- tpl$writers[[n]]
        w$layer <- n
        if (!is.null(w[["function"]])) {
          w$process_marketdata <- utils::getFromNamespace(w[["function"]], "rb3")
        } else {
          w$process_marketdata <- identity
        }
        if (!is.null(w[["fields"]])) {
          fields_pairs <- lapply(names(w$fields), function(name) list(name = name, type = w$fields[[name]]))
          w[["fields"]] <- do.call(fields, lapply(fields_pairs, new_field))
        }
        w
      })
      obj[["writers"]] <- stats::setNames(writers, writers_names)
    } else if (n == "downloader") {
      obj[["downloader"]] <- tpl$downloader
      func_name <- tpl$downloader[["function"]]
      obj[["download_marketdata"]] <- utils::getFromNamespace(func_name, "rb3")
    } else {
      obj[[n]] <- tpl[[n]]
    }
  }

  if (is.null(obj$reader)) {
    reader_name <- paste0(str_to_lower(obj$filetype), "_read_file")
    obj[["read_file"]] <- utils::getFromNamespace(reader_name, "rb3")
    obj[["has_reader"]] <- TRUE
  }

  if (obj$filetype %in% c("MCSV", "MFWF", "MCUSTOM")) {
    for (idx in seq_along(obj$parts)) {
      obj$parts[[idx]]$colnames <- fields_names(obj$parts[[idx]]$fields)
      obj$parts[[idx]]$handlers <- fields_handlers(obj$parts[[idx]]$fields)
      obj$parts[[idx]]$widths <- fields_widths(obj$parts[[idx]]$fields)
    }
  } else {
    obj$colnames <- fields_names(obj$fields)
    obj$widths <- fields_widths(obj$fields)
    obj$handlers <- fields_handlers(obj$fields)
  }

  template_register(obj)
  obj
}

load_template_files <- function() {
  dir <- system.file("extdata/templates/",
    package = "rb3",
    mustWork = TRUE
  )
  files <- list.files(dir, full.names = TRUE)
  for (file in files) {
    load_template_from_file(file)
  }
}

#' @exportS3Method base::print
print.template <- function(x, ...) {
  cli::cli_text("{.strong Template}: {.emph {x$id}}")
  cli::cli_text("{.strong Description}: {.emph {x$description}}")
  if (!is.null(x$downloader$args)) {
    cli::cli_text("{.strong Required arguments}:")
    ulid <- cli::cli_ul()
    for (arg in names(x$downloader$args)) {
      cli::cli_li("{.strong {arg}}: {x$downloader$args[[arg]]}")
    }
    cli::cli_end(ulid)
  }
  # cat("Template:", x$id, "\n")
  if (inherits(x$fields, "fields")) {
    cli::cli_text("{.strong Fields}: ")
    print.fields(x$fields)
  } else {
    parts_names <- names(x$parts)
    ix <- 0
    for (nx in parts_names) {
      ix <- ix + 1
      cat("\n")
      cat(sprintf("Part %d: %s\n", ix, nx))
      cat("Fields: ")
      print.fields(x$parts[[nx]]$fields)
    }
  }
  invisible(NULL)
}

template_registry <- create_registry()

template_register <- function(obj) {
  # if the class is super (i.e has "name") then add to index
  .reg <- template_registry$get_instance()
  .reg[[obj$id]] <- obj
}

#' Retrieve a template by its name
#'
#' This function retrieves a template identified by its name.
#'
#' @param template_name The name identifying the template to retrieve.
#'
#' @return The template associated with the given name.
#'
#' @export
template_retrieve <- function(template_name) {
  .reg <- template_registry$get_instance()
  .reg[[template_name]]
}

#' List Available Templates
#'
#' Retrieves all templates registered in the template registry and returns their properties
#' as a tibble.
#'
#' @return A tibble with the following columns:
#' \describe{
#'   \item{Description}{The description of the template}
#'   \item{Template}{The template identifier}
#' }
#'
#' @examples
#' list_templates()
#'
#' @export
list_templates <- function() {
  .reg <- template_registry$get_instance()
  purrr::map_dfr(registry_keys(.reg), function(cls) {
    tpl_ <- .reg[[cls]]
    dplyr::tibble(
      "Template" = tpl_$id,
      "Description" = tpl_$description,
    )
  })
}

template_schema <- function(template, layer = NULL) {
  layer <- if (is.null(layer)) template$writers[[1]]$layer else template$writers[[layer]]$layer
  stopifnot(!is.null(layer))
  writer <- template$writers[[layer]]
  flds <- if (is.null(writer[["fields"]])) template$fields else writer$fields
  do.call(arrow::schema, fields_arrow_types(flds))
}

template_db_folder <- function(template, layer = NULL) {
  reg <- rb3_registry$get_instance()
  layer <- if (is.null(layer)) template$writers[[1]]$layer else template$writers[[layer]]$layer
  stopifnot(!is.null(layer))
  db_folder <- file.path(reg$db_folder, layer, template$id)
  if (!dir.exists(db_folder)) {
    dir.create(db_folder, recursive = TRUE)
  }
  db_folder
}

#' Access a Dataset for a Template
#'
#' This function provides access to a dataset associated with a specific template.
#' It retrieves the dataset stored in the database folder for the given template and layer,
#' using the schema defined in the template configuration.
#'
#' @param template The template identifier or template object. This specifies the dataset to retrieve.
#' @param layer The layer of the dataset to access (e.g., "input" or "staging"). If `NULL`, the layer `"input` is used.
#'
#' @return An Arrow dataset object representing the data for the specified template and layer.
#'
#' @details
#' The `template_dataset()` function is a generic function that dispatches to specific methods
#' based on the type of the `template` argument. It retrieves the dataset by resolving the template using
#' `template_retrieve()` if the input is a template identifier.
#'
#' @examples
#' \dontrun{
#' # Access the dataset for the "b3-reference-rates" template
#' ds <- template_dataset("b3-reference-rates")
#'
#' # Access the dataset for the "b3-reference-rates" template in the staging layer
#' ds <- template_dataset("b3-reference-rates", layer = "staging")
#'
#' # Query the dataset
#' ds |>
#'   dplyr::filter(refdate > as.Date("2023-01-01")) |>
#'   dplyr::collect()
#' }
#'
#' @export
template_dataset <- function(template, layer = NULL) {
  UseMethod("template_dataset")
}

#' @export
template_dataset.default <- function(template, layer = NULL) {
  template <- template_retrieve(template)
  template_dataset.template(template, layer)
}

#' @export
template_dataset.template <- function(template, layer = NULL) {
  schema <- template_schema(template, layer)
  dir <- template_db_folder(template, layer)
  arrow::open_dataset(dir, schema, hive_style = TRUE, unify_schemas = FALSE)
}

new_part <- function(x) {
  part <- list()
  for (np in names(x)) {
    if (np == "fields") {
      part[["fields"]] <- do.call(fields, lapply(x[["fields"]], new_field))
    } else {
      part[[np]] <- x[[np]]
    }
  }
  part
}

#' Load Metadata for a Template Download
#'
#' These functions provide methods to load metadata associated with a template and the arguments used to a
#' specific download.
#'
#' @param template An object representing the template. Can be of class `character`
#'   (template ID) or `template` (template object).
#' @param ... Additional arguments used in a specific download.
#'
#' @return The metadata associated with the download.
#'
#' @details
#' The `download_marketdata()` function returns a meta object that refers to a specific download.
#' If the meta object does not exist, it is created.
#' If the specific download has already been performed in the past, a meta file will exist, and
#' `download_marketdata()` will raise an error upon detecting it.
#' In such cases, the `template_meta_load()` function should be used to load the meta object
#' associated with the existing meta file.
#'
#' @examples
#' # Example usage with a template ID
#' m <- tryCatch(download_marketdata("b3-indexes-composition"), error = function(e) {
#'   template_meta_load("b3-indexes-composition")
#' })
#' read_marketdata(m)
#'
#' @export
template_meta_load <- function(template, ...) {
  UseMethod("template_meta_load")
}

#' @export
template_meta_load.default <- function(template, ...) {
  template_retrieve(template) |> template_meta_load.template(...)
}

#' @export
template_meta_load.template <- function(template, ...) {
  extra_arg <- template_extra_arg(template)
  meta_load(template$id, ..., extra_arg = extra_arg)
}

template_meta_new <- function(template, ...) {
  extra_arg <- template_extra_arg(template)
  meta_new(template$id, ..., extra_arg = extra_arg)
}

template_extra_arg <- function(template) {
  if (is.null(template$downloader[["extra-arg"]])) {
    NULL
  } else {
    eval(parse(text = template$downloader[["extra-arg"]]))
  }
}
