
<!-- README.md is generated from README.Rmd. Please edit that file -->

# rb3 <img src="man/figures/logo.png" align="right" width="120" />

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
-   B3 indexes composition

Package **rb3** facilitates downloading and reading these datasets from
[B3](https://www.b3.com.br), making it easy to consume it in R in a
structured way. These datasets can be used in industry or academic
studies.

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
#> $ refdate          <date> 2022-04-01, 2022-04-01, 2022-04-01, 2022-04-01, 2022-04-01, 2022-04-01, 2022-04-01, 2022-04-01, 2022-04-01, 2022-04-01, 2022-04-01, 2022-04-01, 2022-04-01~
#> $ commodity        <chr> "DI1", "DI1", "DI1", "DI1", "DI1", "DI1", "DI1", "DI1", "DI1", "DI1", "DI1", "DI1", "DI1", "DI1", "DI1", "DI1", "DI1", "DI1", "DI1", "DI1", "DI1", "DI1", "~
#> $ maturity_code    <chr> "J22", "K22", "M22", "N22", "Q22", "U22", "V22", "X22", "Z22", "F23", "G23", "H23", "J23", "N23", "V23", "F24", "J24", "N24", "V24", "F25", "J25", "N25", "~
#> $ symbol           <chr> "DI1J22", "DI1K22", "DI1M22", "DI1N22", "DI1Q22", "DI1U22", "DI1V22", "DI1X22", "DI1Z22", "DI1F23", "DI1G23", "DI1H23", "DI1J23", "DI1N23", "DI1V23", "DI1F~
#> $ price_previous   <dbl> 99999.99, 99172.50, 98159.27, 97181.87, 96199.14, 95137.64, 94174.49, 93265.23, 92365.48, 91404.64, 90434.90, 89662.14, 88719.94, 86306.50, 84065.98, 82049~
#> $ price            <dbl> 100000.00, 99172.31, 98160.23, 97185.43, 96210.42, 95159.25, 94209.42, 93314.08, 92422.80, 91472.04, 90513.73, 89751.01, 88821.78, 86457.18, 84241.81, 8232~
#> $ change           <dbl> 0.01, -0.19, 0.96, 3.56, 11.28, 21.61, 34.93, 48.85, 57.32, 67.40, 78.83, 88.87, 101.84, 150.68, 175.83, 275.55, 370.18, 423.00, 452.44, 477.65, 497.68, 51~
#> $ settlement_value <dbl> 0.01, 0.19, 0.96, 3.56, 11.28, 21.61, 34.93, 48.85, 57.32, 67.40, 78.83, 88.87, 101.84, 150.68, 175.83, 275.55, 370.18, 423.00, 452.44, 477.65, 497.68, 514~
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
#> Rows: 387
#> Columns: 13
#> $ refdate               <date> 2022-07-19, 2022-07-19, 2022-07-19, 2022-07-19, 2022-07-19, 2022-07-19, 2022-07-19, 2022-07-19, 2022-07-19, 2022-07-19, 2022-07-19, 2022-07-19, 2022-~
#> $ symbol                <chr> "AALR3", "ABCB4", "ABEV3", "AERI3", "AESB3", "AFLT3", "AGRO3", "AGXY3", "ALLD3", "ALPA3", "ALPA4", "ALPK3", "ALSO3", "ALUP3", "ALUP4", "ALUP11", "AMAR~
#> $ open                  <dbl> 19.60, 15.59, 14.49, 2.60, 10.40, 8.80, 23.19, 7.75, 9.55, 15.65, 18.20, 3.05, 16.11, 8.98, 8.81, 26.72, 2.08, 23.52, 15.70, 4.58, 27.16, 10.66, 75.07~
#> $ high                  <dbl> 19.60, 16.16, 14.76, 2.66, 10.51, 8.80, 23.40, 7.75, 9.87, 16.16, 19.63, 3.40, 16.38, 9.15, 8.95, 26.94, 2.12, 24.45, 16.46, 4.63, 27.20, 11.00, 75.17~
#> $ low                   <dbl> 19.26, 15.46, 14.42, 2.51, 10.28, 8.80, 22.89, 7.43, 9.43, 15.65, 18.19, 2.72, 15.92, 8.98, 8.77, 26.51, 2.00, 23.38, 15.27, 4.33, 26.22, 10.43, 72.73~
#> $ close                 <dbl> 19.50, 16.09, 14.48, 2.52, 10.49, 8.80, 23.27, 7.58, 9.59, 16.16, 19.59, 2.76, 16.14, 9.04, 8.95, 26.91, 2.04, 24.30, 16.19, 4.39, 27.10, 10.66, 73.83~
#> $ average               <dbl> 19.43, 15.93, 14.56, 2.55, 10.38, 8.80, 23.17, 7.55, 9.61, 15.96, 19.11, 2.99, 16.13, 9.05, 8.84, 26.80, 2.04, 23.99, 15.93, 4.44, 26.86, 10.63, 73.89~
#> $ best_bid              <dbl> 19.43, 16.07, 14.47, 2.52, 10.43, 8.70, 23.27, 7.58, 9.59, 15.67, 19.52, 2.76, 16.12, 8.98, 8.89, 26.84, 2.03, 24.27, 16.18, 4.36, 27.10, 10.64, 73.80~
#> $ best_ask              <dbl> 19.50, 16.09, 14.48, 2.55, 10.49, 9.10, 23.34, 7.60, 9.86, 16.39, 19.59, 2.80, 16.14, 9.04, 8.95, 26.91, 2.04, 24.32, 16.19, 4.39, 27.30, 10.66, 73.83~
#> $ volume                <dbl> 3861387, 7566724, 311196896, 5745423, 11659815, 1760, 9852249, 1182067, 552694, 71823, 91523349, 2305157, 19325621, 28057, 76944, 15488703, 10091183, ~
#> $ traded_contracts      <dbl> 198700, 474900, 21362100, 2249900, 1122400, 200, 425200, 156500, 57500, 4500, 4787500, 769500, 1197700, 3100, 8700, 577900, 4942300, 845400, 12412700,~
#> $ transactions_quantity <int> 998, 3158, 24903, 5962, 3957, 2, 2351, 464, 381, 19, 18887, 1720, 5233, 23, 54, 3502, 3740, 4716, 20473, 6337, 80, 1212, 5438, 10896, 66, 8615, 3, 162~
#> $ distribution_id       <int> 102, 141, 125, 101, 102, 119, 112, 101, 103, 231, 231, 101, 102, 113, 113, 113, 113, 102, 101, 107, 105, 104, 143, 104, 105, 101, 101, 120, 120, 101, ~
```

Funds data

``` r
glimpse(
  cotahist_etfs_get(ch)
)
#> Rows: 89
#> Columns: 13
#> $ refdate               <date> 2022-07-19, 2022-07-19, 2022-07-19, 2022-07-19, 2022-07-19, 2022-07-19, 2022-07-19, 2022-07-19, 2022-07-19, 2022-07-19, 2022-07-19, 2022-07-19, 2022-~
#> $ symbol                <chr> "5GTK11", "ACWI11", "AGRI11", "ALUG11", "ASIA11", "BBOV11", "BBSD11", "BDIV11", "BITH11", "BLOK11", "BNDX11", "BOVA11", "BOVB11", "BOVS11", "BOVV11", ~
#> $ open                  <dbl> 83.42, 9.32, 44.66, 38.62, 7.84, 50.19, 79.89, 92.49, 28.24, 125.10, 97.02, 93.72, 98.15, 74.95, 98.79, 9.74, 82.29, 60.00, 68.40, 9.63, 5.85, 27.00, ~
#> $ high                  <dbl> 85.20, 9.55, 44.90, 39.74, 7.95, 50.56, 80.53, 92.49, 30.50, 125.10, 101.01, 94.84, 98.71, 75.76, 99.19, 9.87, 82.50, 60.81, 71.40, 9.67, 6.04, 27.00,~
#> $ low                   <dbl> 83.42, 9.20, 44.66, 38.62, 7.84, 50.01, 78.01, 91.37, 28.00, 125.10, 97.02, 93.57, 97.57, 74.79, 97.90, 9.73, 82.13, 60.00, 68.40, 9.55, 5.85, 24.86, ~
#> $ close                 <dbl> 85.20, 9.55, 44.90, 39.46, 7.95, 50.56, 80.35, 91.51, 30.35, 125.10, 101.01, 94.70, 98.71, 75.75, 99.15, 9.87, 82.50, 60.00, 71.40, 9.62, 6.04, 25.48,~
#> $ average               <dbl> 84.31, 9.54, 44.82, 39.23, 7.94, 50.50, 80.35, 91.60, 29.00, 125.10, 99.68, 94.32, 98.68, 75.39, 98.75, 9.84, 82.19, 60.03, 69.85, 9.58, 5.95, 25.79, ~
#> $ best_bid              <dbl> 84.68, 9.55, 44.80, 39.46, 7.95, 50.50, 79.64, 91.51, 30.00, 0.00, 101.01, 94.70, 98.71, 75.67, 98.25, 9.82, 82.50, 60.00, 68.29, 9.60, 6.04, 25.30, 6~
#> $ best_ask              <dbl> 85.20, 9.58, 55.00, 39.74, 7.96, 51.42, 80.71, 92.00, 30.35, 0.00, 0.00, 94.71, 109.45, 75.75, 99.15, 9.87, 90.00, 60.85, 71.40, 9.75, 6.05, 25.67, 66~
#> $ volume                <dbl> 2.183730e+04, 1.419632e+06, 1.017549e+04, 1.141656e+05, 1.107930e+04, 4.079553e+05, 2.016873e+04, 5.912812e+05, 2.153020e+06, 1.251000e+02, 2.990400e+~
#> $ traded_contracts      <dbl> 259, 148797, 227, 2910, 1394, 8078, 251, 6455, 74225, 1, 3, 12130579, 10563, 525, 1392925, 12812596, 1007, 15458, 301, 1156, 894, 3222, 19318, 111, 50~
#> $ transactions_quantity <int> 8, 227, 6, 47, 14, 26, 21, 632, 1154, 1, 3, 70270, 17, 399, 15202, 36383, 5, 1357, 6, 56, 46, 49, 927, 1, 4, 16, 13, 108, 3, 2, 8, 3, 1041, 926, 2, 44~
#> $ distribution_id       <int> 100, 100, 100, 100, 100, 100, 100, 107, 100, 100, 100, 106, 100, 100, 101, 100, 100, 129, 100, 100, 100, 100, 100, 100, 100, 100, 100, 103, 100, 100, ~
```

FIIs data

``` r
glimpse(
  cotahist_fiis_get(ch)
)
#> Rows: 265
#> Columns: 13
#> $ refdate               <date> 2022-07-19, 2022-07-19, 2022-07-19, 2022-07-19, 2022-07-19, 2022-07-19, 2022-07-19, 2022-07-19, 2022-07-19, 2022-07-19, 2022-07-19, 2022-07-19, 2022-~
#> $ symbol                <chr> "ABCP11", "AFHI11", "AFOF11", "AIEC11", "ALMI11", "ALZR11", "APTO11", "ARCT11", "ARRI11", "ATSA11", "BARI11", "BBFI11B", "BBFO11", "BBPO11", "BBRC11",~
#> $ open                  <dbl> 71.42, 99.00, 87.41, 74.88, 870.00, 112.58, 9.95, 103.15, 92.20, 85.01, 99.80, 1769.99, 71.20, 78.80, 97.95, 64.48, 82.75, 107.98, 98.01, 9.43, 94.99,~
#> $ high                  <dbl> 71.67, 99.50, 88.09, 74.88, 894.80, 112.58, 9.95, 103.45, 92.76, 88.97, 100.04, 1790.00, 71.20, 79.00, 98.00, 64.97, 83.31, 107.98, 98.01, 9.46, 94.99~
#> $ low                   <dbl> 69.97, 98.60, 85.00, 73.99, 851.01, 111.50, 9.59, 101.98, 91.87, 85.01, 99.72, 1760.00, 70.66, 78.49, 97.50, 64.45, 82.61, 106.71, 98.01, 9.28, 94.99,~
#> $ close                 <dbl> 71.10, 99.29, 87.75, 74.50, 853.02, 111.80, 9.60, 103.32, 92.45, 88.96, 100.00, 1760.00, 70.98, 78.67, 98.00, 64.78, 82.96, 107.10, 98.01, 9.33, 94.99~
#> $ average               <dbl> 70.84, 99.11, 87.15, 74.43, 856.31, 111.96, 9.60, 102.78, 92.24, 86.45, 99.94, 1771.61, 71.04, 78.77, 97.86, 64.73, 82.81, 107.32, 98.01, 9.34, 94.99,~
#> $ best_bid              <dbl> 71.10, 99.29, 87.72, 74.41, 853.02, 111.79, 9.59, 103.31, 92.45, 85.04, 100.00, 1758.00, 70.87, 78.57, 97.81, 64.77, 82.90, 107.10, 98.00, 9.33, 88.03~
#> $ best_ask              <dbl> 71.15, 99.46, 87.75, 74.50, 888.95, 111.80, 9.60, 103.32, 92.47, 88.94, 100.20, 1778.90, 70.98, 78.67, 98.67, 64.78, 82.96, 107.14, 99.90, 9.39, 94.99~
#> $ volume                <dbl> 170726.75, 620589.45, 57084.83, 452211.56, 25689.41, 1628864.00, 28993.22, 1611046.33, 236877.69, 950.98, 675300.24, 187791.55, 229704.45, 1343656.11,~
#> $ traded_contracts      <dbl> 2410, 6261, 655, 6075, 30, 14548, 3017, 15674, 2568, 11, 6757, 106, 3233, 17056, 563, 35900, 6801, 9784, 7, 29944, 1, 864, 95, 7885, 30, 66918, 305, 4~
#> $ transactions_quantity <int> 264, 1611, 82, 388, 18, 2286, 148, 2969, 250, 6, 777, 64, 81, 1326, 72, 3701, 419, 1007, 2, 407, 1, 10, 17, 1907, 7, 3268, 8, 83, 470, 22, 4407, 6694,~
#> $ distribution_id       <int> 316, 117, 116, 122, 250, 158, 107, 129, 133, 136, 139, 304, 118, 216, 230, 254, 187, 192, 131, 108, 107, 125, 117, 122, 107, 118, 227, 218, 213, 118, ~
```

BDRs data

``` r
glimpse(
  cotahist_bdrs_get(ch)
)
#> Rows: 471
#> Columns: 13
#> $ refdate               <date> 2022-07-19, 2022-07-19, 2022-07-19, 2022-07-19, 2022-07-19, 2022-07-19, 2022-07-19, 2022-07-19, 2022-07-19, 2022-07-19, 2022-07-19, 2022-07-19, 2022-~
#> $ symbol                <chr> "A1AP34", "A1BB34", "A1CR34", "A1EG34", "A1ES34", "A1IV34", "A1KA34", "A1LB34", "A1LG34", "A1LL34", "A1LN34", "A1MD34", "A1MP34", "A1MT34", "A1MX34", ~
#> $ open                  <dbl> 64.08, 37.54, 68.39, 22.84, 111.20, 37.20, 40.28, 1138.55, 357.70, 59.16, 39.24, 439.00, 321.32, 516.00, 50.84, 139.58, 180.11, 304.35, 194.11, 18.91,~
#> $ high                  <dbl> 64.20, 37.98, 68.71, 23.00, 111.30, 38.40, 40.32, 1138.86, 362.25, 59.58, 39.32, 465.62, 321.32, 528.36, 50.93, 141.17, 184.98, 313.00, 196.62, 19.44,~
#> $ low                   <dbl> 64.04, 37.54, 68.31, 22.73, 111.20, 37.20, 40.28, 1131.39, 357.70, 59.16, 39.24, 439.00, 321.16, 516.00, 50.84, 139.16, 180.11, 303.60, 194.11, 18.91,~
#> $ close                 <dbl> 64.11, 37.97, 68.71, 23.00, 111.25, 38.40, 40.28, 1138.86, 361.55, 59.58, 39.28, 465.56, 321.16, 528.36, 50.93, 141.17, 184.98, 313.00, 196.50, 19.42,~
#> $ average               <dbl> 64.09, 37.88, 68.43, 22.95, 111.26, 37.71, 40.30, 1133.84, 361.48, 59.23, 39.25, 449.66, 321.24, 518.70, 50.89, 140.97, 181.75, 307.93, 195.44, 18.95,~
#> $ best_bid              <dbl> 0.00, 37.56, 0.00, 22.72, 50.00, 33.48, 39.27, 0.00, 333.40, 47.00, 27.98, 450.00, 0.00, 483.90, 0.00, 0.00, 95.00, 275.20, 159.17, 19.06, 18.89, 236.~
#> $ best_ask              <dbl> 0.00, 0.00, 0.00, 24.49, 0.00, 44.50, 0.00, 1238.85, 925.00, 99.70, 54.60, 477.92, 0.00, 594.00, 0.00, 200.00, 0.00, 0.00, 0.00, 0.00, 30.00, 287.77, ~
#> $ volume                <dbl> 640.99, 1970.22, 1026.56, 367.26, 556.30, 4449.96, 846.38, 10204.61, 13736.45, 355.38, 706.60, 431224.11, 642.48, 38902.64, 1679.60, 3806.40, 3635.01,~
#> $ traded_contracts      <dbl> 10, 52, 15, 16, 5, 118, 21, 9, 38, 6, 18, 959, 2, 75, 33, 27, 20, 4098, 13, 4811, 39, 11, 94, 12, 22, 3208, 276, 103, 2, 347, 315989, 21, 200, 75, 7, ~
#> $ transactions_quantity <int> 10, 11, 9, 10, 5, 5, 8, 3, 9, 3, 7, 77, 2, 12, 8, 3, 4, 440, 8, 12, 14, 9, 5, 1, 8, 81, 16, 1, 1, 25, 1596, 12, 11, 12, 7, 90, 78, 13, 6183, 28, 3, 18~
#> $ distribution_id       <int> 111, 102, 107, 103, 110, 106, 101, 110, 100, 111, 100, 100, 110, 110, 103, 101, 110, 110, 110, 102, 103, 100, 110, 110, 100, 103, 100, 102, 100, 115, ~
```

Equity options

``` r
glimpse(
  cotahist_equity_options_get(ch)
)
#> Rows: 4,874
#> Columns: 14
#> $ refdate               <date> 2022-07-19, 2022-07-19, 2022-07-19, 2022-07-19, 2022-07-19, 2022-07-19, 2022-07-19, 2022-07-19, 2022-07-19, 2022-07-19, 2022-07-19, 2022-07-19, 2022-~
#> $ symbol                <chr> "ABCBH170", "ABEVH160", "ABEVB15", "ABEVI24", "ABEVI250", "ABEVH138", "ABEVH165", "ABEVH150", "ABEVH168", "ABEVI17", "ABEVI217", "ABEVL161", "ABEVL154~
#> $ type                  <fct> Call, Call, Call, Call, Call, Call, Call, Call, Call, Call, Call, Call, Call, Call, Call, Call, Call, Call, Call, Call, Call, Call, Call, Call, Call, ~
#> $ strike                <dbl> 16.70, 15.04, 14.47, 23.47, 24.47, 13.29, 16.04, 14.54, 16.29, 16.47, 21.22, 15.64, 14.89, 14.39, 14.79, 13.79, 16.57, 15.79, 14.29, 15.97, 17.47, 15.~
#> $ maturity_date         <date> 2022-08-19, 2022-08-19, 2023-02-17, 2022-09-16, 2022-09-16, 2022-08-19, 2022-08-19, 2022-08-19, 2022-08-19, 2022-09-16, 2022-09-16, 2022-12-16, 2022-~
#> $ open                  <dbl> 0.08, 0.38, 1.99, 0.01, 0.01, 1.49, 0.09, 0.59, 0.09, 0.19, 0.01, 0.96, 1.50, 1.74, 0.47, 1.24, 0.84, 0.15, 0.75, 0.30, 0.07, 0.48, 0.11, 0.40, 0.27, ~
#> $ high                  <dbl> 0.18, 0.46, 1.99, 0.03, 0.03, 1.49, 0.14, 0.74, 0.11, 0.21, 0.03, 0.96, 1.50, 1.74, 0.59, 1.24, 0.84, 0.20, 0.99, 0.32, 0.07, 0.48, 0.14, 0.40, 0.36, ~
#> $ low                   <dbl> 0.08, 0.32, 1.72, 0.01, 0.01, 1.49, 0.09, 0.55, 0.08, 0.19, 0.01, 0.96, 1.50, 1.74, 0.43, 1.16, 0.84, 0.13, 0.71, 0.30, 0.07, 0.40, 0.11, 0.40, 0.25, ~
#> $ close                 <dbl> 0.12, 0.32, 1.92, 0.03, 0.03, 1.49, 0.10, 0.55, 0.08, 0.19, 0.03, 0.96, 1.50, 1.74, 0.43, 1.16, 0.84, 0.13, 0.71, 0.32, 0.07, 0.40, 0.14, 0.40, 0.25, ~
#> $ average               <dbl> 0.13, 0.38, 1.87, 0.02, 0.02, 1.49, 0.12, 0.60, 0.09, 0.19, 0.02, 0.96, 1.50, 1.74, 0.52, 1.16, 0.84, 0.15, 0.82, 0.31, 0.07, 0.43, 0.13, 0.40, 0.28, ~
#> $ volume                <dbl> 106, 144742, 5258, 400, 400, 14900, 20419, 216505, 1405, 1367, 400, 1920, 300, 696, 211283, 6527, 840, 14527, 269138, 1240, 182, 5594, 4103, 200, 2352~
#> $ traded_contracts      <dbl> 800, 376500, 2800, 20000, 20000, 10000, 166600, 355200, 14200, 7100, 20000, 2000, 200, 400, 404500, 5600, 1000, 92900, 325700, 4000, 2600, 12800, 3010~
#> $ transactions_quantity <int> 5, 209, 17, 2, 2, 2, 87, 149, 12, 6, 2, 2, 1, 4, 143, 4, 1, 39, 66, 2, 4, 10, 9, 1, 101, 1, 1, 2, 3, 73, 81, 37, 13, 3, 1, 1, 1, 1, 6, 1, 10, 1, 1, 17~
#> $ distribution_id       <int> 140, 122, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 124, 125, 125, 125, 125, 125, 125, 125, 125, 125, 125, 125, 125, 125, 125, 125, 125, 125, ~
```

### Indexes composition

The list with available B3 indexes can be obtained with `indexes_get`.

``` r
indexes_get()
#>  [1] "AGFS" "BDRX" "GPTW" "IBOV" "IBRA" "IBXL" "IBXX" "ICO2" "ICON" "IDIV" "IEEX" "IFIL" "IFIX" "IFNC" "IGCT" "IGCX" "IGNM" "IMAT" "IMOB" "INDX" "ISEE" "ITAG" "IVBX" "MLCX" "SMLL"
#> [26] "UTIL"
```

And the composition of a specific index with `index_comp_get`.

``` r
(ibov_comp <- index_comp_get("IBOV"))
#>  [1] "ABEV3"  "ALPA4"  "AMER3"  "ASAI3"  "AZUL4"  "B3SA3"  "BBAS3"  "BBDC3"  "BBDC4"  "BBSE3"  "BEEF3"  "BIDI11" "BPAC11" "BPAN4"  "BRAP4"  "BRFS3"  "BRKM5"  "BRML3"  "CASH3" 
#> [20] "CCRO3"  "CIEL3"  "CMIG4"  "CMIN3"  "COGN3"  "CPFE3"  "CPLE6"  "CRFB3"  "CSAN3"  "CSNA3"  "CVCB3"  "CYRE3"  "DXCO3"  "ECOR3"  "EGIE3"  "ELET3"  "ELET6"  "EMBR3"  "ENBR3" 
#> [39] "ENEV3"  "ENGI11" "EQTL3"  "EZTC3"  "FLRY3"  "GGBR4"  "GOAU4"  "GOLL4"  "HAPV3"  "HYPE3"  "IGTI11" "IRBR3"  "ITSA4"  "ITUB4"  "JBSS3"  "JHSF3"  "KLBN11" "LCAM3"  "LREN3" 
#> [58] "LWSA3"  "MGLU3"  "MRFG3"  "MRVE3"  "MULT3"  "NTCO3"  "PCAR3"  "PETR3"  "PETR4"  "PETZ3"  "POSI3"  "PRIO3"  "QUAL3"  "RADL3"  "RAIL3"  "RDOR3"  "RENT3"  "RRRP3"  "SANB11"
#> [77] "SBSP3"  "SLCE3"  "SOMA3"  "SULA11" "SUZB3"  "TAEE11" "TIMS3"  "TOTS3"  "UGPA3"  "USIM5"  "VALE3"  "VBBR3"  "VIIA3"  "VIVT3"  "WEGE3"  "YDUQ3"
```

With the index composition you can use COTAHIST to select their quotes.

``` r
glimpse(
  cotahist_get_symbols(ch, ibov_comp)
)
#> Rows: 90
#> Columns: 13
#> $ refdate               <date> 2022-07-19, 2022-07-19, 2022-07-19, 2022-07-19, 2022-07-19, 2022-07-19, 2022-07-19, 2022-07-19, 2022-07-19, 2022-07-19, 2022-07-19, 2022-07-19, 2022-~
#> $ symbol                <chr> "ABEV3", "ALPA4", "AMER3", "ASAI3", "AZUL4", "B3SA3", "BBAS3", "BBDC3", "BBDC4", "BBSE3", "BEEF3", "BPAC11", "BPAN4", "BRAP4", "BRFS3", "BRKM5", "BRML~
#> $ open                  <dbl> 14.49, 18.20, 15.70, 15.48, 12.15, 10.27, 33.88, 13.90, 16.79, 27.00, 13.10, 21.80, 6.28, 22.54, 14.84, 34.12, 7.57, 1.07, 12.22, 4.21, 10.38, 3.34, 2~
#> $ high                  <dbl> 14.76, 19.63, 16.46, 15.68, 12.58, 10.50, 34.70, 14.34, 17.29, 27.11, 13.72, 22.79, 6.46, 22.72, 15.32, 34.73, 7.64, 1.09, 12.22, 4.21, 10.43, 3.45, 2~
#> $ low                   <dbl> 14.42, 18.19, 15.27, 15.28, 12.15, 10.13, 33.79, 13.86, 16.65, 26.60, 13.06, 21.64, 6.19, 22.42, 14.68, 34.03, 7.50, 1.03, 12.00, 4.06, 10.31, 3.33, 2~
#> $ close                 <dbl> 14.48, 19.59, 16.19, 15.49, 12.54, 10.21, 34.66, 14.33, 17.26, 27.01, 13.65, 22.71, 6.43, 22.60, 14.96, 34.54, 7.55, 1.06, 12.04, 4.15, 10.39, 3.44, 2~
#> $ average               <dbl> 14.56, 19.11, 15.93, 15.49, 12.40, 10.23, 34.31, 14.17, 17.08, 26.92, 13.48, 22.33, 6.31, 22.56, 15.00, 34.47, 7.57, 1.05, 12.07, 4.11, 10.38, 3.40, 2~
#> $ best_bid              <dbl> 14.47, 19.52, 16.18, 15.49, 12.53, 10.21, 34.65, 14.33, 17.25, 27.00, 13.65, 22.70, 6.43, 22.59, 14.96, 34.54, 7.55, 1.05, 12.02, 4.13, 10.39, 3.43, 2~
#> $ best_ask              <dbl> 14.48, 19.59, 16.19, 15.50, 12.54, 10.22, 34.67, 14.34, 17.26, 27.01, 13.66, 22.71, 6.44, 22.62, 14.97, 34.55, 7.56, 1.06, 12.04, 4.15, 10.40, 3.44, 2~
#> $ volume                <dbl> 311196896, 91523349, 197838515, 51779881, 127977669, 484826117, 528883931, 84369597, 559754157, 90784902, 81540454, 300875020, 16147142, 57280090, 116~
#> $ traded_contracts      <dbl> 21362100, 4787500, 12412700, 3342100, 10312500, 47346400, 15414400, 5954000, 32754800, 3371400, 6045900, 13473600, 2555800, 2538500, 7773200, 1033200,~
#> $ transactions_quantity <int> 24903, 18887, 20473, 10896, 15150, 71311, 50014, 7382, 42931, 11898, 12572, 26367, 3822, 6438, 22153, 6113, 8227, 74730, 13873, 12756, 7518, 5230, 147~
#> $ distribution_id       <int> 125, 231, 101, 104, 101, 122, 307, 744, 744, 120, 113, 112, 113, 143, 120, 120, 117, 102, 141, 149, 232, 104, 103, 134, 143, 112, 123, 256, 114, 137, ~
```

## Template System

One important part of `rb3` infrastructure is its `Template System`.

All datasets handled by the rb3 package are configured in a template,
that is an YAML file. The template brings many information regarding the
datasets, like its description and its metadata that describes its
columns, their types and how it has to be parsed. The template fully
describes its dataset.

Once you have the template implemented you can fetch and read downloaded
data directly with the functions `download_marketdata` and
`read_marketdata`.

For examples, let’s use the template `FPR` to download and read data
regarding primitive risk factor used by B3 in its risk engine.

``` r
f <- download_marketdata("FPR", refdate = as.Date("2022-05-10"))
f
#> [1] "C:/Users/wilso/R/rb3-cache/FPR/7a2422cc97221426a3b2bd4419215481/FP220510/FatoresPrimitivosRisco.txt"
```

`download_marketdata` returns the path for the downloaded file.

``` r
fpr <- read_marketdata(f, "FPR")
fpr
#> $Header
#> # A tibble: 1 x 2
#>   tipo_registro data_geracao_arquivo
#>           <int> <date>              
#> 1             1 2022-05-10          
#> 
#> $Data
#> # A tibble: 3,204 x 11
#>    tipo_registro id_fpr nome_fpr formato_variacao id_grupo_fpr id_camara_indicador id_instrumento_indicador origem_instrumento  base base_interpolacao criterio_capitalizacao
#>            <int>  <int> <chr>    <fct>                   <dbl> <chr>                                  <dbl>              <int> <int>             <int>                  <int>
#>  1             2   1422 VLRAPT4  Basis Points                1 BVMF                            200000008810                  8     0                 0                      0
#>  2             2   1423 VLPETR3  Basis Points                1 BVMF                            200000008803                  8     0                 0                      0
#>  3             2   1424 VLSEER3  Basis Points                1 BVMF                            200000008818                  8     0                 0                      0
#>  4             2   1426 VLJBSS3  Basis Points                1 BVMF                            200000008780                  8     0                 0                      0
#>  5             2   1427 VLKLBN11 Basis Points                1 BVMF                            200000008781                  8     0                 0                      0
#>  6             2   1428 VLITUB3  Basis Points                1 BVMF                            200000463163                  8     0                 0                      0
#>  7             2   1429 VLITSA4  Basis Points                1 BVMF                            200000008777                  8     0                 0                      0
#>  8             2   1430 VLHYPE3  Basis Points                1 BVMF                            200000008773                  8     0                 0                      0
#>  9             2   1431 VLGRND3  Basis Points                1 BVMF                            200000008770                  8     0                 0                      0
#> 10             2   1433 VLUGPA3  Basis Points                1 BVMF                            200000008830                  8     0                 0                      0
#> # ... with 3,194 more rows
#> 
#> attr(,"class")
#> [1] "parts"
```

`read_marketdata` parses the downloaded file according to the metadata
configured in the template `FPR`.

Here it follows a view of the `show_templates` adding that lists the
available templates.

``` r
show_templates()
```

<img src="man/figures/rb3-templates.png" width="100%" />
