# Filtering data from COTAHIST datasets

A set of functions that implement filters to obtain organized and useful
data from the COTAHIST datasets.

## Usage

``` r
cotahist_filter_equity(x)

cotahist_filter_etf(x)

cotahist_filter_bdr(x)

cotahist_filter_unit(x)

cotahist_filter_fii(x)

cotahist_filter_fidc(x)

cotahist_filter_fiagro(x)

cotahist_filter_index(x)

cotahist_filter_equity_options(x)

cotahist_filter_index_options(x)

cotahist_filter_etf_options(x)

cotahist_filter_fund_options(x)
```

## Arguments

- x:

  A cotahist dataset

## Value

A dataframe containing the requested market data.

## Details

The functions bellow return data from plain instruments, stocks, funds
and indexes.

- `cotahist_filter_equity()` returns data for stocks and UNITs.

- `cotahist_filter_etf()` returns data for ETFs.

- `cotahist_filter_bdr()` returns data for BDRs.

- `cotahist_filter_unit()` returns data exclusively for UNITs.

- `cotahist_filter_index()` returns data for indices. The index data
  returned by `cotahist_filter_index()` corresponds to option expiration
  days, meaning there is only one index quote per month.

- `cotahist_filter_fii()`, `cotahist_filter_fidc()`, and
  `cotahist_filter_fiagro()` return data for funds.

The functions bellow return data related to options, from equities,
indexes and funds (ETFs).

- `cotahist_filter_equity_options()` returns data for stock options.

- `cotahist_filter_index_options()` returns data for index options,
  currently only for IBOVESPA.

- `cotahist_filter_funds_options()` returns data for fund options,
  currently only for ETFs.

The dataset provided must have at least the columns `isin`,
`instrument_market`, `bdi_code` and `specification_code`. A combination
of these columns is used to filter the desired data.

## Examples

``` r
if (FALSE) { # \dontrun{
df <- cotahist_get() |> cotahist_filter_equity()
} # }
if (FALSE) { # \dontrun{
df <- cotahist_get() |> cotahist_filter_etf()
} # }
if (FALSE) { # \dontrun{
df <- cotahist_get() |> cotahist_filter_bdr()
} # }
if (FALSE) { # \dontrun{
df <- cotahist_get() |> cotahist_filter_unit()
} # }
if (FALSE) { # \dontrun{
df <- cotahist_get() |> cotahist_filter_fii()
} # }
if (FALSE) { # \dontrun{
df <- cotahist_get() |> cotahist_filter_fidc()
} # }
if (FALSE) { # \dontrun{
df <- cotahist_get() |> cotahist_filter_fiagro()
} # }
if (FALSE) { # \dontrun{
df <- cotahist_get() |> cotahist_filter_index()
} # }
if (FALSE) { # \dontrun{
df <- cotahist_get() |> cotahist_filter_equity_options()
} # }
if (FALSE) { # \dontrun{
df <- cotahist_get() |> cotahist_filter_index_options()
} # }
if (FALSE) { # \dontrun{
df <- cotahist_get() |> cotahist_filter_etf_options()
} # }
if (FALSE) { # \dontrun{
df <- cotahist_get() |> cotahist_filter_fund_options()
} # }
```
