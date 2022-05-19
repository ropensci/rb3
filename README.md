
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
#> $ refdate          <date> 2022-04-01, 2022-04-01, 2022-04-01, 2022-04-01, 2022-04-01, 2022-04-01, 2022-04-01, 2022-04-01, 2022-04-01, 2022-04-01, 2022-04-01, 2022-04-01, 2022-04~
#> $ commodity        <chr> "DI1", "DI1", "DI1", "DI1", "DI1", "DI1", "DI1", "DI1", "DI1", "DI1", "DI1", "DI1", "DI1", "DI1", "DI1", "DI1", "DI1", "DI1", "DI1", "DI1", "DI1", "DI1"~
#> $ maturity_code    <chr> "J22", "K22", "M22", "N22", "Q22", "U22", "V22", "X22", "Z22", "F23", "G23", "H23", "J23", "N23", "V23", "F24", "J24", "N24", "V24", "F25", "J25", "N25"~
#> $ symbol           <chr> "DI1J22", "DI1K22", "DI1M22", "DI1N22", "DI1Q22", "DI1U22", "DI1V22", "DI1X22", "DI1Z22", "DI1F23", "DI1G23", "DI1H23", "DI1J23", "DI1N23", "DI1V23", "D~
#> $ price_previous   <dbl> 99999.99, 99172.50, 98159.27, 97181.87, 96199.14, 95137.64, 94174.49, 93265.23, 92365.48, 91404.64, 90434.90, 89662.14, 88719.94, 86306.50, 84065.98, 82~
#> $ price            <dbl> 100000.00, 99172.31, 98160.23, 97185.43, 96210.42, 95159.25, 94209.42, 93314.08, 92422.80, 91472.04, 90513.73, 89751.01, 88821.78, 86457.18, 84241.81, 8~
#> $ change           <dbl> 0.01, -0.19, 0.96, 3.56, 11.28, 21.61, 34.93, 48.85, 57.32, 67.40, 78.83, 88.87, 101.84, 150.68, 175.83, 275.55, 370.18, 423.00, 452.44, 477.65, 497.68,~
#> $ settlement_value <dbl> 0.01, 0.19, 0.96, 3.56, 11.28, 21.61, 34.93, 48.85, 57.32, 67.40, 78.83, 88.87, 101.84, 150.68, 175.83, 275.55, 370.18, 423.00, 452.44, 477.65, 497.68, ~
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
#> Rows: 381
#> Columns: 13
#> $ refdate               <date> 2022-05-18, 2022-05-18, 2022-05-18, 2022-05-18, 2022-05-18, 2022-05-18, 2022-05-18, 2022-05-18, 2022-05-18, 2022-05-18, 2022-05-18, 2022-05-18, 20~
#> $ symbol                <chr> "AALR3", "ABCB4", "ABEV3", "AERI3", "AESB3", "AFLT3", "AGRO3", "AGXY3", "ALLD3", "ALPA3", "ALPA4", "ALPK3", "ALSO3", "ALUP3", "ALUP4", "ALUP11", "A~
#> $ open                  <dbl> 19.77, 16.81, 14.72, 3.89, 10.81, 9.16, 31.62, 9.94, 12.25, 18.35, 21.29, 3.83, 20.11, 8.82, 8.82, 26.40, 2.40, 30.30, 22.94, 5.71, 34.83, 12.98, 8~
#> $ high                  <dbl> 20.06, 16.93, 14.82, 3.95, 10.89, 9.16, 31.99, 10.30, 12.43, 18.60, 21.63, 3.83, 20.21, 8.92, 8.88, 26.60, 2.48, 31.78, 23.50, 5.76, 36.00, 13.15, ~
#> $ low                   <dbl> 19.74, 16.41, 14.18, 3.76, 10.66, 9.16, 30.45, 9.94, 11.66, 17.90, 20.74, 3.67, 19.16, 8.73, 8.76, 26.22, 2.31, 30.06, 22.56, 5.45, 33.79, 12.72, 8~
#> $ close                 <dbl> 20.06, 16.61, 14.22, 3.78, 10.68, 9.16, 30.62, 9.98, 11.81, 17.91, 20.94, 3.67, 19.35, 8.88, 8.76, 26.40, 2.35, 31.19, 22.95, 5.54, 35.33, 13.00, 8~
#> $ average               <dbl> 19.89, 16.59, 14.42, 3.82, 10.74, 9.16, 30.99, 10.07, 11.89, 18.19, 21.04, 3.78, 19.45, 8.83, 8.80, 26.41, 2.38, 31.04, 22.97, 5.57, 35.67, 12.95, ~
#> $ best_bid              <dbl> 20.05, 16.60, 14.22, 3.77, 10.68, 9.06, 30.62, 9.98, 11.81, 17.90, 20.91, 3.66, 19.35, 8.87, 8.75, 26.34, 2.35, 31.04, 22.92, 5.53, 34.00, 12.98, 8~
#> $ best_ask              <dbl> 20.09, 16.61, 14.23, 3.78, 10.71, 9.46, 30.70, 10.00, 11.98, 20.00, 20.95, 3.82, 19.40, 8.88, 8.80, 26.40, 2.36, 31.19, 22.95, 5.54, 35.98, 13.03, ~
#> $ volume                <dbl> 10070975, 11310732, 425796280, 7981542, 9264003, 6412, 17228579, 502600, 1295768, 136426, 80283647, 212998, 44464947, 76829, 61642, 41557139, 14061~
#> $ traded_contracts      <int> 506100, 681700, 29516600, 2087900, 862300, 700, 555900, 49900, 108900, 7500, 3814800, 56300, 2286000, 8700, 7000, 1573300, 5884000, 1319900, 102964~
#> $ transactions_quantity <int> 2069, 4754, 50558, 4973, 3369, 3, 2778, 312, 623, 25, 19031, 149, 9519, 64, 45, 6068, 4665, 6909, 21590, 3080, 1180, 3316, 5567, 13942, 111, 5901, ~
#> $ distribution_id       <int> 102, 140, 125, 101, 102, 119, 112, 101, 103, 231, 231, 101, 102, 113, 113, 113, 113, 102, 101, 107, 105, 103, 142, 104, 105, 101, 101, 119, 119, 10~
```

Funds data

``` r
glimpse(
  cotahist_etfs_get(ch)
)
#> Rows: 81
#> Columns: 13
#> $ refdate               <date> 2022-05-18, 2022-05-18, 2022-05-18, 2022-05-18, 2022-05-18, 2022-05-18, 2022-05-18, 2022-05-18, 2022-05-18, 2022-05-18, 2022-05-18, 2022-05-18, 20~
#> $ symbol                <chr> "5GTK11", "ACWI11", "ALUG11", "ASIA11", "BBOV11", "BBSD11", "BDIV11", "BITH11", "BOVA11", "BOVB11", "BOVS11", "BOVV11", "BOVX11", "BRAX11", "BRZP11~
#> $ open                  <dbl> 80.00, 9.11, 37.50, 7.30, 56.40, 91.65, 92.00, 35.60, 104.78, 108.49, 83.27, 109.48, 10.89, 90.51, 65.57, 53.80, 11.08, 8.84, 25.19, 71.25, 33.00, ~
#> $ high                  <dbl> 80.00, 9.11, 37.50, 7.37, 56.40, 91.65, 92.90, 36.50, 104.78, 108.49, 83.27, 109.48, 10.89, 90.51, 66.67, 53.80, 11.08, 8.84, 25.39, 71.75, 33.05, ~
#> $ low                   <dbl> 77.10, 8.86, 36.85, 7.22, 54.45, 89.60, 91.96, 34.18, 102.15, 106.54, 81.54, 106.81, 10.61, 89.21, 65.15, 53.80, 10.75, 8.39, 23.00, 70.25, 31.96, ~
#> $ close                 <dbl> 78.25, 8.90, 36.95, 7.27, 54.45, 89.60, 92.55, 35.40, 102.21, 106.70, 81.71, 106.86, 10.63, 89.30, 65.16, 53.80, 10.77, 8.50, 23.20, 70.25, 32.30, ~
#> $ average               <dbl> 78.85, 8.90, 37.15, 7.26, 54.45, 89.85, 92.20, 34.91, 102.94, 106.78, 82.18, 108.19, 10.66, 89.89, 65.35, 53.80, 10.79, 8.66, 23.48, 70.94, 32.49, ~
#> $ best_bid              <dbl> 77.11, 8.85, 36.85, 7.22, 54.15, 89.50, 92.00, 35.00, 102.21, 106.70, 81.71, 106.86, 10.63, 89.30, 65.16, 0.00, 10.76, 8.30, 23.06, 70.25, 32.30, 8~
#> $ best_ask              <dbl> 78.25, 8.90, 36.95, 7.28, 55.57, 91.25, 92.88, 35.40, 102.26, 108.49, 0.00, 107.64, 11.08, 90.50, 65.77, 53.80, 11.00, 8.50, 24.50, 71.09, 38.00, 1~
#> $ volume                <dbl> 4.770952e+04, 3.425857e+06, 1.001285e+05, 1.671910e+06, 2.237427e+07, 3.037244e+04, 7.305553e+05, 8.654818e+05, 1.053651e+09, 1.836637e+06, 4.15840~
#> $ traded_contracts      <int> 605, 384777, 2695, 230241, 410880, 338, 7923, 24791, 10235510, 17200, 506, 2480688, 389143, 966, 4926, 1, 10161, 8548, 6455, 29741, 1167, 6, 108, 6~
#> $ transactions_quantity <int> 8, 463, 64, 57, 40, 21, 712, 908, 71821, 65, 140, 39872, 568, 16, 1244, 1, 42, 105, 130, 1562, 10, 2, 2, 18, 31, 8, 6, 7, 16, 3392, 159, 51, 26, 9,~
#> $ distribution_id       <int> 100, 100, 100, 100, 100, 100, 107, 100, 106, 100, 100, 100, 100, 100, 127, 100, 100, 100, 100, 100, 100, 100, 100, 100, 102, 100, 100, 100, 100, 10~
```

FIIs data

``` r
glimpse(
  cotahist_fiis_get(ch)
)
#> Rows: 263
#> Columns: 13
#> $ refdate               <date> 2022-05-18, 2022-05-18, 2022-05-18, 2022-05-18, 2022-05-18, 2022-05-18, 2022-05-18, 2022-05-18, 2022-05-18, 2022-05-18, 2022-05-18, 2022-05-18, 20~
#> $ symbol                <chr> "BZLI11", "ABCP11", "AFHI11", "AFOF11", "AIEC11", "ALMI11", "ALZR11", "APTO11", "ARCT11", "ARRI11", "ATSA11", "BARI11", "BBFI11B", "BBFO11", "BBPO1~
#> $ open                  <dbl> 16.00, 72.75, 98.37, 89.10, 79.78, 950.00, 116.38, 10.19, 105.17, 94.28, 90.20, 99.79, 1967.00, 73.40, 81.50, 98.00, 64.89, 81.95, 106.70, 98.98, 9~
#> $ high                  <dbl> 16.90, 72.77, 99.31, 91.49, 79.78, 950.00, 116.40, 10.19, 105.17, 95.05, 90.20, 99.99, 1967.00, 73.40, 81.80, 98.00, 65.00, 82.99, 107.34, 98.98, 9~
#> $ low                   <dbl> 16.00, 72.26, 98.08, 88.51, 78.83, 938.60, 115.99, 9.80, 104.72, 94.00, 90.20, 98.23, 1927.01, 71.50, 81.50, 97.00, 64.40, 80.81, 106.55, 98.00, 9.~
#> $ close                 <dbl> 16.90, 72.76, 99.01, 88.95, 79.64, 950.00, 116.35, 9.99, 105.14, 94.03, 90.20, 99.00, 1939.95, 71.50, 81.76, 97.67, 64.91, 81.13, 107.00, 98.00, 9.~
#> $ average               <dbl> 16.67, 72.67, 98.49, 89.55, 79.39, 947.15, 116.25, 9.92, 105.01, 94.31, 90.20, 99.21, 1941.05, 72.49, 81.67, 97.68, 64.81, 81.59, 106.79, 98.65, 9.~
#> $ best_bid              <dbl> 16.90, 72.68, 98.69, 88.95, 79.60, 938.60, 116.34, 9.99, 105.13, 94.06, 88.01, 98.98, 1937.77, 71.23, 81.51, 97.31, 64.91, 81.13, 107.00, 85.01, 9.~
#> $ best_ask              <dbl> 17.17, 72.76, 99.01, 89.00, 79.64, 954.00, 116.35, 10.11, 105.14, 94.46, 89.12, 99.00, 1939.95, 71.50, 81.76, 97.67, 64.92, 81.22, 107.25, 98.00, 9~
#> $ volume                <dbl> 66.70, 47457.74, 763930.66, 245015.64, 411115.49, 7577.20, 771576.07, 14696.45, 2275005.35, 258529.97, 90.20, 1249031.26, 296981.79, 146510.85, 100~
#> $ traded_contracts      <int> 4, 653, 7756, 2736, 5178, 8, 6637, 1481, 21664, 2741, 1, 12589, 153, 2021, 12276, 580, 29721, 8715, 8294, 3, 9484, 3, 155, 13163, 56974, 56, 1434, ~
#> $ transactions_quantity <int> 2, 113, 882, 274, 702, 8, 1034, 116, 2654, 200, 1, 1667, 56, 122, 803, 64, 5372, 1349, 806, 2, 495, 3, 14, 1446, 2417, 7, 23, 55, 1325, 13, 6146, 2~
#> $ distribution_id       <int> 100, 314, 114, 114, 120, 250, 154, 105, 127, 131, 136, 137, 302, 116, 214, 228, 252, 185, 190, 129, 106, 123, 115, 120, 116, 102, 225, 216, 211, 11~
```

BDRs data

``` r
glimpse(
  cotahist_bdrs_get(ch)
)
#> Rows: 504
#> Columns: 13
#> $ refdate               <date> 2022-05-18, 2022-05-18, 2022-05-18, 2022-05-18, 2022-05-18, 2022-05-18, 2022-05-18, 2022-05-18, 2022-05-18, 2022-05-18, 2022-05-18, 2022-05-18, 20~
#> $ symbol                <chr> "A1AP34", "A1BB34", "A1CR34", "A1DI34", "A1DM34", "A1EE34", "A1EN34", "A1EP34", "A1KA34", "A1LG34", "A1LL34", "A1LN34", "A1MB34", "A1MD34", "A1MP34~
#> $ open                  <dbl> 60.47, 36.09, 65.42, 409.20, 428.56, 232.99, 299.40, 250.50, 40.29, 338.30, 61.75, 32.09, 381.37, 499.99, 322.60, 571.52, 50.21, 126.30, 200.97, 29~
#> $ high                  <dbl> 60.47, 36.09, 65.52, 410.80, 428.56, 233.54, 301.38, 252.50, 40.29, 338.30, 61.75, 32.09, 381.37, 515.00, 322.60, 581.09, 50.21, 126.30, 200.97, 29~
#> $ low                   <dbl> 60.47, 36.09, 63.63, 399.59, 426.34, 231.14, 295.49, 249.00, 40.11, 338.30, 60.90, 32.09, 381.37, 478.42, 322.60, 554.38, 50.21, 126.30, 198.24, 29~
#> $ close                 <dbl> 60.47, 36.09, 63.63, 400.40, 426.34, 231.42, 295.49, 250.49, 40.11, 338.30, 60.90, 32.09, 381.37, 479.57, 322.60, 554.40, 50.21, 126.30, 199.92, 29~
#> $ average               <dbl> 60.47, 36.09, 64.47, 404.83, 427.46, 232.21, 298.17, 251.23, 40.20, 338.30, 61.20, 32.09, 381.37, 483.72, 322.60, 561.21, 50.21, 126.30, 199.53, 29~
#> $ best_bid              <dbl> 0.00, 0.00, 54.00, 0.00, 400.00, 0.00, 0.00, 0.00, 34.75, 312.00, 60.29, 0.00, 0.00, 449.99, 0.00, 534.37, 0.00, 0.00, 0.00, 275.80, 195.02, 28.50,~
#> $ best_ask              <dbl> 0.00, 38.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 925.00, 64.01, 42.48, 0.00, 479.56, 0.00, 0.00, 52.08, 200.00, 0.00, 0.00, 250.00, 49.05, 0.~
#> $ volume                <dbl> 60.47, 72.18, 20762.45, 42507.94, 255198.22, 16255.32, 16399.72, 55523.72, 160.80, 4736.20, 2080.80, 641.80, 381.37, 920537.51, 6452.00, 175097.52,~
#> $ traded_contracts      <int> 1, 2, 322, 105, 597, 70, 55, 221, 4, 14, 34, 20, 1, 1903, 20, 312, 1, 34, 6, 578, 29, 15, 58, 86, 5, 306, 560, 13723, 112, 1, 1, 5, 673, 369974, 12~
#> $ transactions_quantity <int> 1, 1, 206, 101, 9, 70, 55, 70, 2, 2, 4, 1, 1, 189, 1, 104, 1, 1, 6, 151, 5, 1, 58, 4, 1, 224, 217, 28, 1, 1, 1, 2, 6, 3550, 105, 132, 3, 101, 206, ~
#> $ distribution_id       <int> 110, 102, 106, 109, 110, 109, 110, 110, 101, 100, 111, 100, 110, 100, 110, 109, 103, 101, 110, 109, 109, 100, 109, 103, 100, 109, 103, 100, 101, 10~
```

Equity options

``` r
glimpse(
  cotahist_equity_options_get(ch)
)
#> Rows: 6,711
#> Columns: 14
#> $ refdate               <date> 2022-05-18, 2022-05-18, 2022-05-18, 2022-05-18, 2022-05-18, 2022-05-18, 2022-05-18, 2022-05-18, 2022-05-18, 2022-05-18, 2022-05-18, 2022-05-18, 20~
#> $ symbol                <chr> "ABCBE175", "ABCBQ160", "ABEVB15", "ABEVD30", "ABEVE121", "ABEVE125", "ABEVE127", "ABEVE130", "ABEVE132", "ABEVE135", "ABEVE137", "ABEVE140", "ABEV~
#> $ type                  <fct> Call, Put, Call, Call, Call, Call, Call, Call, Call, Call, Call, Call, Call, Call, Call, Call, Call, Call, Call, Call, Call, Call, Call, Call, Call~
#> $ strike                <dbl> 17.23, 15.73, 14.47, 29.47, 11.04, 12.54, 12.79, 13.04, 13.29, 13.54, 13.79, 14.04, 14.29, 14.54, 14.79, 15.04, 15.29, 15.54, 15.79, 16.04, 16.29, ~
#> $ maturity_date         <date> 2022-05-20, 2022-05-20, 2023-02-17, 2023-04-20, 2022-05-20, 2022-05-20, 2022-05-20, 2022-05-20, 2022-05-20, 2022-05-20, 2022-05-20, 2022-05-20, 20~
#> $ open                  <dbl> 0.01, 0.14, 2.34, 0.01, 3.19, 2.20, 1.85, 1.52, 1.47, 1.08, 0.83, 0.77, 0.43, 0.40, 0.13, 0.06, 0.02, 0.01, 0.01, 0.01, 0.01, 0.01, 0.01, 0.01, 0.0~
#> $ high                  <dbl> 0.01, 0.14, 2.34, 0.01, 3.20, 2.20, 1.85, 1.65, 1.47, 1.15, 0.83, 0.77, 0.43, 0.43, 0.15, 0.06, 0.02, 0.02, 0.01, 0.01, 0.01, 0.01, 0.01, 0.01, 0.0~
#> $ low                   <dbl> 0.01, 0.14, 2.34, 0.01, 3.19, 2.20, 1.48, 1.25, 1.00, 0.73, 0.46, 0.27, 0.14, 0.05, 0.01, 0.01, 0.01, 0.01, 0.01, 0.01, 0.01, 0.01, 0.01, 0.01, 0.0~
#> $ close                 <dbl> 0.01, 0.14, 2.34, 0.01, 3.20, 2.20, 1.51, 1.25, 1.00, 0.73, 0.46, 0.28, 0.15, 0.06, 0.02, 0.01, 0.01, 0.01, 0.01, 0.01, 0.01, 0.01, 0.01, 0.01, 0.0~
#> $ average               <dbl> 0.01, 0.14, 2.34, 0.01, 3.19, 2.20, 1.51, 1.46, 1.11, 0.95, 0.68, 0.51, 0.24, 0.14, 0.04, 0.02, 0.01, 0.01, 0.01, 0.01, 0.01, 0.01, 0.01, 0.01, 0.0~
#> $ volume                <dbl> 1, 14, 234, 3, 959, 1100, 83275, 139792, 145053, 213675, 24886, 38081, 102317, 134668, 42983, 20926, 7175, 370, 227, 574, 11, 42, 5, 1000, 52, 2240~
#> $ traded_contracts      <int> 100, 100, 100, 300, 300, 500, 55000, 95300, 130400, 223700, 36300, 74100, 413700, 935300, 1006500, 730300, 565800, 36900, 22700, 57400, 1100, 4200,~
#> $ transactions_quantity <int> 1, 1, 1, 1, 2, 1, 11, 23, 10, 265, 19, 69, 79, 194, 116, 238, 77, 35, 110, 15, 11, 42, 3, 13, 52, 1, 4, 16, 1, 25, 12, 159, 29, 300, 65, 202, 227, ~
#> $ distribution_id       <int> 139, 139, 124, 124, 122, 125, 125, 125, 125, 125, 125, 125, 125, 125, 125, 125, 125, 125, 125, 125, 125, 125, 125, 125, 125, 125, 125, 125, 124, 12~
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
#> Rows: 92
#> Columns: 13
#> $ refdate               <date> 2022-05-18, 2022-05-18, 2022-05-18, 2022-05-18, 2022-05-18, 2022-05-18, 2022-05-18, 2022-05-18, 2022-05-18, 2022-05-18, 2022-05-18, 2022-05-18, 20~
#> $ symbol                <chr> "ABEV3", "ALPA4", "AMER3", "ASAI3", "AZUL4", "B3SA3", "BBAS3", "BBDC3", "BBDC4", "BBSE3", "BEEF3", "BIDI11", "BPAC11", "BPAN4", "BRAP4", "BRFS3", "~
#> $ open                  <dbl> 14.72, 21.29, 22.94, 15.81, 21.79, 11.72, 36.40, 16.26, 19.83, 25.79, 12.46, 15.37, 24.83, 8.59, 26.94, 14.23, 44.09, 9.05, 2.01, 13.10, 3.35, 11.0~
#> $ high                  <dbl> 14.82, 21.63, 23.50, 15.83, 22.20, 11.82, 36.88, 16.37, 19.95, 25.88, 12.46, 15.37, 24.83, 8.71, 27.06, 14.64, 44.09, 9.09, 2.08, 13.19, 3.46, 11.2~
#> $ low                   <dbl> 14.18, 20.74, 22.56, 15.38, 21.06, 11.47, 35.73, 15.93, 19.47, 25.27, 11.94, 14.24, 23.61, 8.46, 26.12, 13.58, 42.00, 8.63, 1.94, 12.81, 3.31, 10.9~
#> $ close                 <dbl> 14.22, 20.94, 22.95, 15.40, 21.23, 11.55, 35.91, 16.01, 19.56, 25.41, 12.19, 14.32, 23.87, 8.50, 26.22, 13.58, 42.59, 8.69, 1.95, 13.02, 3.38, 11.0~
#> $ average               <dbl> 14.42, 21.04, 22.97, 15.52, 21.61, 11.61, 36.20, 16.06, 19.60, 25.54, 12.19, 14.55, 23.94, 8.52, 26.42, 14.02, 42.81, 8.75, 2.00, 12.98, 3.38, 11.1~
#> $ best_bid              <dbl> 14.22, 20.91, 22.92, 15.39, 21.23, 11.52, 35.91, 16.00, 19.56, 25.40, 12.19, 14.31, 23.85, 8.50, 26.20, 13.58, 42.51, 8.69, 1.94, 12.97, 3.38, 11.0~
#> $ best_ask              <dbl> 14.23, 20.95, 22.95, 15.40, 21.25, 11.56, 35.92, 16.01, 19.57, 25.41, 12.20, 14.32, 23.87, 8.51, 26.22, 13.65, 42.60, 8.71, 1.95, 13.02, 3.39, 11.0~
#> $ volume                <dbl> 425796280, 80283647, 236561952, 106264437, 151706028, 531192301, 452153919, 184075368, 893663060, 111365341, 106738532, 280265348, 348285985, 61860~
#> $ traded_contracts      <int> 29516600, 3814800, 10296400, 6842800, 7019100, 45745200, 12487200, 11457500, 45581800, 4359900, 8754000, 19251700, 14547800, 7257400, 3577300, 1184~
#> $ transactions_quantity <int> 50558, 19031, 21590, 13942, 16706, 48810, 34065, 19677, 47357, 15329, 14078, 33793, 28525, 11778, 12391, 22330, 11918, 44802, 11339, 27195, 17874, ~
#> $ distribution_id       <int> 125, 231, 101, 104, 101, 121, 305, 741, 741, 120, 113, 110, 112, 113, 143, 120, 120, 117, 102, 141, 149, 231, 104, 102, 134, 143, 111, 123, 256, 11~
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
#> [1] "C:/Users/wilso/AppData/Local/Temp/RtmpKc4zmX/rb3-cache/FPR-7a2422cc97221426a3b2bd4419215481/FP220510/FatoresPrimitivosRisco.txt"
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
