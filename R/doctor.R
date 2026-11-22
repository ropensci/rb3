#' One tibble shape for every finding of the doctor
#' @noRd
doctor_findings <- function(template = character(), layer = character(), check = character(),
                            refdate = as.Date(character()), reason = character(), detail = character()) {
  dplyr::tibble(
    template = as.character(template), layer = as.character(layer), check = as.character(check),
    refdate = as.Date(refdate), reason = as.character(reason), detail = as.character(detail)
  )
}

#' Read the download records, optionally for one template
#' @noRd
doctor_records <- function(template = NULL) {
  query <- "SELECT download_checksum, template, download_args_json, downloaded, is_downloaded, is_processed, is_valid FROM meta"
  params <- NULL
  if (!is.null(template)) {
    query <- paste(query, "WHERE template = ?")
    params <- list(template)
  }
  recs <- DBI::dbGetQuery(meta_db_connection(), query, params = params)
  recs$download_args <- lapply(recs$download_args_json, function(j) {
    if (is.na(j)) list() else as.list(jsonlite::fromJSON(j))
  })
  recs$downloaded <- lapply(recs$downloaded, function(x) as.character(unlist(.meta_deserialize_obj(x))))
  for (col in c("is_downloaded", "is_processed", "is_valid")) recs[[col]] <- as.logical(recs[[col]])
  recs
}

#' A record is stale when its template is gone or its arguments differ from the template's
#' @noRd
doctor_is_stale <- function(template, args) {
  tpl <- tryCatch(template_retrieve(template), error = function(e) NULL)
  is.null(tpl) || !setequal(names(args), names(tpl$downloader$args))
}

#' Health checks of the records and of the raw folder
#' @noRd
doctor_health <- function(template = NULL) {
  recs <- doctor_records(template)
  detail <- purrr::map_chr(recs$download_args, ~ meta_args_str(list(download_args = .x)))

  stale <- purrr::map2_lgl(recs$template, recs$download_args, doctor_is_stale)
  missing <- recs$is_downloaded & purrr::map_lgl(recs$downloaded, ~ length(.x) == 0 || !all(file.exists(.x)))
  out <- list(
    doctor_findings(recs$template[stale], NA, "stale_meta", NA, NA, detail[stale]),
    doctor_findings(
      recs$template[missing], NA, "missing_raw", NA, NA,
      paste0(detail[missing], " (", purrr::map_chr(recs$downloaded[missing], ~ paste(basename(.x), collapse = ", ")), ")")
    )
  )
  if (is.null(template)) {
    # compare by file name: `downloaded` is stored with dput(), see meta_unlink_raw()
    raw <- list.files(rb3_registry$get_instance()$raw_folder)
    orphan <- setdiff(raw, basename(as.character(unlist(recs$downloaded))))
    out <- c(out, list(doctor_findings(NA, NA, "orphan_raw", NA, NA, orphan)))
  }
  dplyr::bind_rows(out)
}

DOCTOR_STATUS <- c("download_failed", "not_read", "no_data", "ok") # worst to best

#' Status of a download record, as in fetch_report()
#' @noRd
doctor_record_status <- function(recs) {
  ifelse(!recs$is_downloaded, "download_failed",
    ifelse(!recs$is_processed, "not_read", ifelse(!recs$is_valid, "no_data", "ok"))
  )
}

#' Business days of the period without rows in a layer, with the reason for each
#' @noRd
doctor_gaps <- function(template, layer = "input", from = NULL, to = NULL, calendar = NULL) {
  tpl <- template_retrieve(template)
  if (is.null(tpl$writers[[layer]])) {
    cli::cli_abort("Template {.strong {template}} has no {.val {layer}} layer", class = "error_doctor_layer")
  }
  args <- names(tpl$downloader$args)
  by_year <- !"refdate" %in% args
  if (by_year && !"year" %in% args) {
    cli::cli_alert_info("Template {.strong {template}} has no time series (no {.arg refdate} or {.arg year} argument): gaps not checked")
    return(doctor_findings())
  }
  if (!"refdate" %in% template_schema(tpl, layer)$names) {
    cli::cli_abort(
      "The {.val {layer}} layer of {.strong {template}} has no {.field refdate} column, try {.code layer = \"staging\"}",
      class = "error_doctor_layer"
    )
  }
  present <- template_dataset(tpl, layer) |>
    dplyr::distinct(.data$refdate) |>
    dplyr::collect() |>
    dplyr::pull("refdate")
  if (length(present) == 0 && (is.null(from) || is.null(to))) {
    cli::cli_abort(
      "No data in the {.val {layer}} layer of {.strong {template}}: pass {.arg from} and {.arg to}",
      class = "error_doctor_layer"
    )
  }
  from <- as.Date(from %||% min(present))
  to <- as.Date(to %||% max(present))

  calendar <- calendar %||% tpl$calendar
  if (is.null(calendar)) {
    cli::cli_abort(
      "Template {.strong {template}} defines no calendar: pass one in {.arg calendar}, e.g. {.code calendar = \"Brazil/B3\"}",
      class = "error_doctor_calendar_missing"
    )
  }
  expected <- tryCatch(bizdays::bizseq(from, to, calendar), error = function(e) {
    cal <- bizdays::calendars()[[calendar]]
    cli::cli_abort(
      c("Period {from} to {to} is outside the {.val {calendar}} calendar",
        i = "The calendar covers {cal$start.date} to {cal$end.date}"),
      class = "error_doctor_calendar", parent = e
    )
  })
  missing <- expected[!expected %in% present]

  recs <- doctor_records(template)
  recs <- recs[!purrr::map2_lgl(recs$template, recs$download_args, doctor_is_stale), ]
  rank <- match(doctor_record_status(recs), DOCTOR_STATUS)
  rec_key <- if (by_year) {
    as.integer(purrr::map_chr(recs$download_args, ~ as.character(.x$year)))
  } else {
    as.Date(purrr::map_chr(recs$download_args, ~ as.character(.x$refdate)))
  }
  miss_key <- if (by_year) as.integer(format(missing, "%Y")) else missing
  best <- purrr::map_int(seq_along(missing), function(i) {
    r <- rank[rec_key == miss_key[i]]
    if (length(r) == 0) NA_integer_ else max(r)
  })
  reason <- ifelse(is.na(best), "never_fetched", DOCTOR_STATUS[best])
  reason[reason == "ok"] <- "not_in_layer"

  res <- doctor_findings(template, layer, "gap", missing, reason, NA)
  attr(res, "period") <- list(from = from, to = to, n_days = length(expected), n_with_data = sum(expected %in% present))
  res
}
