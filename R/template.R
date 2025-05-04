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

#' @details
#' The `template_meta_load` function checks that all required arguments for the template
#' are provided. If any required arguments are missing, it will abort with
#' an error of class "error_template_missing_args".
#' It raises an error if the template is not found or if the required arguments are not
#' provided. The error message will indicate which arguments are missing.
#' 
#' @rdname template_meta_create_or_load
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
  tryCatch(
    check_args(..., required_args = names(template$downloader$args)),
    error = function(e) {
      cli::cli_abort("Required arguments not provided", class = "error_template_missing_args", parent = e)
    }
  )
  extra_arg <- template_extra_arg(template)
  meta_load(template$id, ..., extra_arg = extra_arg)
}

#' @details
#' The `template_meta_new` function checks that all required arguments for the template
#' are provided. If any required arguments are missing, it will abort with
#' an error of class "error_template_missing_args".
#' It raises an error if the template already exists in the database.
#'   
#' @rdname template_meta_create_or_load
#' @export
template_meta_new <- function(template, ...) {
  UseMethod("template_meta_new")
}

#' @export
template_meta_new.default <- function(template, ...) {
  template_retrieve(template) |> template_meta_new.template(...)
}

#' @export
template_meta_new.template <- function(template, ...) {
  tryCatch(
    check_args(..., required_args = names(template$downloader$args)),
    error = function(e) {
      cli::cli_abort("Required arguments not provided", class = "error_template_missing_args", parent = e)
    }
  )
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

#' Create or Load Template Metadata
#'
#' @description
#' These functions attempt to create new template metadata objects or load existing ones.
#'
#' @param template An object representing the template. Can be of class `character`
#'   (template ID) or `template` (template object).
#' @param template_name Character string specifying the template ID.
#' @param ... Additional arguments to be passed to the metadata creation process.
#'   These should include all required arguments specified in the template definition.
#'
#' @return The created or loaded template metadata object
#' 
#' @details The `template_meta_create_or_load` function is a safe way to create
#' or load template metadata. It first attempts to create a new metadata object
#' using the provided arguments. If that fails (e.g., if the template already exists),
#' it will attempt to load the existing metadata object. This is useful for ensuring
#' that you always have access to the latest metadata for a given template.
#' 
#' @examples
#' \dontrun{
#' # Create or load metadata for a template
#' meta <- template_meta_create_or_load("b3-reference-rates",
#'   refdate = as.Date("2024-04-05"),
#'   curve_name = "PRE"
#' )
#' }
#'
#' @export
template_meta_create_or_load <- function(template_name, ...) {
  tryCatch(
    template_meta_new(template_name, ...),
    error = function(e) {
      template_meta_load(template_name, ...)
    }
  )
}

check_args <- function(..., required_args) {
  args <- list(...)
  for (arg_name in required_args) {
    if (!utils::hasName(args, arg_name)) {
      cli::cli_abort("{arg_name} argument not provided")
    }
  }
}

template_download_marketdata <- function(template, dest, ...) {
  template$download_marketdata(template, dest, ...)
}
