# Retrieve Portfolio of B3 Indexes

These functions fetch the current and theoretical portfolio of B3
indexes using predefined dataset templates. The data is retrieved from
the datasets "b3-indexes-current-portfolio" and
"b3-indexes-theoretical-portfolio".

## Usage

``` r
indexes_current_portfolio_get()

indexes_theoretical_portfolio_get()
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
template_dataset("b3-indexes-current-portfolio", layer = 2) |>
  filter(index %in% c("SMLL", "IBOV", "IBRA")) |>
  collect()
} # }

if (FALSE) { # \dontrun{
template_dataset("b3-indexes-theoretical-portfolio", layer = 2) |>
  filter(index == "IBOV") |>
  collect()
} # }
```
