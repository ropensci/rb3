
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
[![Status at rOpenSci Software Peer
Review](https://badges.ropensci.org/534_status.svg)](https://github.com/ropensci/software-review/issues/534)
<!-- badges: end -->

[B3](https://www.b3.com.br) is the main financial exchange in Brazil,
offering support and access to trading systems for equity and fixed
income markets. In its website you can find a vast number of datasets
regarding prices and transactions for contracts available for trading at
these markets, including:

-   equities/stocks
-   futures
-   FII (Reits)
-   options
-   BDRs
-   historical yield curves (calculated from futures contracts)
-   B3 indexes composition

For example, you can find the current yield curve at this
[link](https://www.b3.com.br/pt_br/market-data-e-indices/servicos-de-dados/market-data/consultas/mercado-de-derivativos/precos-referenciais/taxas-referenciais-bm-fbovespa/).
Package **rb3** uses webscraping tools to download and read these
datasets from [B3](https://www.b3.com.br), making it easy to consume it
in R in a structured way.

The available datasets are highly valuable, going back as early as
2000’s, and can be used by industry practitioners or academics. None of
these datasets are available anywhere else, which makes rb3 an unique
package for data importation from the Brazilian financial exchange.

# Documentation

The documentation is available in its [pkgdown
page](https://wilsonfreitas.github.io/rb3/), where articles (vignettes)
with real applications can be found.

## Installation

Package rb3 is available in its stable form in CRAN and its development
version in Github. Please find the installation commands below:

``` r
# stable (CRAN)
install.packages("rb3")

# github (Development branch)
if (!require(devtools)) install.packages("devtools")
devtools::install_github("wilsonfreitas/rb3")
```

## Examples

### Yield curve

In this first example we’ll import and plot the historical yield curve
for Brazil using function `yc_get`.

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
#> $ refdate          <date> 2022-04-01, 2022-04-01, 2022-04-01, 2022-04-01, 2022~
#> $ commodity        <chr> "DI1", "DI1", "DI1", "DI1", "DI1", "DI1", "DI1", "DI1~
#> $ maturity_code    <chr> "J22", "K22", "M22", "N22", "Q22", "U22", "V22", "X22~
#> $ symbol           <chr> "DI1J22", "DI1K22", "DI1M22", "DI1N22", "DI1Q22", "DI~
#> $ price_previous   <dbl> 99999.99, 99172.50, 98159.27, 97181.87, 96199.14, 951~
#> $ price            <dbl> 100000.00, 99172.31, 98160.23, 97185.43, 96210.42, 95~
#> $ change           <dbl> 0.01, -0.19, 0.96, 3.56, 11.28, 21.61, 34.93, 48.85, ~
#> $ settlement_value <dbl> 0.01, 0.19, 0.96, 3.56, 11.28, 21.61, 34.93, 48.85, 5~
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
#> Rows: 391
#> Columns: 13
#> $ refdate               <date> 2022-09-23, 2022-09-23, 2022-09-23, 2022-09-23,~
#> $ symbol                <chr> "AALR3", "ABCB4", "ABEV3", "AERI3", "AESB3", "AF~
#> $ open                  <dbl> 21.02, 20.58, 15.40, 2.25, 9.64, 9.60, 30.96, 7.~
#> $ high                  <dbl> 21.32, 20.82, 15.48, 2.26, 9.74, 9.69, 31.20, 7.~
#> $ low                   <dbl> 21.02, 20.36, 15.17, 2.16, 9.58, 9.60, 30.35, 6.~
#> $ close                 <dbl> 21.15, 20.82, 15.37, 2.18, 9.64, 9.69, 30.56, 6.~
#> $ average               <dbl> 21.23, 20.58, 15.33, 2.19, 9.65, 9.64, 30.69, 6.~
#> $ best_bid              <dbl> 21.15, 20.75, 15.36, 2.18, 9.64, 9.50, 30.55, 6.~
#> $ best_ask              <dbl> 21.27, 20.82, 15.37, 2.19, 9.65, 9.74, 30.56, 7.~
#> $ volume                <dbl> 9702201, 13210268, 598903006, 9119526, 16974620,~
#> $ traded_contracts      <dbl> 457000, 641700, 39045900, 4150600, 1758500, 200,~
#> $ transactions_quantity <int> 1552, 3862, 34816, 3415, 4934, 2, 1877, 212, 182~
#> $ distribution_id       <int> 102, 141, 125, 101, 104, 119, 112, 101, 103, 231~
```

### Funds data

One can also download hedge fund data with `cotahist_etfs_get`.

``` r
glimpse(
  cotahist_etfs_get(ch)
)
#> Rows: 89
#> Columns: 13
#> $ refdate               <date> 2022-09-23, 2022-09-23, 2022-09-23, 2022-09-23,~
#> $ symbol                <chr> "5GTK11", "ACWI11", "AGRI11", "ALUG11", "ASIA11"~
#> $ open                  <dbl> 72.02, 8.53, 48.33, 34.09, 6.80, 58.40, 90.57, 1~
#> $ high                  <dbl> 72.30, 8.58, 48.96, 34.63, 6.86, 58.40, 90.58, 1~
#> $ low                   <dbl> 71.68, 8.50, 48.33, 34.01, 6.80, 57.01, 88.70, 1~
#> $ close                 <dbl> 72.30, 8.58, 48.60, 34.27, 6.86, 57.28, 89.13, 1~
#> $ average               <dbl> 72.09, 8.57, 48.64, 34.24, 6.85, 57.11, 89.08, 1~
#> $ best_bid              <dbl> 70.00, 8.55, 48.57, 34.06, 6.85, 57.28, 36.00, 1~
#> $ best_ask              <dbl> 72.30, 8.58, 48.60, 34.27, 7.37, 58.67, 91.20, 1~
#> $ volume                <dbl> 43620.12, 2070659.80, 3405.33, 119906.09, 38014.~
#> $ traded_contracts      <dbl> 605, 241405, 70, 3501, 5545, 830, 710, 1924, 1, ~
#> $ transactions_quantity <int> 11, 83, 8, 86, 18, 25, 51, 38, 1, 315, 2, 68057,~
#> $ distribution_id       <int> 100, 100, 100, 100, 100, 100, 100, 108, 100, 100~
```

### FIIs (Brazilian REITs) data

Download FII (Fundo de Investimento Imobiliário) data with
`cotahist_fiis_get`:

``` r
glimpse(
  cotahist_fiis_get(ch)
)
#> Rows: 266
#> Columns: 13
#> $ refdate               <date> 2022-09-23, 2022-09-23, 2022-09-23, 2022-09-23,~
#> $ symbol                <chr> "ABCP11", "AFHI11", "AIEC11", "ALZM11", "ALZR11"~
#> $ open                  <dbl> 75.51, 98.38, 80.32, 93.00, 117.54, 9.22, 101.00~
#> $ high                  <dbl> 76.20, 99.39, 81.30, 94.44, 118.07, 9.22, 101.50~
#> $ low                   <dbl> 75.25, 98.00, 79.60, 92.51, 115.06, 9.09, 100.45~
#> $ close                 <dbl> 75.90, 98.00, 79.97, 94.30, 117.16, 9.19, 100.80~
#> $ average               <dbl> 75.87, 98.50, 80.07, 93.76, 117.20, 9.13, 100.87~
#> $ best_bid              <dbl> 75.15, 97.90, 79.95, 92.85, 117.16, 9.09, 100.80~
#> $ best_ask              <dbl> 75.90, 98.00, 79.97, 94.30, 117.20, 9.18, 100.93~
#> $ volume                <dbl> 56530.30, 791180.59, 289308.60, 25971.95, 228449~
#> $ traded_contracts      <dbl> 745, 8032, 3613, 277, 19492, 3749, 10220, 25059,~
#> $ transactions_quantity <int> 382, 622, 769, 51, 2764, 394, 2101, 787, 1, 3, 8~
#> $ distribution_id       <int> 318, 119, 124, 101, 160, 109, 131, 136, 101, 137~
```

### BDRs data

Download BDR (Brazilian depositary receipts) with `cotahist_bdrs_get`:

``` r
glimpse(
  cotahist_bdrs_get(ch)
)
#> Rows: 474
#> Columns: 13
#> $ refdate               <date> 2022-09-23, 2022-09-23, 2022-09-23, 2022-09-23,~
#> $ symbol                <chr> "A1BB34", "A1CR34", "A1EG34", "A1EP34", "A1IV34"~
#> $ open                  <dbl> 33.55, 58.11, 22.35, 255.84, 41.30, 35.21, 1359.~
#> $ high                  <dbl> 33.79, 58.11, 22.35, 257.40, 41.30, 35.21, 1367.~
#> $ low                   <dbl> 33.55, 57.72, 22.05, 254.22, 41.30, 35.16, 1359.~
#> $ close                 <dbl> 33.79, 57.72, 22.05, 257.40, 41.30, 35.16, 1361.~
#> $ average               <dbl> 33.55, 57.79, 22.08, 255.63, 41.30, 35.18, 1361.~
#> $ best_bid              <dbl> 33.30, 0.00, 21.85, 0.00, 24.33, 34.75, 1361.78,~
#> $ best_ask              <dbl> 39.00, 0.00, 24.40, 0.00, 0.00, 0.00, 0.00, 44.0~
#> $ volume                <dbl> 34627.83, 635.70, 6692.05, 153383.48, 41.30, 70.~
#> $ traded_contracts      <dbl> 1032, 11, 303, 600, 1, 2, 19, 1314, 9257, 28, 46~
#> $ transactions_quantity <int> 4, 2, 3, 323, 1, 2, 6, 26, 61, 1, 27, 1, 9, 25, ~
#> $ distribution_id       <int> 102, 108, 104, 111, 107, 101, 111, 112, 100, 111~
```

### Equity options

Download equity options contracts with `cotahist_option_get`:

``` r
glimpse(
  cotahist_equity_options_get(ch)
)
#> Rows: 5,595
#> Columns: 14
#> $ refdate               <date> 2022-09-23, 2022-09-23, 2022-09-23, 2022-09-23,~
#> $ symbol                <chr> "ABEVL160", "ABEVB15", "ABEVD220", "ABEVD100", "~
#> $ type                  <fct> Call, Call, Call, Call, Call, Put, Call, Call, C~
#> $ strike                <dbl> 15.39, 14.47, 21.47, 9.47, 15.64, 14.89, 17.00, ~
#> $ maturity_date         <date> 2022-12-16, 2023-02-17, 2023-04-20, 2023-04-20,~
#> $ open                  <dbl> 0.95, 2.00, 0.18, 6.58, 0.85, 0.42, 0.06, 0.23, ~
#> $ high                  <dbl> 0.95, 2.00, 0.18, 6.58, 0.87, 0.46, 0.06, 0.23, ~
#> $ low                   <dbl> 0.95, 2.00, 0.13, 6.50, 0.76, 0.40, 0.04, 0.19, ~
#> $ close                 <dbl> 0.95, 2.00, 0.13, 6.50, 0.87, 0.42, 0.05, 0.22, ~
#> $ average               <dbl> 0.95, 2.00, 0.13, 6.52, 0.78, 0.44, 0.05, 0.20, ~
#> $ volume                <dbl> 95, 200, 203, 2608, 4483, 5050, 18381, 96844, 62~
#> $ traded_contracts      <dbl> 100, 100, 1500, 400, 5700, 11300, 366100, 469200~
#> $ transactions_quantity <int> 1, 1, 6, 2, 6, 7, 79, 27, 10, 17, 7, 2, 7, 64, 1~
#> $ distribution_id       <int> 123, 124, 124, 124, 124, 124, 125, 125, 125, 125~
```

### Indexes composition

The list with available B3 indexes can be obtained with `indexes_get`.

``` r
indexes_get()
#>  [1] "AGFS" "BDRX" "GPTW" "IBOV" "IBRA" "IBXL" "IBXX" "ICO2" "ICON" "IDIV"
#> [11] "IEEX" "IFIL" "IFIX" "IFNC" "IGCT" "IGCX" "IGNM" "IMAT" "IMOB" "INDX"
#> [21] "ISEE" "ITAG" "IVBX" "MLCX" "SMLL" "UTIL"
```

And the composition of a specific index with `index_comp_get`.

``` r
(ibov_comp <- index_comp_get("IBOV"))
#>  [1] "ABEV3"  "ALPA4"  "AMER3"  "ASAI3"  "AZUL4"  "B3SA3"  "BBAS3"  "BBDC3" 
#>  [9] "BBDC4"  "BBSE3"  "BEEF3"  "BIDI11" "BPAC11" "BPAN4"  "BRAP4"  "BRFS3" 
#> [17] "BRKM5"  "BRML3"  "CASH3"  "CCRO3"  "CIEL3"  "CMIG4"  "CMIN3"  "COGN3" 
#> [25] "CPFE3"  "CPLE6"  "CRFB3"  "CSAN3"  "CSNA3"  "CVCB3"  "CYRE3"  "DXCO3" 
#> [33] "ECOR3"  "EGIE3"  "ELET3"  "ELET6"  "EMBR3"  "ENBR3"  "ENEV3"  "ENGI11"
#> [41] "EQTL3"  "EZTC3"  "FLRY3"  "GGBR4"  "GOAU4"  "GOLL4"  "HAPV3"  "HYPE3" 
#> [49] "IGTI11" "IRBR3"  "ITSA4"  "ITUB4"  "JBSS3"  "JHSF3"  "KLBN11" "LCAM3" 
#> [57] "LREN3"  "LWSA3"  "MGLU3"  "MRFG3"  "MRVE3"  "MULT3"  "NTCO3"  "PCAR3" 
#> [65] "PETR3"  "PETR4"  "PETZ3"  "POSI3"  "PRIO3"  "QUAL3"  "RADL3"  "RAIL3" 
#> [73] "RDOR3"  "RENT3"  "RRRP3"  "SANB11" "SBSP3"  "SLCE3"  "SOMA3"  "SULA11"
#> [81] "SUZB3"  "TAEE11" "TIMS3"  "TOTS3"  "UGPA3"  "USIM5"  "VALE3"  "VBBR3" 
#> [89] "VIIA3"  "VIVT3"  "WEGE3"  "YDUQ3"
```

With the index composition you can use COTAHIST to select their quotes.

``` r
glimpse(
  cotahist_get_symbols(ch, ibov_comp)
)
#> Rows: 90
#> Columns: 13
#> $ refdate               <date> 2022-09-23, 2022-09-23, 2022-09-23, 2022-09-23,~
#> $ symbol                <chr> "ABEV3", "ALPA4", "AMER3", "ASAI3", "AZUL4", "B3~
#> $ open                  <dbl> 15.40, 22.30, 16.87, 17.76, 17.00, 13.03, 40.80,~
#> $ high                  <dbl> 15.48, 22.55, 17.80, 18.09, 17.05, 13.39, 40.90,~
#> $ low                   <dbl> 15.17, 21.96, 16.84, 17.61, 16.00, 13.01, 40.08,~
#> $ close                 <dbl> 15.37, 22.35, 17.53, 17.79, 16.14, 13.39, 40.73,~
#> $ average               <dbl> 15.33, 22.27, 17.39, 17.79, 16.30, 13.24, 40.52,~
#> $ best_bid              <dbl> 15.36, 22.33, 17.53, 17.78, 16.13, 13.39, 40.69,~
#> $ best_ask              <dbl> 15.37, 22.35, 17.54, 17.79, 16.14, 13.40, 40.75,~
#> $ volume                <dbl> 598903006, 43377998, 492345131, 214449477, 20167~
#> $ traded_contracts      <dbl> 39045900, 1947300, 28306800, 12048200, 12371700,~
#> $ transactions_quantity <int> 34816, 9533, 41228, 25408, 18741, 36027, 29738, ~
#> $ distribution_id       <int> 125, 231, 101, 104, 101, 123, 309, 746, 746, 121~
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
#>    tipo_r~1 id_fpr nome_~2 forma~3 id_gr~4 id_ca~5 id_in~6 orige~7  base base_~8
#>       <int>  <int> <chr>   <fct>     <dbl> <chr>     <dbl>   <int> <int>   <int>
#>  1        2   1422 VLRAPT4 Basis ~       1 BVMF    2.00e11       8     0       0
#>  2        2   1423 VLPETR3 Basis ~       1 BVMF    2.00e11       8     0       0
#>  3        2   1424 VLSEER3 Basis ~       1 BVMF    2.00e11       8     0       0
#>  4        2   1426 VLJBSS3 Basis ~       1 BVMF    2.00e11       8     0       0
#>  5        2   1427 VLKLBN~ Basis ~       1 BVMF    2.00e11       8     0       0
#>  6        2   1428 VLITUB3 Basis ~       1 BVMF    2.00e11       8     0       0
#>  7        2   1429 VLITSA4 Basis ~       1 BVMF    2.00e11       8     0       0
#>  8        2   1430 VLHYPE3 Basis ~       1 BVMF    2.00e11       8     0       0
#>  9        2   1431 VLGRND3 Basis ~       1 BVMF    2.00e11       8     0       0
#> 10        2   1433 VLUGPA3 Basis ~       1 BVMF    2.00e11       8     0       0
#> # ... with 3,194 more rows, 1 more variable: criterio_capitalizacao <int>, and
#> #   abbreviated variable names 1: tipo_registro, 2: nome_fpr,
#> #   3: formato_variacao, 4: id_grupo_fpr, 5: id_camara_indicador,
#> #   6: id_instrumento_indicador, 7: origem_instrumento, 8: base_interpolacao
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
