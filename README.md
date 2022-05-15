
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
#> Skipping download - using cached version
#> Skipping download - using cached version
#> Skipping download - using cached version
#> Skipping download - using cached version

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
#> $ refdate          <date> 2022-04-01, 2022-04-01, 2022-04-01, 2022-04-01, 2022-04-01, 2022-04-01, 2022-04-01, 2022-04-01, 2022-04-01, 2022-04-01, 2022-04-0~
#> $ commodity        <chr> "DI1", "DI1", "DI1", "DI1", "DI1", "DI1", "DI1", "DI1", "DI1", "DI1", "DI1", "DI1", "DI1", "DI1", "DI1", "DI1", "DI1", "DI1", "DI1~
#> $ maturity_code    <chr> "J22", "K22", "M22", "N22", "Q22", "U22", "V22", "X22", "Z22", "F23", "G23", "H23", "J23", "N23", "V23", "F24", "J24", "N24", "V24~
#> $ symbol           <chr> "DI1J22", "DI1K22", "DI1M22", "DI1N22", "DI1Q22", "DI1U22", "DI1V22", "DI1X22", "DI1Z22", "DI1F23", "DI1G23", "DI1H23", "DI1J23", ~
#> $ price_previous   <dbl> 99999.99, 99172.50, 98159.27, 97181.87, 96199.14, 95137.64, 94174.49, 93265.23, 92365.48, 91404.64, 90434.90, 89662.14, 88719.94, ~
#> $ price            <dbl> 100000.00, 99172.31, 98160.23, 97185.43, 96210.42, 95159.25, 94209.42, 93314.08, 92422.80, 91472.04, 90513.73, 89751.01, 88821.78,~
#> $ change           <dbl> 0.01, -0.19, 0.96, 3.56, 11.28, 21.61, 34.93, 48.85, 57.32, 67.40, 78.83, 88.87, 101.84, 150.68, 175.83, 275.55, 370.18, 423.00, 4~
#> $ settlement_value <dbl> 0.01, 0.19, 0.96, 3.56, 11.28, 21.61, 34.93, 48.85, 57.32, 67.40, 78.83, 88.87, 101.84, 150.68, 175.83, 275.55, 370.18, 423.00, 45~
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
#> Skipping download - using cached version

