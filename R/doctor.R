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
  # template_dataset() creates a missing folder; the doctor must not write to the cache
  folder <- file.path(rb3_registry$get_instance()$db_folder, tpl$writers[[layer]]$layer, tpl$id)
  present <- if (dir.exists(folder)) {
    template_dataset(tpl, layer) |>
      dplyr::distinct(.data$refdate) |>
      dplyr::collect() |>
      dplyr::pull("refdate")
  } else {
    as.Date(character())
  }
  present <- present[!is.na(present)] # e.g. header/trailer rows of COTAHIST files
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
  if (!calendar %in% names(bizdays::calendars())) {
    cli::cli_abort("Unknown calendar {.val {calendar}}, see {.code bizdays::calendars()}", class = "error_doctor_calendar")
  }
  if (from > to) {
    cli::cli_abort("{.arg from} ({from}) is after {.arg to} ({to})", class = "error_doctor_period")
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
  # index of the record with the best status for each missing date
  best <- purrr::map_int(seq_along(missing), function(i) {
    idx <- which(rec_key == miss_key[i])
    if (length(idx) == 0) NA_integer_ else idx[which.max(rank[idx])]
  })
  reason <- ifelse(is.na(best), "never_fetched", DOCTOR_STATUS[rank[best]])
  reason[reason == "ok"] <- "not_in_layer"
  detail <- ifelse(is.na(best), NA_character_, purrr::map_chr(best, function(b) {
    if (is.na(b)) NA_character_ else meta_args_str(list(download_args = recs$download_args[[b]]))
  }))

  res <- doctor_findings(template, layer, "gap", missing, reason, detail)
  attr(res, "period") <- list(from = from, to = to, calendar = calendar, n_days = length(expected), n_with_data = sum(expected %in% present))
  res
}

