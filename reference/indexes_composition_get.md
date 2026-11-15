# Retrieve Composition of B3 Indexes

This function fetches the composition of B3 indexes. It uses the
template dataset "b3-indexes-composition" to retrieve the data.

## Usage

``` r
indexes_composition_get()
```

## Value

A data frame containing the columns:

- update_date:

  The date when the data was last updated.

- symbol:

  The symbol of the asset.

- indexes:

  The indexes associated with the asset.

An `arrow_dplyr_query` or `ArrowObject`, representing a lazily evaluated
query. The underlying data is not collected until explicitly requested,
allowing efficient manipulation of large datasets without immediate
memory usage. To trigger evaluation and return the results as an R
`tibble`, use `collect()`.

## Data availability

B3 publishes only the current composition. Each
[`fetch_marketdata()`](https://ropensci.github.io/rb3/reference/fetch_marketdata.md)
call stores a snapshot with `refdate` equal to the day it was fetched,
so history only builds up if you fetch it regularly.

## Examples

``` r
if (FALSE) { # \dontrun{
  indexes_composition <- indexes_composition_get()
  head(indexes_composition)
} # }
```
