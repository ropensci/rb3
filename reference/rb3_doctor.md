# Check the health of the rb3 cache

`rb3_doctor()` checks the download records (`meta.sqlite`) and the raw
files of the cache, and finds the gaps in the time series of a
template's dataset layer: business days in a period that have no rows.
It only reports; it never changes the cache.

## Usage

``` r
rb3_doctor(
  template = NULL,
  layer = "input",
  from = NULL,
  to = NULL,
  calendar = NULL
)
```

## Arguments

- template:

  A template id (see
  [`list_templates()`](https://ropensci.github.io/rb3/reference/list_templates.md)).
  `NULL` (default) runs only the health checks, for the whole cache.

- layer:

  The dataset layer to check for gaps: `"input"` (default) or
  `"staging"`.

- from, to:

  The period to check (Date or `"YYYY-MM-DD"`). Defaults: the first and
  the last `refdate` in the layer. Use `to = Sys.Date()` to also find
  recent dates not fetched yet.

- calendar:

  A `bizdays` calendar name. `NULL` (default) uses the template's
  calendar (the `calendar` field of its YAML file). Templates without a
  calendar need this argument. A value passed here overrides the
  template's calendar.

## Value

Invisibly, a tibble with one row per finding and the columns `template`,
`layer`, `check` (`"gap"`, `"stale_meta"`, `"missing_raw"` or
`"orphan_raw"`), `refdate` (the missing date of a gap), `reason` (for
gaps, see Details) and `detail` (the record's download arguments, or the
raw file name). A healthy cache gives 0 rows.

## Details

**Health checks** (always; for one template when `template` is given):

- `stale_meta`: records whose download arguments differ from the
  template's current arguments, or whose template no longer exists. For
  example, records of `b3-reference-rates` created before rb3 0.1.1
  still have a `curve_name` argument. They are never used again.

- `missing_raw`: records marked as downloaded whose raw file does not
  exist.

- `orphan_raw`: files in the `raw/` folder that no record uses (only
  when `template = NULL`).

**Gap check** (only with `template`): the business days of the period
with no rows in the layer. Each missing date gets a `reason`, taken from
the download records:

- `never_fetched`: no record for this date (or year). Fetch it with
  [`fetch_marketdata()`](https://ropensci.github.io/rb3/reference/fetch_marketdata.md).

- `download_failed`: the download failed, or B3 sent an empty file.
  Fetch it again; B3 may not have the file.

- `not_read`: the file was downloaded but not read. Use
  `fetch_marketdata(..., reprocess = TRUE)`.

- `no_data`: the file was read but had no usable data.

A day the exchange was closed, although the calendar says it was open,
shows as `no_data` or as `download_failed`, depending on what B3 sends
for that template on a closed day.

- `not_in_layer`: the record says the file was read, but the layer has
  no rows for that date. Either the layer and the records disagree (a
  deleted dataset folder, a staging layer not rebuilt: use
  `reprocess = TRUE`), or the file held another date than the one
  requested. For yearly templates it means that the year's file has no
  data for that day.

When several records cover one date (yearly templates, or templates with
an extra argument such as `index`), the best status wins: ok, then no
data, then not read, then download failed. Templates without a `refdate`
or `year` argument (snapshots such as `b3-indexes-composition`) have no
time series, and the gap check is skipped. A date counts as present if
it has any row, even if only one index or one curve has it.

## Calendar

The expected dates are `bizdays::bizseq(from, to, calendar)`. A period
outside the calendar's range is an error that shows the calendar's last
date: update `bizdays` or pass a shorter `to`.

## Examples

``` r
if (FALSE) { # \dontrun{
# health of the whole cache
rb3_doctor()
# gaps in the input layer of the yield curves
res <- rb3_doctor("b3-reference-rates")
# templates without a calendar need one; check up to today
rb3_doctor("b3-futures-settlement-prices", calendar = "Brazil/B3", to = Sys.Date())
# fetch the dates that were never fetched
dates <- res |> dplyr::filter(reason == "never_fetched") |> dplyr::pull(refdate)
fetch_marketdata("b3-reference-rates", refdate = dates)
} # }
```