glimpse(
  cotahist_equity_get(ch)
)
#> Rows: 382
#> Columns: 13
#> $ refdate               <date> 2022-05-13, 2022-05-13, 2022-05-13, 2022-05-13, 2022-05-13, 2022-05-13, 2022-05-13, 2022-05-13, 2022-05-13, 2022-05-13, 2022~
#> $ symbol                <chr> "AALR3", "ABCB4", "ABEV3", "AERI3", "AESB3", "AFLT3", "AGRO3", "AGXY3", "ALLD3", "ALPA3", "ALPA4", "ALPK3", "ALSO3", "ALUP3",~
#> $ open                  <dbl> 19.81, 16.16, 14.55, 3.83, 10.79, 9.06, 31.60, 9.23, 13.35, 19.52, 22.28, 3.79, 19.65, 8.81, 8.66, 2.17, 28.52, 22.93, 5.02, ~
#> $ high                  <dbl> 19.89, 16.55, 14.67, 3.93, 10.81, 9.50, 32.40, 9.78, 13.35, 19.52, 22.46, 3.80, 19.90, 8.90, 8.94, 2.28, 29.98, 24.62, 5.47, ~
#> $ low                   <dbl> 19.43, 16.06, 14.45, 3.72, 10.64, 9.06, 31.54, 9.21, 12.30, 18.83, 21.70, 3.65, 19.48, 8.52, 8.60, 2.17, 28.52, 22.74, 5.01, ~
#> $ close                 <dbl> 19.75, 16.54, 14.54, 3.75, 10.64, 9.35, 32.06, 9.33, 12.52, 19.25, 21.80, 3.80, 19.69, 8.70, 8.75, 2.23, 29.75, 23.05, 5.38, ~
#> $ average               <dbl> 19.66, 16.38, 14.55, 3.80, 10.69, 9.38, 31.99, 9.50, 12.73, 19.12, 22.04, 3.75, 19.66, 8.72, 8.76, 2.23, 29.51, 23.52, 5.35, ~
#> $ best_bid              <dbl> 19.75, 16.45, 14.54, 3.74, 10.64, 9.35, 32.06, 9.33, 12.52, 19.05, 21.80, 3.77, 19.68, 8.70, 8.75, 2.22, 29.74, 23.04, 5.37, ~
#> $ best_ask              <dbl> 19.80, 16.54, 14.58, 3.75, 10.65, 9.47, 32.08, 9.70, 12.68, 19.50, 21.91, 3.80, 19.69, 8.72, 8.82, 2.23, 29.75, 23.05, 5.38, ~
#> $ volume                <dbl> 13692159, 10155477, 194865062, 13607948, 11877006, 16893, 17358541, 855837, 2366674, 68854, 115741119, 68319, 19234179, 13697~
#> $ traded_contracts      <int> 696300, 619700, 13385100, 3571700, 1110400, 1800, 542500, 90000, 185800, 3600, 5251300, 18200, 978000, 15700, 13200, 5237300,~
#> $ transactions_quantity <int> 2873, 4115, 29016, 7499, 4533, 16, 3363, 492, 633, 19, 23648, 85, 3961, 115, 91, 5106, 7014, 27959, 6067, 157, 3744, 6423, 13~
#> $ distribution_id       <int> 102, 140, 125, 101, 102, 119, 112, 101, 103, 231, 231, 101, 102, 113, 113, 113, 102, 101, 107, 105, 103, 142, 104, 105, 101, ~
```

Funds data

``` r
glimpse(
  cotahist_funds_get(ch)
)
#> Rows: 359
#> Columns: 13
#> $ refdate               <date> 2022-05-13, 2022-05-13, 2022-05-13, 2022-05-13, 2022-05-13, 2022-05-13, 2022-05-13, 2022-05-13, 2022-05-13, 2022-05-13, 2022~
#> $ symbol                <chr> "ABCP11", "AFHI11", "AFOF11", "AIEC11", "ALMI11", "ALZR11", "APTO11", "ARCT11", "ARRI11", "ATSA11", "BARI11", "BBFI11B", "BBF~
#> $ open                  <dbl> 72.48, 99.52, 89.00, 78.55, 950.00, 115.19, 10.22, 106.05, 94.99, 88.10, 99.61, 1975.48, 71.50, 81.00, 95.99, 63.85, 81.01, 1~
#> $ high                  <dbl> 72.78, 100.80, 89.49, 78.99, 951.00, 115.98, 10.50, 106.39, 95.93, 89.00, 100.00, 1999.98, 72.46, 81.67, 100.01, 65.80, 81.83~
#> $ low                   <dbl> 72.16, 99.50, 88.52, 78.55, 930.00, 115.19, 10.22, 105.95, 94.71, 88.10, 99.61, 1900.02, 70.99, 80.65, 95.99, 63.85, 80.73, 1~
#> $ close                 <dbl> 72.24, 100.65, 89.00, 78.93, 950.00, 115.70, 10.31, 106.00, 94.78, 89.00, 99.99, 1958.94, 72.39, 80.90, 97.97, 65.35, 81.35, ~
#> $ average               <dbl> 72.38, 100.13, 89.02, 78.90, 947.15, 115.63, 10.48, 106.15, 95.10, 88.60, 99.93, 1949.91, 71.40, 81.12, 97.87, 65.18, 81.43, ~
#> $ best_bid              <dbl> 72.24, 100.60, 88.99, 78.91, 930.50, 115.69, 10.38, 106.00, 94.78, 88.07, 99.98, 1935.00, 71.51, 80.84, 97.96, 65.35, 81.25, ~
#> $ best_ask              <dbl> 72.53, 100.65, 89.00, 78.99, 951.00, 115.70, 10.50, 106.10, 94.82, 90.53, 99.99, 1958.95, 72.39, 80.90, 97.97, 65.78, 81.35, ~
#> $ volume                <dbl> 67023.89, 1305373.39, 130064.77, 57283.07, 79561.11, 995972.30, 33367.53, 3268860.08, 234137.10, 3189.60, 604620.93, 300286.4~
#> $ traded_contracts      <int> 926, 13036, 1461, 726, 84, 8613, 3181, 30794, 2462, 36, 6050, 154, 7765, 15026, 1075, 50039, 2497, 10446, 14900, 50, 123, 954~
#> $ transactions_quantity <int> 231, 542, 79, 129, 77, 1039, 99, 3989, 221, 3, 721, 86, 191, 1316, 106, 7695, 306, 1060, 803, 1, 15, 1564, 2694, 1, 3, 94, 22~
#> $ distribution_id       <int> 314, 113, 113, 120, 250, 154, 105, 126, 131, 136, 137, 302, 116, 214, 228, 252, 185, 190, 106, 123, 114, 120, 116, 102, 225, ~
```

BDRs data

``` r
glimpse(
  cotahist_bdrs_get(ch)
)
#> Rows: 509
#> Columns: 13
#> $ refdate               <date> 2022-05-13, 2022-05-13, 2022-05-13, 2022-05-13, 2022-05-13, 2022-05-13, 2022-05-13, 2022-05-13, 2022-05-13, 2022-05-13, 2022~
#> $ symbol                <chr> "A1AP34", "A1BB34", "A1CR34", "A1DM34", "A1EE34", "A1EG34", "A1EN34", "A1EP34", "A1IV34", "A1KA34", "A1LB34", "A1LG34", "A1LK~
#> $ open                  <dbl> 67.80, 36.71, 65.10, 443.76, 234.24, 26.28, 294.30, 252.43, 29.28, 41.40, 1154.00, 344.19, 230.00, 65.00, 32.22, 460.00, 330.~
#> $ high                  <dbl> 67.80, 36.71, 65.10, 443.76, 235.20, 26.28, 295.80, 252.43, 29.28, 41.41, 1154.00, 349.14, 230.00, 66.11, 32.22, 488.25, 331.~
#> $ low                   <dbl> 66.79, 36.23, 64.56, 430.00, 233.77, 26.10, 293.69, 249.52, 29.28, 41.37, 1154.00, 344.19, 230.00, 64.74, 32.19, 454.51, 330.~
#> $ close                 <dbl> 66.79, 36.25, 64.62, 430.00, 235.00, 26.10, 295.50, 250.00, 29.28, 41.37, 1154.00, 349.14, 230.00, 64.74, 32.19, 477.90, 331.~
#> $ average               <dbl> 67.43, 36.31, 64.68, 434.09, 234.62, 26.22, 294.66, 250.61, 29.28, 41.39, 1154.00, 345.01, 230.00, 65.53, 32.20, 475.33, 331.~
#> $ best_bid              <dbl> 0.00, 0.00, 54.00, 0.00, 0.00, 0.00, 0.00, 0.00, 29.31, 34.75, 0.00, 329.01, 0.00, 61.75, 0.00, 435.00, 0.00, 529.64, 0.00, 0~
#> $ best_ask              <dbl> 0.00, 38.00, 0.00, 0.00, 0.00, 27.43, 0.00, 0.00, 31.00, 0.00, 1300.00, 925.00, 0.00, 0.00, 42.48, 480.00, 0.00, 0.00, 0.00, ~
#> $ volume                <dbl> 3709.04, 435.83, 14619.84, 8247.78, 14781.36, 183.54, 14438.53, 16039.06, 58.56, 124.18, 1154.00, 2070.09, 1610.00, 116261.00~
#> $ traded_contracts      <int> 55, 12, 226, 19, 63, 7, 49, 64, 2, 3, 1, 6, 7, 1774, 3, 6162, 20, 812, 5, 44, 11, 4, 50, 1619, 9, 1, 97, 1721, 11580, 144, 4,~
#> $ transactions_quantity <int> 6, 12, 38, 5, 36, 5, 46, 45, 1, 3, 1, 3, 1, 15, 3, 151, 5, 3, 5, 1, 2, 4, 43, 19, 3, 1, 3, 115, 38, 1, 1, 23, 2639, 5, 13, 15~
#> $ distribution_id       <int> 110, 102, 106, 109, 109, 102, 110, 110, 106, 101, 109, 100, 101, 111, 100, 100, 110, 109, 103, 101, 100, 102, 109, 103, 100, ~
```

Equity options

``` r
glimpse(
  cotahist_equity_options_get(ch)
)
#> Rows: 6,059
#> Columns: 14
#> $ refdate               <date> 2022-05-13, 2022-05-13, 2022-05-13, 2022-05-13, 2022-05-13, 2022-05-13, 2022-05-13, 2022-05-13, 2022-05-13, 2022-05-13, 2022~
#> $ symbol                <chr> "ABEVR155", "ABEVR180", "ABEVX20", "ABEVR154", "ABEVQ127", "ABEVS162", "ALPAS230", "ALSOS210", "AMARF350", "AMARB300", "AMARE~
#> $ type                  <fct> Put, Put, Put, Put, Put, Put, Put, Put, Call, Call, Call, Put, Call, Put, Call, Put, Call, Call, Call, Call, Call, Call, Call~
#> $ strike                <dbl> 14.97, 17.47, 19.47, 15.47, 12.79, 16.29, 23.00, 20.62, 3.50, 3.00, 2.00, 3.50, 31.70, 31.70, 25.31, 62.81, 32.31, 32.56, 37.~
#> $ maturity_date         <date> 2022-06-17, 2022-06-17, 2023-12-15, 2022-06-17, 2022-05-20, 2022-07-15, 2022-07-15, 2022-07-15, 2022-06-17, 2024-02-16, 2022~
#> $ open                  <dbl> 0.69, 2.72, 3.30, 0.97, 0.01, 1.62, 1.80, 1.53, 0.03, 0.60, 0.28, 1.49, 0.68, 2.55, 1.55, 35.50, 0.04, 0.04, 0.01, 0.02, 0.02~
#> $ high                  <dbl> 0.71, 2.81, 3.30, 1.03, 0.02, 1.62, 2.20, 1.53, 0.03, 0.60, 0.28, 1.49, 0.68, 2.55, 1.73, 35.50, 0.04, 0.04, 0.01, 0.02, 0.04~
#> $ low                   <dbl> 0.59, 2.72, 3.30, 0.91, 0.01, 1.62, 1.80, 1.53, 0.03, 0.60, 0.26, 1.28, 0.68, 2.55, 1.14, 35.50, 0.04, 0.04, 0.01, 0.02, 0.02~
#> $ close                 <dbl> 0.60, 2.81, 3.30, 0.92, 0.01, 1.62, 2.10, 1.53, 0.03, 0.60, 0.26, 1.28, 0.68, 2.55, 1.14, 35.50, 0.04, 0.04, 0.01, 0.02, 0.04~
#> $ average               <dbl> 0.65, 2.74, 3.30, 0.96, 0.01, 1.62, 2.06, 1.53, 0.03, 0.60, 0.26, 1.39, 0.68, 2.55, 1.56, 35.50, 0.04, 0.04, 0.01, 0.02, 0.03~
#> $ volume                <dbl> 414290, 541506, 66000, 201996, 1057, 81000, 825, 2295, 6, 60, 396, 2646, 68, 255, 6409, 287550, 4, 28, 4, 800, 1200, 300, 40,~
#> $ traded_contracts      <int> 637000, 197000, 20000, 209700, 105400, 50000, 400, 1500, 200, 100, 1500, 1900, 100, 100, 4100, 8100, 100, 700, 400, 40000, 40~
#> $ transactions_quantity <int> 99, 6, 1, 172, 13, 1, 4, 1, 1, 1, 2, 8, 1, 1, 7, 1, 1, 1, 2, 3, 3, 1, 1, 5, 7, 9, 2, 1, 1, 4, 2, 1, 28, 4, 8, 10, 8, 8, 6, 4,~
#> $ distribution_id       <int> 124, 124, 124, 125, 125, 125, 231, 101, 113, 113, 113, 113, 101, 101, 100, 100, 101, 101, 101, 101, 101, 101, 101, 101, 101, ~
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
#> [1] "C:/Users/wilso/AppData/Local/Temp/RtmpQ3Pkd7/rb3-cache/FPR-7a2422cc97221426a3b2bd4419215481/FP220510/FatoresPrimitivosRisco.txt"
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
#>    tipo_registro id_fpr nome_fpr formato_variacao id_grupo_fpr id_camara_indicador id_instrumento_i~ origem_instrume~  base base_interpolac~ criterio_capita~
#>            <int>  <int> <chr>    <fct>                   <dbl> <chr>                           <dbl>            <int> <int>            <int>            <int>
#>  1             2   1422 VLRAPT4  Basis Points                1 BVMF                     200000008810                8     0                0                0
#>  2             2   1423 VLPETR3  Basis Points                1 BVMF                     200000008803                8     0                0                0
#>  3             2   1424 VLSEER3  Basis Points                1 BVMF                     200000008818                8     0                0                0
#>  4             2   1426 VLJBSS3  Basis Points                1 BVMF                     200000008780                8     0                0                0
#>  5             2   1427 VLKLBN11 Basis Points                1 BVMF                     200000008781                8     0                0                0
#>  6             2   1428 VLITUB3  Basis Points                1 BVMF                     200000463163                8     0                0                0
#>  7             2   1429 VLITSA4  Basis Points                1 BVMF                     200000008777                8     0                0                0
#>  8             2   1430 VLHYPE3  Basis Points                1 BVMF                     200000008773                8     0                0                0
#>  9             2   1431 VLGRND3  Basis Points                1 BVMF                     200000008770                8     0                0                0
#> 10             2   1433 VLUGPA3  Basis Points                1 BVMF                     200000008830                8     0                0                0
#> # ... with 3,194 more rows
#> 
#> attr(,"class")
#> [1] "parts"
```

`read_marketdata` parses the downloaded file according to the metadata
configured in the template `FPR`.

Here it follows a list of available templates.

<img src="man/figures/rb3-templates.png" width="100%" />
