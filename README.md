
<!-- README.md is generated from README.Rmd. Please edit that file -->

# rb3

<!-- badges: start -->

[![Project Status: Active – The project has reached a stable, usable
state and is being actively
developed.](https://www.repostatus.org/badges/latest/active.svg)](https://www.repostatus.org/#active)
[![Codecov test
coverage](https://codecov.io/gh/wilsonfreitas/rb3/branch/main/graph/badge.svg)](https://app.codecov.io/gh/wilsonfreitas/rb3?branch=main)
[![R build
(rcmdcheck)](https://github.com/wilsonfreitas/rb3/workflows/R-CMD-check/badge.svg)](https://github.com/wilsonfreitas/rb3/actions)
[![CRAN
status](https://www.r-pkg.org/badges/version/rb3)](https://CRAN.R-project.org/package=rb3)
[![](https://cranlogs.r-pkg.org/badges/rb3)](https://cran.r-project.org/package=rb3)
<!-- badges: end -->

[B3](https://www.b3.com.br) is the main financial exchange in Brazil,
offering support and access to trading systems for equity and fixed
income markets. In its website you can find a vast number of datasets
regarding prices and transactions for contracts available for trading at
these markets, including:

-   equities (unadjusted for corporate events)
-   futures
-   FII (Reits)
-   options
-   BDRs
-   historical yield curves (calculated from futures contracts)

Package **rb3** facilitates downloading and reading these datasets from
[B3](https://www.b3.com.br), making it easy to consume it in R in a
structured way.

# Documentation

The documentation is available in its [pkgdown
page](https://wilsonfreitas.github.io/rb3/), where articles (vignettes)
with real applications can be found.

## Installation

``` r
install.packages("rb3")
```

``` r
# github (Development branch)
if (!require(devtools)) install.packages("devtools")
devtools::install_github("wilsonfreitas/rb3")
```

## Examples

### Yield curve

Download and use historical yield curve data with `yc_get`.

``` r
library(rb3)
library(ggplot2)
library(stringr)

df_yc <- yc_mget(
  first_date = Sys.Date() - 255 * 5,
  last_date = Sys.Date(),
  by = 255
)

p <- ggplot(
  df_yc,
  aes(
    x = forward_date,
    y = r_252,
    group = refdate,
    color = factor(refdate)
  )
) +
  geom_line() +
  labs(
    title = "Yield Curves for Brazil",
    subtitle = "Built using interest rates future contracts",
    caption = str_glue("Data imported using rb3 at {Sys.Date()}"),
    x = "Forward Date",
    y = "Annual Interest Rate",
    color = "Reference Date"
  ) +
  theme_light() +
  scale_y_continuous(labels = scales::percent)

print(p)
```

<img src="man/figures/README-setup-1.png" width="100%" />

### Futures prices

Get settlement future prices with `futures_get`.

``` r
library(rb3)
library(dplyr)

df <- futures_mget(
  first_date = "2022-04-01",
  last_date = "2022-04-29",
  by = 5
)

glimpse(
  df |>
    filter(commodity == "DI1")
)
#> Rows: 153
#> Columns: 8
#> $ refdate          <date> 2022-04-01, 2022-04-01, 2022-04-01, 2022-04-01, 2022…
#> $ commodity        <chr> "DI1", "DI1", "DI1", "DI1", "DI1", "DI1", "DI1", "DI1…
#> $ maturity_code    <chr> "J22", "K22", "M22", "N22", "Q22", "U22", "V22", "X22…
#> $ symbol           <chr> "DI1J22", "DI1K22", "DI1M22", "DI1N22", "DI1Q22", "DI…
#> $ price_previous   <dbl> 99999.99, 99172.50, 98159.27, 97181.87, 96199.14, 951…
#> $ price            <dbl> 100000.00, 99172.31, 98160.23, 97185.43, 96210.42, 95…
#> $ change           <dbl> 0.01, -0.19, 0.96, 3.56, 11.28, 21.61, 34.93, 48.85, …
#> $ settlement_value <dbl> 0.01, 0.19, 0.96, 3.56, 11.28, 21.61, 34.93, 48.85, 5…
```

### Equity data

Equity closing data (without **ANY** price adjustments) is available
thru `cotahist_get`.

``` r
library(rb3)
library(bizdays)
#> 
#> Attaching package: 'bizdays'
#> The following object is masked from 'package:stats':
#> 
#>     offset

# fix for ssl error (only in linux)
if (Sys.info()["sysname"] == "Linux") {
  httr::set_config(
    httr::config(ssl_verifypeer = FALSE)
  )
}

date <- preceding(Sys.Date() - 1, "Brazil/ANBIMA") # last business day
ch <- cotahist_get(date, "daily")

glimpse(
  cotahist_equity_get(ch)
)
#> Rows: 382
#> Columns: 13
#> $ refdate               <date> 2022-05-13, 2022-05-13, 2022-05-13, 2022-05-13,…
#> $ symbol                <chr> "AALR3", "ABCB4", "ABEV3", "AERI3", "AESB3", "AF…
#> $ open                  <dbl> 19.81, 16.16, 14.55, 3.83, 10.79, 9.06, 31.60, 9…
#> $ high                  <dbl> 19.89, 16.55, 14.67, 3.93, 10.81, 9.50, 32.40, 9…
#> $ low                   <dbl> 19.43, 16.06, 14.45, 3.72, 10.64, 9.06, 31.54, 9…
#> $ close                 <dbl> 19.75, 16.54, 14.54, 3.75, 10.64, 9.35, 32.06, 9…
#> $ average               <dbl> 19.66, 16.38, 14.55, 3.80, 10.69, 9.38, 31.99, 9…
#> $ best_bid              <dbl> 19.75, 16.45, 14.54, 3.74, 10.64, 9.35, 32.06, 9…
#> $ best_ask              <dbl> 19.80, 16.54, 14.58, 3.75, 10.65, 9.47, 32.08, 9…
#> $ volume                <dbl> 13692159, 10155477, 194865062, 13607948, 1187700…
#> $ traded_contracts      <int> 696300, 619700, 13385100, 3571700, 1110400, 1800…
#> $ transactions_quantity <int> 2873, 4115, 29016, 7499, 4533, 16, 3363, 492, 63…
#> $ distribution_id       <int> 102, 140, 125, 101, 102, 119, 112, 101, 103, 231…
```

Funds data

``` r
glimpse(
  cotahist_funds_get(ch)
)
#> Rows: 359
#> Columns: 13
#> $ refdate               <date> 2022-05-13, 2022-05-13, 2022-05-13, 2022-05-13,…
#> $ symbol                <chr> "ABCP11", "AFHI11", "AFOF11", "AIEC11", "ALMI11"…
#> $ open                  <dbl> 72.48, 99.52, 89.00, 78.55, 950.00, 115.19, 10.2…
#> $ high                  <dbl> 72.78, 100.80, 89.49, 78.99, 951.00, 115.98, 10.…
#> $ low                   <dbl> 72.16, 99.50, 88.52, 78.55, 930.00, 115.19, 10.2…
#> $ close                 <dbl> 72.24, 100.65, 89.00, 78.93, 950.00, 115.70, 10.…
#> $ average               <dbl> 72.38, 100.13, 89.02, 78.90, 947.15, 115.63, 10.…
#> $ best_bid              <dbl> 72.24, 100.60, 88.99, 78.91, 930.50, 115.69, 10.…
#> $ best_ask              <dbl> 72.53, 100.65, 89.00, 78.99, 951.00, 115.70, 10.…
#> $ volume                <dbl> 67023.89, 1305373.39, 130064.77, 57283.07, 79561…
#> $ traded_contracts      <int> 926, 13036, 1461, 726, 84, 8613, 3181, 30794, 24…
#> $ transactions_quantity <int> 231, 542, 79, 129, 77, 1039, 99, 3989, 221, 3, 7…
#> $ distribution_id       <int> 314, 113, 113, 120, 250, 154, 105, 126, 131, 136…
```

BDRs data

``` r
glimpse(
  cotahist_bdrs_get(ch)
)
#> Rows: 509
#> Columns: 13
#> $ refdate               <date> 2022-05-13, 2022-05-13, 2022-05-13, 2022-05-13,…
#> $ symbol                <chr> "A1AP34", "A1BB34", "A1CR34", "A1DM34", "A1EE34"…
#> $ open                  <dbl> 67.80, 36.71, 65.10, 443.76, 234.24, 26.28, 294.…
#> $ high                  <dbl> 67.80, 36.71, 65.10, 443.76, 235.20, 26.28, 295.…
#> $ low                   <dbl> 66.79, 36.23, 64.56, 430.00, 233.77, 26.10, 293.…
#> $ close                 <dbl> 66.79, 36.25, 64.62, 430.00, 235.00, 26.10, 295.…
#> $ average               <dbl> 67.43, 36.31, 64.68, 434.09, 234.62, 26.22, 294.…
#> $ best_bid              <dbl> 0.00, 0.00, 54.00, 0.00, 0.00, 0.00, 0.00, 0.00,…
#> $ best_ask              <dbl> 0.00, 38.00, 0.00, 0.00, 0.00, 27.43, 0.00, 0.00…
#> $ volume                <dbl> 3709.04, 435.83, 14619.84, 8247.78, 14781.36, 18…
#> $ traded_contracts      <int> 55, 12, 226, 19, 63, 7, 49, 64, 2, 3, 1, 6, 7, 1…
#> $ transactions_quantity <int> 6, 12, 38, 5, 36, 5, 46, 45, 1, 3, 1, 3, 1, 15, …
#> $ distribution_id       <int> 110, 102, 106, 109, 109, 102, 110, 110, 106, 101…
```

Equity options

``` r
glimpse(
  cotahist_equity_options_get(ch)
)
#> Rows: 6,059
#> Columns: 14
#> $ refdate               <date> 2022-05-13, 2022-05-13, 2022-05-13, 2022-05-13,…
#> $ symbol                <chr> "ABEVR155", "ABEVR180", "ABEVX20", "ABEVR154", "…
#> $ type                  <fct> Put, Put, Put, Put, Put, Put, Put, Put, Call, Ca…
#> $ strike                <dbl> 14.97, 17.47, 19.47, 15.47, 12.79, 16.29, 23.00,…
#> $ maturity_date         <date> 2022-06-17, 2022-06-17, 2023-12-15, 2022-06-17,…
#> $ open                  <dbl> 0.69, 2.72, 3.30, 0.97, 0.01, 1.62, 1.80, 1.53, …
#> $ high                  <dbl> 0.71, 2.81, 3.30, 1.03, 0.02, 1.62, 2.20, 1.53, …
#> $ low                   <dbl> 0.59, 2.72, 3.30, 0.91, 0.01, 1.62, 1.80, 1.53, …
#> $ close                 <dbl> 0.60, 2.81, 3.30, 0.92, 0.01, 1.62, 2.10, 1.53, …
#> $ average               <dbl> 0.65, 2.74, 3.30, 0.96, 0.01, 1.62, 2.06, 1.53, …
#> $ volume                <dbl> 414290, 541506, 66000, 201996, 1057, 81000, 825,…
#> $ traded_contracts      <int> 637000, 197000, 20000, 209700, 105400, 50000, 40…
#> $ transactions_quantity <int> 99, 6, 1, 172, 13, 1, 4, 1, 1, 1, 2, 8, 1, 1, 7,…
#> $ distribution_id       <int> 124, 124, 124, 125, 125, 125, 231, 101, 113, 113…
```
