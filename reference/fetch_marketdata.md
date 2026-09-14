# Fetch and process market data

Downloads market data based on a template and parameter combinations,
then reads the data into a database.

## Usage

``` r
fetch_marketdata(
  template,
  force_download = FALSE,
  reprocess = FALSE,
  throttle = FALSE,
  ...
)
```

## Arguments

- template:

  A character string specifying the market data template to use

- force_download:

  A logical value indicating whether to force downloading files even if
  they already exist in the cache (default is `FALSE`). If `TRUE`, the
  function will download files again even if they were previously
  downloaded.

- reprocess:

  A logical value indicating whether to reprocess files even if they are
  already processed (default is `FALSE`). If `TRUE`, the function will
  reprocess the files in the input layer, even if they were previously
  processed.

- throttle:

  A logical value indicating whether to throttle the download requests
  (default is `FALSE`). If `TRUE`, a 1-second delay is introduced
  between requests to avoid overwhelming the server.

- ...:

  Named arguments that will be expanded into a grid of all combinations
  to fetch data for

## Details

This function performs three main steps:

1.  Downloads market data files by creating all combinations of the
    provided parameters.

2.  Processes the downloaded files by reading them into the input layer
    of the database.

3.  Creates the staging layer if configured in the template.

Progress indicators are displayed during both steps, and warnings are
shown for combinations that failed to download or produced invalid
files.

The `throttle` parameter is useful for avoiding server overload and
ensuring that the requests are sent at a reasonable rate. If set to
`TRUE`, a 1-second delay is introduced between each download request.

The `force_download` parameter allows you to re-download files even if
they already exist in the cache. This can be useful if you want to
ensure that you have the latest version of the data or if the files have
been modified on the server.

The `reprocess` parameter allows you to reprocess files even if they
have already been processed. This can be useful if you want to ensure
that the data is up-to-date.

## Examples

``` r
if (FALSE) { # \dontrun{
fetch_marketdata("b3-cotahist-yearly", year = 2020:2024)
fetch_marketdata("b3-cotahist-daily", refdate = bizseq("2025-01-01", "2025-03-10", "Brazil/B3"))
fetch_marketdata("b3-reference-rates", refdate = bizseq("2025-01-01", "2025-03-10", "Brazil/B3"))
fetch_marketdata("b3-indexes-historical-data",
  throttle = TRUE, index = c("IBOV", "IBXX", "IBXL"),
  year = 2000:2025
)
} # }
```