#' Check the health of the rb3 cache
#'
#' `rb3_doctor()` checks the download records (`meta.sqlite`) and the raw files of the cache,
#' and finds the gaps in the time series of a template's dataset layer: business days in a
#' period that have no rows. It only reports; it never changes the cache.
#'
#' @param template A template id (see `list_templates()`). `NULL` (default) runs only the health
#'   checks, for the whole cache.
#' @param layer The dataset layer to check for gaps: `"input"` (default) or `"staging"`.
#' @param from,to The period to check (Date or `"YYYY-MM-DD"`). Defaults: the first and the last
#'   `refdate` in the layer. Use `to = Sys.Date()` to also find recent dates not fetched yet.
#' @param calendar A `bizdays` calendar name. `NULL` (default) uses the template's calendar
#'   (the `calendar` field of its YAML file). Templates without a calendar need this argument.
#'   A value passed here overrides the template's calendar.
#'
#' @details
#' **Health checks** (always; for one template when `template` is given):
#' - `stale_meta`: records whose download arguments differ from the template's current
#'   arguments, or whose template no longer exists. For example, records of `b3-reference-rates`
#'   created before rb3 0.1.1 still have a `curve_name` argument. They are never used again.
#' - `missing_raw`: records marked as downloaded whose raw file does not exist.
#' - `orphan_raw`: files in the `raw/` folder that no record uses (only when `template = NULL`).
#'
#' **Gap check** (only with `template`): the business days of the period with no rows in the
#' layer. Each missing date gets a `reason`, taken from the download records:
#' - `never_fetched`: no record for this date (or year). Fetch it with `fetch_marketdata()`.
#' - `download_failed`: the download failed, or B3 sent an empty file. Fetch it again; B3 may
#'   not have the file.
#' - `not_read`: the file was downloaded but not read. Use `fetch_marketdata(..., reprocess = TRUE)`.
#' - `no_data`: the file was read but had no usable data.
#'
#' A day the exchange was closed, although the calendar says it was open, shows as `no_data` or
#' as `download_failed`, depending on what B3 sends for that template on a closed day.
#' - `not_in_layer`: the record says the file was read, but the layer has no rows for that date.
#'   Either the layer and the records disagree (a deleted dataset folder, a staging layer not
#'   rebuilt: use `reprocess = TRUE`), or the file held another date than the one requested.
#'   For yearly templates it means that the year's file has no data for that day.
#'
#' When several records cover one date (yearly templates, or templates with an extra argument
#' such as `index`), the best status wins: ok, then no data, then not read, then download failed.
#' Templates without a `refdate` or `year` argument (snapshots such as `b3-indexes-composition`)
#' have no time series, and the gap check is skipped. A date counts as present if it has any row,
#' even if only one index or one curve has it.
#'
#' @section Calendar:
#' The expected dates are `bizdays::bizseq(from, to, calendar)`. A period outside the calendar's
#' range is an error that shows the calendar's last date: update `bizdays` or pass a shorter `to`.
#'
#' @return Invisibly, a tibble with one row per finding and the columns `template`, `layer`,
#'   `check` (`"gap"`, `"stale_meta"`, `"missing_raw"` or `"orphan_raw"`), `refdate` (the
#'   missing date of a gap), `reason` (for gaps, see Details) and `detail` (the record's download
#'   arguments, or the raw file name). A healthy cache gives 0 rows.
#'
#' @examples
#' \dontrun{
#' # health of the whole cache
#' rb3_doctor()
#' # gaps in the input layer of the yield curves
#' res <- rb3_doctor("b3-reference-rates")
#' # templates without a calendar need one; check up to today
#' rb3_doctor("b3-futures-settlement-prices", calendar = "Brazil/B3", to = Sys.Date())
#' # fetch the dates that were never fetched
#' dates <- res |> dplyr::filter(reason == "never_fetched") |> dplyr::pull(refdate)
#' fetch_marketdata("b3-reference-rates", refdate = dates)
#' }
#' @export
rb3_doctor <- function(template = NULL, layer = "input", from = NULL, to = NULL, calendar = NULL) {
  title <- if (is.null(template)) "Cache doctor" else paste0("Cache doctor: ", template, " (", layer, ")")
  cli::cli_inform("\u2501\u2501 {.strong {title}}")
  gaps <- doctor_findings()
  if (!is.null(template)) {
    gaps <- doctor_gaps(template, layer, from, to, calendar)
    doctor_print_gaps(gaps)
  }
  health <- doctor_health(template)
  checks <- list(
    stale_meta = c("No stale records", "{n} stale record{?s}"),
    missing_raw = c("No records without raw files", "{n} record{?s} without raw file"),
    orphan_raw = c("No raw files without records", "{n} raw file{?s} without record")
  )
  if (!is.null(template)) checks$orphan_raw <- NULL
  for (ck in names(checks)) {
    n <- sum(health$check == ck)
    if (n == 0) cli::cli_inform(c(v = checks[[ck]][1])) else cli::cli_inform(c(x = checks[[ck]][2]))
  }
  invisible(dplyr::bind_rows(gaps, health))
}

#' Print gaps as runs of consecutive business days with the same reason
#' @noRd
doctor_print_gaps <- function(gaps) {
  p <- attr(gaps, "period")
  if (is.null(p)) {
    return(invisible())
  }
  cli::cli_inform(c(i = "Period {p$from} to {p$to}, {p$n_days} business days, {p$n_with_data} with data"))
  if (nrow(gaps) == 0) {
    cli::cli_inform(c(v = "No gaps"))
    return(invisible())
  }
  labels <- c(
    never_fetched = "never fetched", download_failed = "download failed", not_read = "not read",
    no_data = "no data", not_in_layer = "read, but not in the layer"
  )
  d <- gaps$refdate
  new_run <- c(TRUE, gaps$reason[-1] != gaps$reason[-nrow(gaps)] |
    bizdays::bizdays(d[-length(d)], d[-1], p$calendar) != 1)
  run <- cumsum(new_run)
  max_runs <- 20
  if (max(run) > max_runs) {
    on.exit(cli::cli_inform(c(i = "... and {max(run) - max_runs} more run{?s} of missing days, see the returned tibble")))
  }
  for (r in utils::head(unique(run), max_runs)) {
    i <- which(run == r)
    n <- length(i)
    span <- if (n == 1) format(d[i]) else paste(format(d[i[1]]), "to", format(d[i[n]]))
    msg <- paste0(span, " (", n, if (n == 1) " day" else " days", "): ", labels[[gaps$reason[i[1]]]])
    cli::cli_inform(stats::setNames(msg, if (gaps$reason[i[1]] == "no_data") "!" else "x"))
  }
}
