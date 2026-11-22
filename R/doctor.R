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
