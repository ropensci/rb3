# Get historical data from B3 indexes

Fetches historical data from B3 indexes.

## Usage

``` r
indexes_historical_data_get()
```

## Value

An `arrow_dplyr_query` or `ArrowObject`, representing a lazily evaluated
query. The underlying data is not collected until explicitly requested,
allowing efficient manipulation of large datasets without immediate
memory usage. To trigger evaluation and return the results as an R
`tibble`, use `collect()`.

## Examples

``` r
if (FALSE) { # \dontrun{
fetch_marketdata("b3-indexes-historical-data", index = "IBOV", year = 2001:2010)
indexes_historical_data_get() |>
 filter(index == "IBOV", refdate >= as.Date("2001-01-01"), refdate <= as.Date("2010-12-31"))
} # }
```
