# Access COTAHIST datasets

The COTAHIST files are available with daily, monthly, and yearly data.
Therefore, the datasets correspond to these periods (`daily`, `monthly`,
`yearly`). See
[`download_marketdata`](https://ropensci.github.io/rb3/reference/download_marketdata.md)
and
[`read_marketdata`](https://ropensci.github.io/rb3/reference/read_marketdata.md)
for instructions on how to download the files and create the datasets.

## Usage

``` r
cotahist_get(type = c("yearly", "monthly", "daily"))
```

## Arguments

- type:

  A string specifying the dataset to be used: `"daily"`, `"monthly"`, or
  `"yearly"`.

## Value

An `arrow_dplyr_query` or `ArrowObject`, representing a lazily evaluated
query. The underlying data is not collected until explicitly requested,
allowing efficient manipulation of large datasets without immediate
memory usage. To trigger evaluation and return the results as an R
`tibble`, use `collect()`.

## Details

The COTAHIST files contain historical quotation data (*Cotações
Históricas*) for stocks, stock options, stock forward contracts, ETFs,
ETF options, BDRs, UNITs, REITs (FIIs - *Fundos Imobiliários*), FIAGROs
(*Fundos da Agroindústria*), and FIDCs (*Fundos de Direitos
Creditórios*). These files from B3 hold the oldest available
information. The earliest annual file available dates back to 1986.
However, it is not recommended to use data prior to 1995 due to the
monetary stabilization process in 1994 (Plano Real).

Note that the prices in the files are not adjusted for corporate
actions. As a result, only ETF series can be used without issues.

Before using the dataset, it is necessary to download the files using
the
[`download_marketdata`](https://ropensci.github.io/rb3/reference/download_marketdata.md)
function and create the datasets with the
[`read_marketdata`](https://ropensci.github.io/rb3/reference/read_marketdata.md)
function.

## Examples

``` r
if (FALSE) { # \dontrun{
# get all data to the year of 2001
meta <- download_marketdata("b3-cotahist-yearly", year = 2001)
read_marketdata(meta)
ds_yearly <- cotahist_get()

# Earliest available annual file: 1986
# Recommended starting point: 1995 (after Plano Real)
} # }
if (FALSE) { # \dontrun{
# To obtain data from January 2, 2014, the earliest available date:
meta <- download_marketdata("b3-cotahist-daily", refdate = as.Date("2014-01-02"))
read_marketdata(meta)
ds_daily <- cotahist_get("daily")
} # }
if (FALSE) { # \dontrun{
# Once you download more dates, the data downloaded before remains stored and you can filter
# any date you want.
meta <- download_marketdata("b3-cotahist-daily", refdate = as.Date("2014-01-03"))
read_marketdata(meta)
df_daily <- cotahist_get("daily") |>
  filter(refdate == "2014-01-03") |>
  collect()
} # }
```
