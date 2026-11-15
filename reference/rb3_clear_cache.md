# Clear the rb3 Cache

Deletes every downloaded file (`raw` folder), every dataset (`db`
folder) and every row of the metadata table in the cache folder set by
[rb3.cachedir](https://ropensci.github.io/rb3/reference/rb3.cachedir.md).
The folders and the empty metadata table are kept, so the package can be
used right away without calling
[`rb3_bootstrap()`](https://ropensci.github.io/rb3/reference/rb3_bootstrap.md).

## Usage

``` r
rb3_clear_cache(ask = interactive())
```

## Arguments

- ask:

  If `TRUE` (the default in interactive sessions), asks for confirmation
  before deleting anything.

## Value

Invisibly, `TRUE` if the cache was cleared, `FALSE` if the user
cancelled.

## Details

This cannot be undone.

## Examples

``` r
if (FALSE) { # \dontrun{
rb3_clear_cache()
} # }
```
