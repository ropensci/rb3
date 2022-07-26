
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
2000’s, and can be used by industry practioneers or academics. None of
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

In this first example we’ll import and plot the historical yeild curve
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
#> Rows: 383
#> Columns: 13
#> $ refdate               <date> 2022-07-25, 2022-07-25, 2022-07-25, 2022-07-25,…
#> $ symbol                <chr> "AALR3", "ABCB4", "ABEV3", "AERI3", "AESB3", "AG…
#> $ open                  <dbl> 19.88, 16.42, 14.53, 2.97, 10.30, 23.43, 7.10, 9…
#> $ high                  <dbl> 20.18, 16.92, 14.78, 2.97, 10.50, 23.74, 7.22, 1…
#> $ low                   <dbl> 19.71, 16.42, 14.45, 2.77, 10.30, 23.37, 6.69, 9…
#> $ close                 <dbl> 19.88, 16.82, 14.68, 2.78, 10.44, 23.37, 6.78, 9…
#> $ average               <dbl> 19.88, 16.77, 14.68, 2.82, 10.40, 23.53, 6.92, 9…
#> $ best_bid              <dbl> 19.76, 16.73, 14.68, 2.77, 10.44, 23.37, 6.78, 9…
#> $ best_ask              <dbl> 19.88, 16.82, 14.69, 2.78, 10.46, 23.55, 7.00, 9…
#> $ volume                <dbl> 3837126, 8321425, 210650873, 7862655, 9334466, 7…
#> $ traded_contracts      <dbl> 193000, 496100, 14348000, 2782600, 897400, 31690…
#> $ transactions_quantity <int> 889, 3406, 20723, 4508, 3304, 1941, 464, 133, 46…
#> $ distribution_id       <int> 102, 141, 125, 101, 102, 112, 101, 103, 231, 231…
```

### Funds data

One can also download hedge fund data with `cotahist_etfs_get`.

``` r
glimpse(
  cotahist_etfs_get(ch)
)
#> Rows: 87
#> Columns: 13
#> $ refdate               <date> 2022-07-25, 2022-07-25, 2022-07-25, 2022-07-25,…
#> $ symbol                <chr> "5GTK11", "ACWI11", "AGRI11", "ALUG11", "ASIA11"…
#> $ open                  <dbl> 85.10, 9.80, 45.60, 40.60, 8.01, 50.65, 81.48, 9…
#> $ high                  <dbl> 87.20, 9.80, 46.26, 40.60, 8.01, 51.59, 82.34, 9…
#> $ low                   <dbl> 84.52, 9.51, 45.60, 39.66, 7.82, 50.65, 81.48, 8…
#> $ close                 <dbl> 84.80, 9.53, 46.19, 39.85, 7.84, 51.58, 81.93, 8…
#> $ average               <dbl> 85.20, 9.53, 45.93, 40.06, 7.84, 51.48, 81.85, 8…
#> $ best_bid              <dbl> 74.01, 9.53, 45.00, 39.70, 7.80, 50.64, 81.66, 8…
#> $ best_ask              <dbl> 84.80, 9.57, 46.25, 39.85, 7.84, 53.91, 82.07, 8…
#> $ volume                <dbl> 1107.65, 1769630.74, 3812.84, 112492.61, 509566.…
#> $ traded_contracts      <dbl> 13, 185568, 83, 2808, 64994, 2285, 54, 2647, 434…
#> $ transactions_quantity <int> 7, 237, 10, 47, 43, 17, 19, 183, 664, 5, 58540, …
#> $ distribution_id       <int> 100, 100, 100, 100, 100, 100, 100, 108, 100, 100…
```

### FIIs (brazilian REITs) data

Download FII (Fundo de Investimento Imobiliário) data with
`cotahist_fiis_get`:

``` r
glimpse(
  cotahist_fiis_get(ch)
)
#> Rows: 261
#> Columns: 13
#> $ refdate               <date> 2022-07-25, 2022-07-25, 2022-07-25, 2022-07-25,…
#> $ symbol                <chr> "BZLI11", "ABCP11", "AFHI11", "AFOF11", "AIEC11"…
#> $ open                  <dbl> 17.00, 68.73, 98.71, 85.51, 73.56, 851.01, 113.5…
#> $ high                  <dbl> 19.50, 69.65, 99.04, 86.39, 73.93, 851.03, 114.0…
#> $ low                   <dbl> 17.00, 68.60, 98.50, 85.46, 73.25, 851.01, 112.6…
#> $ close                 <dbl> 17.03, 68.66, 98.90, 86.13, 73.27, 851.03, 112.9…
#> $ average               <dbl> 17.09, 68.92, 98.81, 85.92, 73.65, 851.02, 113.5…
#> $ best_bid              <dbl> 17.00, 68.66, 98.75, 86.12, 73.27, 851.03, 112.9…
#> $ best_ask              <dbl> 19.78, 69.44, 98.90, 86.38, 73.76, 888.94, 112.9…
#> $ volume                <dbl> 3624.63, 62788.29, 1926722.95, 98128.51, 311114.…
#> $ traded_contracts      <dbl> 212, 911, 19498, 1142, 4224, 13, 15693, 1812, 30…
#> $ transactions_quantity <int> 7, 214, 1005, 121, 380, 3, 1963, 464, 5697, 183,…
#> $ distribution_id       <int> 100, 316, 117, 116, 122, 250, 158, 107, 129, 133…
```

### BDRs data

Download BDR (Brazilian depositary receipts) with `cotahist_bdrs_get`:

``` r
glimpse(
  cotahist_bdrs_get(ch)
)
#> Rows: 501
#> Columns: 13
#> $ refdate               <date> 2022-07-25, 2022-07-25, 2022-07-25, 2022-07-25,…
#> $ symbol                <chr> "A1BB34", "A1CR34", "A1DI34", "A1DM34", "A1EE34"…
#> $ open                  <dbl> 38.36, 67.81, 439.86, 409.00, 236.89, 22.82, 311…
#> $ high                  <dbl> 38.36, 68.78, 439.86, 409.00, 236.89, 22.86, 311…
#> $ low                   <dbl> 38.36, 67.81, 432.87, 409.00, 236.89, 22.65, 311…
#> $ close                 <dbl> 38.36, 68.37, 436.18, 409.00, 236.89, 22.65, 311…
#> $ average               <dbl> 38.36, 68.30, 435.99, 409.00, 236.89, 22.77, 311…
#> $ best_bid              <dbl> 0.00, 0.00, 0.00, 198.00, 0.00, 0.00, 0.00, 50.0…
#> $ best_ask              <dbl> 0.00, 0.00, 0.00, 0.00, 0.00, 23.66, 0.00, 0.00,…
#> $ volume                <dbl> 38.36, 1092.80, 152598.19, 1227.00, 51405.13, 17…
#> $ traded_contracts      <dbl> 1, 16, 350, 3, 217, 79, 1, 42, 4, 1, 1, 4, 31, 9…
#> $ transactions_quantity <int> 1, 6, 350, 1, 1, 5, 1, 3, 2, 1, 1, 4, 2, 38, 8, …
#> $ distribution_id       <int> 102, 107, 110, 110, 110, 103, 110, 110, 106, 101…
```

### Equity options

Download equity options contracts with `cotahist_option_get`:

``` r
glimpse(
  cotahist_equity_options_get(ch)
)
#> Rows: 4,911
#> Columns: 14
#> $ refdate               <date> 2022-07-25, 2022-07-25, 2022-07-25, 2022-07-25,…
#> $ symbol                <chr> "ABCBH170", "ABEVH160", "ABEVI16", "ABEVI20", "A…
#> $ type                  <fct> Call, Call, Call, Call, Call, Call, Call, Call, …
#> $ strike                <dbl> 16.70, 15.04, 15.47, 19.47, 13.29, 16.04, 14.54,…
#> $ maturity_date         <date> 2022-08-19, 2022-08-19, 2023-09-15, 2022-09-16,…
#> $ open                  <dbl> 0.40, 0.34, 2.70, 0.02, 1.26, 0.10, 0.52, 0.07, …
#> $ high                  <dbl> 0.40, 0.43, 2.70, 0.02, 1.70, 0.13, 0.71, 0.10, …
#> $ low                   <dbl> 0.38, 0.33, 2.61, 0.01, 1.26, 0.10, 0.52, 0.07, …
#> $ close                 <dbl> 0.38, 0.40, 2.61, 0.01, 1.62, 0.11, 0.65, 0.10, …
#> $ average               <dbl> 0.38, 0.39, 2.62, 0.01, 1.58, 0.11, 0.64, 0.08, …
#> $ volume                <dbl> 1914, 238187, 1575, 31, 205109, 9310, 224798, 12…
#> $ traded_contracts      <dbl> 5000, 609800, 600, 1600, 129700, 81300, 346300, …
#> $ transactions_quantity <int> 28, 240, 2, 5, 21, 49, 125, 17, 7, 3, 1, 79, 15,…
#> $ distribution_id       <int> 140, 122, 124, 124, 124, 124, 124, 124, 124, 124…
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
#> $ refdate               <date> 2022-07-25, 2022-07-25, 2022-07-25, 2022-07-25,…
#> $ symbol                <chr> "ABEV3", "ALPA4", "AMER3", "ASAI3", "AZUL4", "B3…
#> $ open                  <dbl> 14.53, 20.83, 16.01, 15.79, 11.65, 10.79, 34.55,…
#> $ high                  <dbl> 14.78, 20.92, 16.29, 16.02, 11.77, 10.79, 35.31,…
#> $ low                   <dbl> 14.45, 20.34, 15.47, 15.48, 11.30, 10.49, 34.55,…
#> $ close                 <dbl> 14.68, 20.56, 15.57, 15.50, 11.46, 10.73, 35.20,…
#> $ average               <dbl> 14.68, 20.57, 15.68, 15.66, 11.49, 10.64, 35.14,…
#> $ best_bid              <dbl> 14.68, 20.56, 15.57, 15.50, 11.45, 10.72, 35.19,…
#> $ best_ask              <dbl> 14.69, 20.61, 15.58, 15.56, 11.46, 10.73, 35.22,…
#> $ volume                <dbl> 210650873, 42503172, 139585738, 97558778, 108594…
#> $ traded_contracts      <dbl> 14348000, 2066100, 8901400, 6226600, 9446600, 30…
#> $ transactions_quantity <int> 20723, 9770, 13032, 17344, 17329, 28779, 48368, …
#> $ distribution_id       <int> 125, 231, 101, 104, 101, 122, 307, 744, 744, 120…
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
#> [1] "/tmp/RtmpDXjc8M/rb3-cache/FPR/7a2422cc97221426a3b2bd4419215481/FP220510/FatoresPrimitivosRisco.txt"
```

`download_marketdata` returns the path for the downloaded file.

``` r
fpr <- read_marketdata(f, "FPR")
fpr
#> $Header
#> # A tibble: 1 × 2
#>   tipo_registro data_geracao_arquivo
#>           <int> <date>              
#> 1             1 2022-05-10          
#> 
#> $Data
#> # A tibble: 3,204 × 11
#>    tipo_r…¹ id_fpr nome_…² forma…³ id_gr…⁴ id_ca…⁵ id_in…⁶ orige…⁷  base base_…⁸
#>       <int>  <int> <chr>   <fct>     <dbl> <chr>     <dbl>   <int> <int>   <int>
#>  1        2   1422 VLRAPT4 Basis …       1 BVMF    2.00e11       8     0       0
#>  2        2   1423 VLPETR3 Basis …       1 BVMF    2.00e11       8     0       0
#>  3        2   1424 VLSEER3 Basis …       1 BVMF    2.00e11       8     0       0
#>  4        2   1426 VLJBSS3 Basis …       1 BVMF    2.00e11       8     0       0
#>  5        2   1427 VLKLBN… Basis …       1 BVMF    2.00e11       8     0       0
#>  6        2   1428 VLITUB3 Basis …       1 BVMF    2.00e11       8     0       0
#>  7        2   1429 VLITSA4 Basis …       1 BVMF    2.00e11       8     0       0
#>  8        2   1430 VLHYPE3 Basis …       1 BVMF    2.00e11       8     0       0
#>  9        2   1431 VLGRND3 Basis …       1 BVMF    2.00e11       8     0       0
#> 10        2   1433 VLUGPA3 Basis …       1 BVMF    2.00e11       8     0       0
#> # … with 3,194 more rows, 1 more variable: criterio_capitalizacao <int>, and
#> #   abbreviated variable names ¹​tipo_registro, ²​nome_fpr, ³​formato_variacao,
#> #   ⁴​id_grupo_fpr, ⁵​id_camara_indicador, ⁶​id_instrumento_indicador,
#> #   ⁷​origem_instrumento, ⁸​base_interpolacao
#> # ℹ Use `print(n = ...)` to see more rows, and `colnames()` to see all variable names
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
