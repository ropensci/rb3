
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
#> $ refdate          <date> 2022-04-01, 2022-04-01, 2022-04-01, 2022-04-01, 2022-04-01, 2022-04-01, 2022-04-01, 2022-04-01, 2022-04-01, 2022-04-01, 20~
#> $ commodity        <chr> "DI1", "DI1", "DI1", "DI1", "DI1", "DI1", "DI1", "DI1", "DI1", "DI1", "DI1", "DI1", "DI1", "DI1", "DI1", "DI1", "DI1", "DI1~
#> $ maturity_code    <chr> "J22", "K22", "M22", "N22", "Q22", "U22", "V22", "X22", "Z22", "F23", "G23", "H23", "J23", "N23", "V23", "F24", "J24", "N24~
#> $ symbol           <chr> "DI1J22", "DI1K22", "DI1M22", "DI1N22", "DI1Q22", "DI1U22", "DI1V22", "DI1X22", "DI1Z22", "DI1F23", "DI1G23", "DI1H23", "DI~
#> $ price_previous   <dbl> 99999.99, 99172.50, 98159.27, 97181.87, 96199.14, 95137.64, 94174.49, 93265.23, 92365.48, 91404.64, 90434.90, 89662.14, 887~
#> $ price            <dbl> 100000.00, 99172.31, 98160.23, 97185.43, 96210.42, 95159.25, 94209.42, 93314.08, 92422.80, 91472.04, 90513.73, 89751.01, 88~
#> $ change           <dbl> 0.01, -0.19, 0.96, 3.56, 11.28, 21.61, 34.93, 48.85, 57.32, 67.40, 78.83, 88.87, 101.84, 150.68, 175.83, 275.55, 370.18, 42~
#> $ settlement_value <dbl> 0.01, 0.19, 0.96, 3.56, 11.28, 21.61, 34.93, 48.85, 57.32, 67.40, 78.83, 88.87, 101.84, 150.68, 175.83, 275.55, 370.18, 423~
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
#> Rows: 367
#> Columns: 13
#> $ refdate               <date> 2022-05-06, 2022-05-06, 2022-05-06, 2022-05-06, 2022-05-06, 2022-05-06, 2022-05-06, 2022-05-06, 2022-05-06, 2022-05-0~
#> $ symbol                <chr> "AALR3", "ABCB4", "ABEV3", "AERI3", "AESB3", "AFLT3", "AGRO3", "AGXY3", "ALLD3", "ALPA3", "ALPA4", "ALPK3", "ALSO3", "~
#> $ open                  <dbl> 19.70, 15.79, 13.73, 4.45, 10.70, 9.74, 33.70, 9.12, 13.50, 18.16, 19.70, 4.07, 19.10, 8.83, 8.72, 2.10, 34.45, 23.29,~
#> $ high                  <dbl> 19.84, 16.21, 13.83, 4.53, 10.98, 9.89, 33.80, 9.23, 13.59, 19.49, 21.59, 4.07, 19.19, 8.91, 8.90, 2.16, 34.45, 23.40,~
#> $ low                   <dbl> 19.55, 15.59, 13.53, 4.31, 10.70, 9.68, 32.85, 8.90, 12.90, 18.16, 19.56, 3.90, 18.34, 8.69, 8.50, 2.06, 31.80, 22.29,~
#> $ close                 <dbl> 19.74, 15.79, 13.53, 4.32, 10.71, 9.68, 33.30, 9.00, 13.32, 19.01, 21.23, 3.90, 18.63, 8.72, 8.50, 2.08, 32.10, 22.38,~
#> $ average               <dbl> 19.71, 15.84, 13.64, 4.42, 10.79, 9.78, 33.32, 9.09, 13.16, 18.91, 20.99, 3.91, 18.58, 8.75, 8.75, 2.10, 32.52, 22.72,~
#> $ best_bid              <dbl> 19.68, 15.78, 13.53, 4.32, 10.70, 9.17, 33.29, 9.00, 13.00, 19.00, 21.23, 3.90, 18.62, 8.72, 8.51, 2.08, 32.08, 22.38,~
#> $ best_ask              <dbl> 19.74, 15.79, 13.55, 4.36, 10.71, 9.88, 33.30, 9.14, 13.32, 19.49, 21.28, 3.94, 18.63, 8.84, 8.76, 2.09, 32.10, 22.40,~
#> $ volume                <dbl> 4762731, 10863637, 299963173, 6516785, 15847229, 4894, 20330650, 497554, 1161289, 98345, 151835589, 58755, 57136524, 7~
#> $ traded_contracts      <int> 241600, 685600, 21978900, 1471300, 1468400, 500, 610100, 54700, 88200, 5200, 7233100, 15000, 3074500, 8600, 17900, 618~
#> $ transactions_quantity <int> 1227, 4594, 29374, 6159, 5941, 5, 3627, 360, 596, 21, 34300, 46, 11553, 50, 83, 8813, 6656, 18474, 9759, 34, 3519, 121~
#> $ distribution_id       <int> 102, 140, 125, 101, 102, 119, 112, 101, 103, 231, 231, 101, 102, 113, 113, 113, 102, 101, 107, 105, 103, 142, 104, 105~
```

Funds data

``` r
glimpse(
  cotahist_funds_get(ch)
)
#> Rows: 358
#> Columns: 13
#> $ refdate               <date> 2022-05-06, 2022-05-06, 2022-05-06, 2022-05-06, 2022-05-06, 2022-05-06, 2022-05-06, 2022-05-06, 2022-05-06, 2022-05-0~
#> $ symbol                <chr> "ABCP11", "AFHI11", "AFOF11", "AIEC11", "ALMI11", "ALZR11", "APTO11", "ARCT11", "ARRI11", "ATSA11", "BARI11", "BBFI11B~
#> $ open                  <dbl> 75.00, 98.95, 90.38, 79.79, 950.00, 115.90, 10.50, 108.06, 95.69, 93.98, 100.21, 2009.99, 71.25, 80.97, 97.73, 66.88, ~
#> $ high                  <dbl> 75.76, 99.19, 90.38, 79.79, 950.00, 116.35, 10.79, 108.44, 96.46, 93.98, 100.47, 2029.00, 72.13, 81.33, 98.45, 66.88, ~
#> $ low                   <dbl> 73.92, 98.80, 88.39, 77.84, 930.50, 115.50, 10.35, 107.33, 95.52, 93.98, 100.04, 1995.50, 70.80, 80.00, 97.00, 66.60, ~
#> $ close                 <dbl> 75.00, 98.90, 89.15, 78.78, 931.00, 116.30, 10.50, 107.99, 95.90, 93.98, 100.40, 1997.08, 71.25, 81.00, 97.40, 66.83, ~
#> $ average               <dbl> 74.53, 98.87, 89.19, 78.55, 940.37, 116.10, 10.58, 108.03, 95.73, 93.98, 100.26, 2006.90, 71.17, 80.82, 97.39, 66.73, ~
#> $ best_bid              <dbl> 74.99, 98.89, 89.15, 78.09, 922.00, 116.25, 10.40, 107.99, 95.71, 88.91, 100.40, 1997.01, 70.83, 81.00, 97.01, 66.83, ~
#> $ best_ask              <dbl> 75.00, 98.90, 89.99, 78.78, 933.00, 116.30, 10.50, 108.00, 95.80, 93.99, 100.51, 2009.97, 71.25, 81.10, 97.47, 66.85, ~
#> $ volume                <dbl> 83995.91, 881581.38, 36391.76, 920055.31, 3761.50, 869599.35, 17947.07, 3104192.19, 143983.25, 93.98, 511672.00, 50975~
#> $ traded_contracts      <int> 1127, 8916, 408, 11712, 4, 7490, 1696, 28733, 1504, 1, 5103, 254, 935, 17694, 588, 35766, 12515, 11334, 4, 10399, 3347~
#> $ transactions_quantity <int> 195, 669, 70, 4213, 4, 1069, 78, 8626, 168, 1, 571, 82, 54, 1199, 70, 5103, 549, 872, 1, 1246, 18, 2, 1612, 2, 2565, 1~
#> $ distribution_id       <int> 314, 113, 113, 120, 250, 154, 105, 125, 131, 136, 137, 302, 116, 214, 228, 251, 185, 190, 129, 106, 122, 114, 119, 105~
```

BDRs data

``` r
glimpse(
  cotahist_bdrs_get(ch)
)
#> Rows: 515
#> Columns: 13
#> $ refdate               <date> 2022-05-06, 2022-05-06, 2022-05-06, 2022-05-06, 2022-05-06, 2022-05-06, 2022-05-06, 2022-05-06, 2022-05-06, 2022-05-0~
#> $ symbol                <chr> "A1AP34", "A1BB34", "A1BM34", "A1CR34", "A1DM34", "A1EE34", "A1EG34", "A1EN34", "A1EP34", "A1IV34", "A1KA34", "A1LB34"~
#> $ open                  <dbl> 63.57, 37.28, 321.73, 62.40, 453.15, 234.36, 25.71, 295.81, 253.75, 29.99, 40.64, 1172.15, 397.57, 473.80, 334.97, 574~
#> $ high                  <dbl> 63.57, 37.28, 321.73, 64.75, 453.15, 235.69, 25.71, 297.90, 256.00, 30.08, 40.64, 1193.57, 401.70, 494.16, 335.92, 574~
#> $ low                   <dbl> 63.57, 36.61, 321.73, 62.40, 453.15, 233.22, 25.39, 295.50, 253.25, 29.79, 40.30, 1172.15, 397.57, 472.82, 334.97, 568~
#> $ close                 <dbl> 63.57, 36.61, 321.73, 64.75, 453.15, 233.85, 25.39, 296.06, 255.00, 29.79, 40.30, 1193.56, 401.70, 483.56, 335.92, 568~
#> $ average               <dbl> 63.57, 36.83, 321.73, 64.72, 453.15, 234.33, 25.55, 295.91, 254.73, 30.07, 40.30, 1192.70, 399.59, 482.99, 335.87, 570~
#> $ best_bid              <dbl> 63.71, 0.00, 0.00, 63.60, 450.14, 0.00, 0.00, 0.00, 0.00, 29.17, 34.75, 0.00, 0.00, 470.00, 0.00, 566.00, 0.00, 0.00, ~
#> $ best_ask              <dbl> 0.00, 58.50, 0.00, 0.00, 0.00, 0.00, 27.45, 0.00, 0.00, 40.65, 0.00, 1247.00, 0.00, 489.34, 0.00, 0.00, 200.00, 0.00, ~
#> $ volume                <dbl> 254.28, 110.50, 321.73, 5112.90, 453.15, 4686.60, 102.20, 337047.14, 4585.25, 3303233.33, 12130.64, 287442.98, 1598.39~
#> $ traded_contracts      <int> 4, 3, 1, 79, 1, 20, 4, 1139, 18, 109815, 301, 241, 4, 7192, 20, 34, 31, 6, 3, 10, 5, 3801, 16, 1031, 21, 26, 527, 278,~
#> $ transactions_quantity <int> 1, 2, 1, 2, 1, 20, 2, 27, 18, 5, 2, 12, 4, 123, 2, 5, 1, 1, 1, 1, 1, 5, 15, 3, 2, 1, 105, 12, 1, 1, 2, 2, 131, 1752, 1~
#> $ distribution_id       <int> 110, 102, 100, 106, 109, 109, 102, 110, 109, 106, 101, 109, 109, 100, 110, 109, 101, 100, 110, 100, 108, 102, 109, 103~
```

Equity options

``` r
glimpse(
  cotahist_equity_options_get(ch)
)
#> Rows: 5,143
#> Columns: 14
#> $ refdate               <date> 2022-05-06, 2022-05-06, 2022-05-06, 2022-05-06, 2022-05-06, 2022-05-06, 2022-05-06, 2022-05-06, 2022-05-06, 2022-05-0~
#> $ symbol                <chr> "ABCBR160", "ABEVA900", "ABEVB15", "ABEVD100", "ABEVD150", "ABEVD220", "ABEVE100", "ABEVE130", "ABEVE132", "ABEVE135",~
#> $ type                  <fct> Put, Call, Call, Call, Call, Call, Call, Call, Call, Call, Call, Call, Call, Call, Call, Call, Call, Call, Call, Call,~
#> $ strike                <dbl> 15.73, 9.00, 14.47, 9.47, 15.00, 21.47, 10.04, 13.04, 13.29, 13.54, 13.79, 14.04, 14.29, 14.54, 14.79, 15.04, 15.29, 1~
#> $ maturity_date         <date> 2022-06-17, 2024-01-19, 2023-02-17, 2023-04-20, 2024-04-19, 2023-04-20, 2022-05-20, 2022-05-20, 2022-05-20, 2022-05-2~
#> $ open                  <dbl> 0.45, 6.45, 1.80, 5.49, 3.18, 0.32, 3.73, 0.83, 0.72, 0.47, 0.33, 0.29, 0.16, 0.11, 0.07, 0.04, 0.03, 0.01, 0.02, 0.01~
#> $ high                  <dbl> 0.45, 6.45, 1.80, 5.49, 3.18, 0.32, 3.73, 0.83, 0.72, 0.54, 0.39, 0.29, 0.19, 0.12, 0.07, 0.04, 0.03, 0.02, 0.02, 0.01~
#> $ low                   <dbl> 0.45, 6.45, 1.80, 5.49, 3.18, 0.20, 3.73, 0.74, 0.56, 0.39, 0.26, 0.17, 0.11, 0.06, 0.03, 0.02, 0.01, 0.01, 0.01, 0.01~
#> $ close                 <dbl> 0.45, 6.45, 1.80, 5.49, 3.18, 0.29, 3.73, 0.74, 0.56, 0.39, 0.28, 0.18, 0.11, 0.06, 0.03, 0.02, 0.02, 0.01, 0.01, 0.01~
#> $ average               <dbl> 0.45, 6.45, 1.80, 5.49, 3.18, 0.30, 3.73, 0.81, 0.57, 0.43, 0.33, 0.22, 0.13, 0.09, 0.05, 0.03, 0.02, 0.01, 0.01, 0.01~
#> $ volume                <dbl> 450, 645, 180, 549, 1590, 1669, 17158, 12002, 4692, 31011, 62069, 257970, 46128, 42782, 9911, 23442, 11352, 1572, 1579~
#> $ traded_contracts      <int> 1000, 100, 100, 100, 500, 5400, 4600, 14800, 8200, 70700, 186000, 1133400, 331200, 472400, 177200, 726700, 542800, 105~
#> $ transactions_quantity <int> 1, 1, 1, 1, 1, 12, 1, 5, 14, 97, 139, 264, 66, 268, 92, 223, 117, 67, 34, 20, 4, 2, 2, 1, 2, 8, 14, 107, 69, 137, 62, ~
#> $ distribution_id       <int> 139, 125, 124, 124, 125, 124, 125, 125, 125, 125, 125, 125, 125, 125, 125, 125, 125, 125, 125, 125, 125, 125, 125, 125~
```
