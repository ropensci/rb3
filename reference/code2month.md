# Convert Maturity Code to Corresponding Month

This function takes a character string representing the maturity code of
a futures contract and returns the corresponding month as an integer. It
supports both the new and old maturity code formats used in futures
contracts.

## Usage

``` r
code2month(x)
```

## Arguments

- x:

  A character vector with the maturity code(s) of futures contracts. The
  codes can be either a single letter (e.g., "F", "G", "H", ...)
  representing the new code format or a three-letter abbreviation (e.g.,
  "JAN", "FEV", "MAR", ...) representing the old code format.

## Value

A vector of integers corresponding to the months of the year, where 1 =
January, 2 = February, ..., 12 = December.

## Details

The function distinguishes between two maturity code formats:

- The **new code format** uses a single letter (e.g., "F" = January, "G"
  = February, etc.).

- The **old code format** uses a three-letter abbreviation (e.g., "JAN"
  = January, "FEV" = February, etc.).

## Examples

``` r
code2month(c("F", "G", "H", "J", "K", "M", "N", "Q", "U", "V", "X", "Z"))
#>  [1]  1  2  3  4  5  6  7  8  9 10 11 12
code2month(c("JAN", "FEV", "MAR", "NOV", "DEZ"))
#> [1]  1  2  3 11 12
```
