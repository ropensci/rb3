# Checking the Cache

## Introduction

rb3 keeps everything it downloads in a local cache: the raw files, the
datasets built from them, and one download record (a *meta*) per file,
in `meta.sqlite`. Over time you fetch some dates, skip others, and some
downloads fail.
[`rb3_doctor()`](https://ropensci.github.io/rb3/reference/rb3_doctor.md)
tells you how healthy that cache is, and above all whether the time
series behind a dataset is complete:

- which business days have no data in a dataset layer, and **why** each
  one is missing;
- which download records are stale or broken.

[`rb3_doctor()`](https://ropensci.github.io/rb3/reference/rb3_doctor.md)
only reports. It never downloads, deletes or rewrites anything. You
decide what to do with what it finds, usually by calling
[`fetch_marketdata()`](https://ropensci.github.io/rb3/reference/fetch_marketdata.md)
again.

``` r

library(rb3)
library(dplyr)
library(bizdays)
```

## What the doctor checks

[`rb3_doctor()`](https://ropensci.github.io/rb3/reference/rb3_doctor.md)
has two kinds of checks.

The **gap check** runs when you pass a template. It looks at one dataset
layer of that template (`input` or `staging`), takes every `refdate` in
it, and compares them with the business days of a calendar. Each
business day without rows is a gap.

The **health checks** always run, on the whole cache
([`rb3_doctor()`](https://ropensci.github.io/rb3/reference/rb3_doctor.md))
or on the records of one template (`rb3_doctor("<template>")`):

| check | what it finds |
|----|----|
| `stale_meta` | records whose download arguments differ from the template’s current arguments, or whose template no longer exists |
| `missing_raw` | records marked as downloaded whose raw file is gone |
| `orphan_raw` | raw files that no record uses (only for the whole cache) |

What the doctor does **not** check:

- the `*_get()` helpers that combine several templates, such as
  [`yc_brl_with_futures_get()`](https://ropensci.github.io/rb3/reference/superdataset.md):
  check each template behind them instead;
- gaps per index, per curve or per symbol: a date counts as present if
  it has any row;
- dates that are only partly written (row counts are not checked).

## Gaps in a layer

As an example, we fetch the yield curves of January 2024, but skip the
15th to the 17th on purpose.

``` r

dates <- bizseq("2024-01-02", "2024-01-31", "Brazil/ANBIMA")
dates <- dates[!dates %in% as.Date(c("2024-01-15", "2024-01-16", "2024-01-17"))]
fetch_marketdata("b3-reference-rates", refdate = dates)
```

Then we ask the doctor about the `input` layer of `b3-reference-rates`:

``` r

res <- rb3_doctor("b3-reference-rates")
```

    ━━ Cache doctor: b3-reference-rates (input)
    ℹ Period 2024-01-02 to 2024-01-31, 22 business days, 19 with data
    ✖ 2024-01-15 to 2024-01-17 (3 days): never fetched
    ✔ No stale records
    ✔ No records without raw files

The first line gives the period, the number of business days in it and
how many have data. Then each run of consecutive missing days with the
same reason gets one line. The function also returns a tibble, with one
row per finding:

``` r

res
```

    #> # A tibble: 3 × 6
    #>   template           layer check refdate    reason        detail
    #>   <chr>              <chr> <chr> <date>     <chr>         <chr> 
    #> 1 b3-reference-rates input gap   2024-01-15 never_fetched NA    
    #> 2 b3-reference-rates input gap   2024-01-16 never_fetched NA    
    #> 3 b3-reference-rates input gap   2024-01-17 never_fetched NA

Its columns are `template`, `layer`, `check`, `refdate` (the missing
date), `reason` and `detail`. A healthy cache gives a tibble with 0
rows.

### The reasons

Each missing date gets one reason, taken from the download records:

| reason | meaning | what to do |
|----|----|----|
| `never_fetched` | no record for this date (or for its year) | [`fetch_marketdata()`](https://ropensci.github.io/rb3/reference/fetch_marketdata.md) for that date |
| `download_failed` | the download failed, or B3 sent an empty file | try again; B3 may not have the file (holiday, or too old) |
| `not_read` | the file was downloaded but never read | `fetch_marketdata(..., reprocess = TRUE)` |
| `no_data` | the file was read but had no usable data | often a day the exchange was closed; nothing to do |
| `not_in_layer` | the record says the file was read, but the layer has no rows for that date | see below |

A day the exchange was closed, although the calendar says it was open,
shows as `no_data` or as `download_failed`, depending on what B3 sends
for that template on a closed day (an empty file, or a file without
data). See the Christmas example in [Calendars](#calendars).

The `detail` column shows the download arguments of the record behind
each reason (empty for `never_fetched`), for example which `index` and
`year` a yearly record was for.

`not_in_layer` has two causes:

- the layer and the records disagree, for example a dataset folder was
  deleted or a staging layer was not rebuilt: fetch again with
  `reprocess = TRUE`;
- the file held another date than the one requested: some readers take
  the date from the file itself (for example
  `b3-futures-settlement-prices`), so a download for one day can store
  another day.

For yearly templates (`b3-cotahist-yearly`,
`b3-indexes-historical-data`) `not_in_layer` simply means that the
year’s file has no data for that day.

When several records cover the same date, the best one wins, in this
order: ok, no data, not read, download failed. This happens for yearly
templates (one record per year) and for templates with an extra
argument, such as `index` in `b3-indexes-historical-data`.

## Choosing the layer and the period

`layer = "input"` (the default) checks the data as it was read from the
files. `layer = "staging"` checks the processed data that most `*_get()`
functions return. The two can differ, for example when a staging layer
was not rebuilt after new downloads.

``` r

rb3_doctor("b3-reference-rates", layer = "staging", calendar = "Brazil/B3")
```

    ━━ Cache doctor: b3-reference-rates (staging)
    ℹ Period 2024-01-02 to 2024-01-31, 22 business days, 19 with data
    ✖ 2024-01-15 to 2024-01-17 (3 days): never fetched
    ✔ No stale records
    ✔ No records without raw files

By default the period goes from the first to the last `refdate` in the
layer, so dates after your last fetch are not reported. Use `from` and
`to` to choose the period, for example `to = Sys.Date()` to see the
recent dates you have not fetched yet:

``` r

rb3_doctor("b3-reference-rates", calendar = "Brazil/B3", to = "2024-02-09")
```

    ━━ Cache doctor: b3-reference-rates (input)
    ℹ Period 2024-01-02 to 2024-02-09, 29 business days, 19 with data
    ✖ 2024-01-15 to 2024-01-17 (3 days): never fetched
    ✖ 2024-02-01 to 2024-02-09 (7 days): never fetched
    ✔ No stale records
    ✔ No records without raw files

Templates with no data in the layer need both `from` and `to`.

## Filling the gaps

The returned tibble gives the dates to fetch:

``` r

res <- rb3_doctor("b3-reference-rates")
dates <- res |>
  filter(check == "gap", reason == "never_fetched") |>
  pull(refdate)
fetch_marketdata("b3-reference-rates", refdate = dates)
```

For yearly templates, fetch the years of the missing dates:

``` r

res <- rb3_doctor("b3-cotahist-yearly", calendar = "Brazil/B3")
years <- res |>
  filter(check == "gap", reason == "never_fetched") |>
  pull(refdate) |>
  format("%Y") |>
  unique() |>
  as.integer()
fetch_marketdata("b3-cotahist-yearly", year = years)
```

## Calendars

The expected dates come from a `bizdays` calendar. By default the doctor
uses the calendar of the template (the `calendar` field of its YAML
file). Templates without one need the `calendar` argument:

``` r

rb3_doctor("b3-futures-settlement-prices")
#> Error: Template b3-futures-settlement-prices defines no calendar: pass one in `calendar`,
#> e.g. `calendar = "Brazil/B3"`
rb3_doctor("b3-futures-settlement-prices", calendar = "Brazil/B3")
```

A value passed in `calendar` also overrides the template’s calendar.

The calendar matters: a day that the calendar says is open but the
exchange was closed shows up as a gap. `b3-reference-rates` uses
`Brazil/ANBIMA`, which is open on December 24, when B3 is closed. In the
Christmas week of 2024, the download for that day failed (B3 sent an
empty file):

``` r

fetch_marketdata("b3-reference-rates", refdate = bizseq("2024-12-23", "2024-12-27", "Brazil/ANBIMA"))
rb3_doctor("b3-reference-rates", from = "2024-12-23", to = "2024-12-27")
```

    ━━ Cache doctor: b3-reference-rates (input)
    ℹ Period 2024-12-23 to 2024-12-27, 4 business days, 3 with data
    ✖ 2024-12-24 (1 day): download failed
    ✔ No stale records
    ✔ No records without raw files

With the B3 calendar the gap goes away:

``` r

rb3_doctor("b3-reference-rates", from = "2024-12-23", to = "2024-12-27", calendar = "Brazil/B3")
```

    ━━ Cache doctor: b3-reference-rates (input)
    ℹ Period 2024-12-23 to 2024-12-27, 3 business days, 3 with data
    ✔ No gaps
    ✔ No stale records
    ✔ No records without raw files

A period outside the calendar’s range is an error that shows the
calendar’s last date. Update `bizdays` or choose a shorter period.

## Templates without time series, or with a short history

Some templates are snapshots with no `refdate` or `year` argument:
`b3-indexes-composition`, `b3-indexes-current-portfolio` and
`b3-indexes-theoretical-portfolio`. They have no time series, so the gap
check is skipped and only the health checks run.

Some sources keep only recent data, so old gaps can never be filled:

- `b3-futures-settlement-prices` and `b3-bdi-derivatives-trades`: about
  the last 21 sessions;
- `b3-trade-information-consolidated`: about the last 360 sessions.

For these templates, old dates come back as `download_failed` when you
fetch them again.

## Health checks and cleaning records

Without a template,
[`rb3_doctor()`](https://ropensci.github.io/rb3/reference/rb3_doctor.md)
checks the whole cache:

``` r

rb3_doctor()
```

    ━━ Cache doctor
    ✔ No stale records
    ✔ No records without raw files
    ✔ No raw files without records

A common finding in caches created before rb3 0.1.1 is a long list of
stale records for `b3-reference-rates`: they still have the old
`curve_name` argument and are never used again. Stale records and their
raw files only take disk space. To remove all of them at once, use
[`rb3_clear_cache()`](https://ropensci.github.io/rb3/reference/rb3_clear_cache.md),
which empties the whole cache (fetch the data you need again
afterwards).

The `detail` column of the result shows the download arguments of each
record, so you can see which dates or years a finding is about:

``` r

rb3_doctor() |>
  filter(check == "stale_meta") |>
  count(template)
```
