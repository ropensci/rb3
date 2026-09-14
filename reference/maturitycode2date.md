# Convert Maturity Code to Date

This function converts a vector of maturity codes into actual dates.

## Usage

``` r
maturitycode2date(x, expr = "first day", refdate = NULL)
```

## Arguments

- x:

  a character vector with three letters string that represent maturity
  of futures contracts.

- expr:

  a string which indicates the day to use in maturity date, default is
  "first day". See
  [`bizdays::getdate`](https://rdrr.io/pkg/bizdays/man/getdate.html) for
  more details on this argument

- refdate:

  reference date to be passed. It is necessary to convert old maturities
  like JAN0, that can be Jan/2000 or Jan/2010. If `refdate` is greater
  that 2001-01-01 JAN0 is converted to Jan/2010, otherwise, Jan/2000.

## Value

A vector of dates corresponding to the input maturity codes. Convert
Maturity Code to Date

This function converts a vector of maturity codes into actual dates. Get
the corresponding maturity date for the three characters string that
represent maturity of futures contracts.

a Date vector with maturity dates

## Examples

``` r
maturitycode2date(c("F22", "F23", "G23", "H23", "F45"), "first day")
#> [1] "2022-01-01" "2023-01-01" "2023-02-01" "2023-03-01" "2045-01-01"
maturitycode2date(c("F23", "K35"), "15th day")
#> [1] "2023-01-15" "2035-05-15"
maturitycode2date(c("AGO2", "SET2"), "first day")
#> [1] "2002-08-01" "2002-09-01"
```
