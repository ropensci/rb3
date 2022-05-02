
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

<!-- badges: end -->

[B3](https://www.b3.com.br) is the main financial exchange in Brazil,
offering support and access to trading systems for equity and fixed
income markets. In its website you can find a vast number of datasets
regarding prices and transactions for contracts available for trading at
these markets.

Package **rb3** facilitates downloading and reading these datasets from
[B3](https://www.b3.com.br), making it easy to consume it in R in a
structured way.

# Documentation

The documentation is available in its [pkgdown
page](https://wilsonfreitas.github.io/rb3/), where articles (vignettes)
with real applications can be found.

## Installation

``` r
# in CRAN (Official) -- NOT YET AVAILABLE
# install.packages("rb3")

# github (Development branch)
if (!require(devtools)) install.packages("devtools")
devtools::install_github("wilsonfreitas/rb3")
```

## Examples

### Yield curve

Download and use historical yield curve data with `yc_get`.

``` r
library(rb3)
#> Loading required package: bizdays
#> 
#> Attaching package: 'bizdays'
#> The following object is masked from 'package:stats':
#> 
#>     offset
library(ggplot2)
library(stringr)

df_yc <- yc_get(
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

df <- futures_get(
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
#> Rows: 378
#> Columns: 13
#> $ refdate               <date> 2022-04-29, 2022-04-29, 2022-04-29, 2022-04-29,…
#> $ symbol                <chr> "AALR3", "ABCB4", "ABEV3", "AERI3", "AESB3", "AG…
#> $ open                  <dbl> 19.69, 16.81, 14.85, 5.12, 11.25, 34.34, 9.20, 1…
#> $ high                  <dbl> 19.77, 16.81, 15.00, 5.18, 11.28, 34.70, 9.80, 1…
#> $ low                   <dbl> 19.32, 15.80, 14.52, 4.88, 11.01, 33.80, 9.11, 1…
#> $ close                 <dbl> 19.41, 15.80, 14.52, 4.88, 11.05, 33.99, 9.80, 1…
#> $ average               <dbl> 19.48, 16.09, 14.72, 5.00, 11.09, 34.22, 9.59, 1…
#> $ best_bid              <dbl> 19.41, 15.80, 14.52, 4.88, 11.03, 33.99, 9.13, 1…
#> $ best_ask              <dbl> 19.44, 16.00, 14.60, 4.89, 11.05, 34.00, 9.80, 1…
#> $ volume                <dbl> 14055007, 28379427, 384931858, 11565634, 3820062…
#> $ traded_contracts      <int> 721500, 1763100, 26145100, 2309900, 3443700, 110…
#> $ transactions_quantity <int> 2050, 6273, 23420, 6249, 8291, 4766, 349, 303, 2…
#> $ distribution_id       <int> 102, 140, 125, 101, 102, 112, 100, 102, 231, 231…
```

Funds data

``` r
glimpse(
  cotahist_funds_get(ch)
)
#> Rows: 366
#> Columns: 13
#> $ refdate               <date> 2022-04-29, 2022-04-29, 2022-04-29, 2022-04-29,…
#> $ symbol                <chr> "BZLI11", "ABCP11", "AFHI11", "AFOF11", "AIEC11"…
#> $ open                  <dbl> 16.90, 74.40, 99.22, 93.88, 80.45, 930.00, 115.4…
#> $ high                  <dbl> 16.90, 74.90, 99.22, 94.35, 80.95, 930.00, 116.0…
#> $ low                   <dbl> 16.90, 73.23, 98.56, 92.50, 79.54, 930.00, 115.4…
#> $ close                 <dbl> 16.90, 73.57, 98.98, 93.40, 80.20, 930.00, 116.0…
#> $ average               <dbl> 16.90, 73.61, 98.86, 93.24, 79.99, 928.42, 115.8…
#> $ best_bid              <dbl> 16.90, 73.29, 98.95, 92.78, 80.19, 930.00, 116.0…
#> $ best_ask              <dbl> 17.70, 73.57, 98.98, 93.40, 80.20, 985.98, 116.0…
#> $ volume                <dbl> 135.20, 151215.31, 1000055.72, 205332.83, 114626…
#> $ traded_contracts      <int> 8, 2054, 10115, 2202, 14330, 6, 5691, 908, 24029…
#> $ transactions_quantity <int> 2, 205, 709, 87, 3001, 5, 737, 54, 3965, 288, 2,…
#> $ distribution_id       <int> 100, 313, 113, 113, 119, 250, 154, 104, 125, 130…
```

BDRs data

``` r
glimpse(
  cotahist_bdrs_get(ch)
)
#> Rows: 523
#> Columns: 13
#> $ refdate               <date> 2022-04-29, 2022-04-29, 2022-04-29, 2022-04-29,…
#> $ symbol                <chr> "A1AP34", "A1BB34", "A1CR34", "A1DM34", "A1EG34"…
#> $ open                  <dbl> 61.51, 37.36, 59.61, 446.66, 25.50, 100.89, 301.…
#> $ high                  <dbl> 61.51, 37.53, 59.61, 446.66, 25.61, 100.89, 301.…
#> $ low                   <dbl> 61.51, 36.89, 58.71, 443.04, 25.50, 100.89, 301.…
#> $ close                 <dbl> 61.51, 36.89, 58.71, 443.04, 25.61, 100.89, 301.…
#> $ average               <dbl> 61.51, 36.89, 58.71, 444.83, 25.60, 100.89, 301.…
#> $ best_bid              <dbl> 61.51, 36.89, 58.71, 0.00, 25.50, 100.89, 0.00, …
#> $ best_ask              <dbl> 70.10, 58.50, 0.00, 0.00, 25.61, 0.00, 303.25, 3…
#> $ volume                <dbl> 44287.20, 185762.84, 42917.91, 1779.34, 3175.20,…
#> $ traded_contracts      <int> 720, 5035, 731, 4, 124, 660, 1, 340, 1590, 61, 9…
#> $ transactions_quantity <int> 1, 6, 2, 4, 3, 1, 1, 1, 1, 2, 5, 2, 1, 2, 184, 3…
#> $ distribution_id       <int> 110, 102, 106, 109, 102, 110, 109, 106, 101, 109…
```

Equity options

``` r
glimpse(
  cotahist_equity_options_get(ch)
)
#> Rows: 4,794
#> Columns: 14
#> $ refdate               <date> 2022-04-29, 2022-04-29, 2022-04-29, 2022-04-29,…
#> $ symbol                <chr> "ABEVE135", "ABEVE162", "ABEVE140", "ABEVE167", …
#> $ type                  <fct> Call, Call, Call, Call, Call, Call, Call, Put, C…
#> $ strike                <dbl> 13.54, 16.29, 14.04, 16.79, 15.04, 13.04, 27.00,…
#> $ maturity_date         <date> 2022-05-20, 2022-05-20, 2022-05-20, 2022-05-20,…
#> $ open                  <dbl> 1.46, 0.06, 1.07, 0.04, 0.37, 1.98, 0.10, 1.80, …
#> $ high                  <dbl> 1.55, 0.07, 1.19, 0.04, 0.46, 1.98, 0.10, 1.80, …
#> $ low                   <dbl> 1.46, 0.05, 0.92, 0.03, 0.28, 1.84, 0.10, 1.80, …
#> $ close                 <dbl> 1.48, 0.05, 0.92, 0.03, 0.30, 1.84, 0.10, 1.80, …
#> $ average               <dbl> 1.53, 0.05, 1.07, 0.03, 0.37, 1.91, 0.10, 1.80, …
#> $ volume                <dbl> 323814, 412, 12437, 185, 796102, 3820, 30, 10980…
#> $ traded_contracts      <int> 210700, 7800, 11600, 5300, 2102300, 2000, 300, 6…
#> $ transactions_quantity <int> 33, 8, 11, 9, 266, 2, 1, 1, 2, 1, 3, 17, 3, 4, 5…
#> $ distribution_id       <int> 125, 125, 125, 125, 125, 125, 101, 101, 101, 101…
```
