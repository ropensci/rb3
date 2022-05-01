
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

Download and read a bunch o data from [B3](https://www.b3.com.br) making
it easy to store, process and consume it in a structure way.

# Documentation

The documentation is available
[here](https://wilsonfreitas.github.io/rb3/), the reference and articles
with real applications can be found.

## Installation

``` r
devtools::install_github("wilsonfreitas/rb3")
```

## Examples

### Yield curve

Download and use historical yield curve data with `yc_get`.

``` r
library(rb3)
library(ggplot2)
library(stringr)

df_yc <- yc_get(
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

df <- futures_get(
    first_date = "2022-04-01",
    last_date = "2022-04-29",
    by = 5
)

df |> filter(commodity == "DI1")
#> # A tibble: 153 x 8
#>    refdate    commodity maturity_code symbol price_previous   price change settlement_value
#>    <date>     <chr>     <chr>         <chr>           <dbl>   <dbl>  <dbl>            <dbl>
#>  1 2022-04-01 DI1       J22           DI1J22        100000. 100000    0.01             0.01
#>  2 2022-04-01 DI1       K22           DI1K22         99172.  99172.  -0.19             0.19
#>  3 2022-04-01 DI1       M22           DI1M22         98159.  98160.   0.96             0.96
#>  4 2022-04-01 DI1       N22           DI1N22         97182.  97185.   3.56             3.56
#>  5 2022-04-01 DI1       Q22           DI1Q22         96199.  96210.  11.3             11.3 
#>  6 2022-04-01 DI1       U22           DI1U22         95138.  95159.  21.6             21.6 
#>  7 2022-04-01 DI1       V22           DI1V22         94174.  94209.  34.9             34.9 
#>  8 2022-04-01 DI1       X22           DI1X22         93265.  93314.  48.8             48.8 
#>  9 2022-04-01 DI1       Z22           DI1Z22         92365.  92423.  57.3             57.3 
#> 10 2022-04-01 DI1       F23           DI1F23         91405.  91472.  67.4             67.4 
#> # ... with 143 more rows
```

### Equity data

Equity closing data (without price adjustments) is available thru
`cotahist_get`.

``` r
library(rb3)
library(bizdays)

date <- preceding(Sys.Date(), "Brazil/ANBIMA") # last business day
ch <- cotahist_get(date, "daily")
#> Skipping download - using cached version
cotahist_equity_get(ch)
#> # A tibble: 378 x 13
#>    refdate    symbol  open  high   low close average best_bid best_ask    volume traded_contracts transactions_quantity distribution_id
#>    <date>     <chr>  <dbl> <dbl> <dbl> <dbl>   <dbl>    <dbl>    <dbl>     <dbl>            <int>                 <int>           <int>
#>  1 2022-04-29 AALR3  19.7  19.8  19.3  19.4    19.5     19.4     19.4   14055007           721500                  2050             102
#>  2 2022-04-29 ABCB4  16.8  16.8  15.8  15.8    16.1     15.8     16     28379427          1763100                  6273             140
#>  3 2022-04-29 ABEV3  14.8  15    14.5  14.5    14.7     14.5     14.6  384931858         26145100                 23420             125
#>  4 2022-04-29 AERI3   5.12  5.18  4.88  4.88    5        4.88     4.89  11565634          2309900                  6249             101
#>  5 2022-04-29 AESB3  11.2  11.3  11.0  11.0    11.1     11.0     11.0   38200620          3443700                  8291             102
#>  6 2022-04-29 AGRO3  34.3  34.7  33.8  34.0    34.2     34.0     34     37912461          1107600                  4766             112
#>  7 2022-04-29 AGXY3   9.2   9.8   9.11  9.8     9.59     9.13     9.8    1504789           156900                   349             100
#>  8 2022-04-29 ALLD3  14.0  14.2  13.8  14.0    14.0     13.8     14.0     952543            68100                   303             102
#>  9 2022-04-29 ALPA3  19    19.5  19    19.5    19.2     18.5     19.3       3850              200                     2             231
#> 10 2022-04-29 ALPA4  20.4  20.6  19.5  19.6    20.0     19.6     19.6   84525397          4236000                 20368             231
#> # ... with 368 more rows
```

Funds data

``` r
cotahist_funds_get(ch)
#> # A tibble: 366 x 13
#>    refdate    symbol  open  high   low close average best_bid best_ask   volume traded_contracts transactions_quantity distribution_id
#>    <date>     <chr>  <dbl> <dbl> <dbl> <dbl>   <dbl>    <dbl>    <dbl>    <dbl>            <int>                 <int>           <int>
#>  1 2022-04-29 BZLI11  16.9  16.9  16.9  16.9    16.9     16.9     17.7     135.                8                     2             100
#>  2 2022-04-29 ABCP11  74.4  74.9  73.2  73.6    73.6     73.3     73.6  151215.             2054                   205             313
#>  3 2022-04-29 AFHI11  99.2  99.2  98.6  99.0    98.9     99.0     99.0 1000056.            10115                   709             113
#>  4 2022-04-29 AFOF11  93.9  94.4  92.5  93.4    93.2     92.8     93.4  205333.             2202                    87             113
#>  5 2022-04-29 AIEC11  80.4  81.0  79.5  80.2    80.0     80.2     80.2 1146269.            14330                  3001             119
#>  6 2022-04-29 ALMI11 930   930   930   930     928.     930      986.     5571.                6                     5             250
#>  7 2022-04-29 ALZR11 115.  116.  115.  116.    116.     116.     116.   659266.             5691                   737             154
#>  8 2022-04-29 APTO11  10.4  10.4  10.3  10.4    10.4     10.4     10.4    9442.              908                    54             104
#>  9 2022-04-29 ARCT11 105   105.  105.  105.    105.     105.     105.  2524851.            24029                  3965             125
#> 10 2022-04-29 ARRI11  98.8  99.0  96.5  98.8    98.1     98.7     98.8  437927.             4462                   288             130
#> # ... with 356 more rows
```

BDRs data

``` r
cotahist_bdrs_get(ch)
#> # A tibble: 523 x 13
#>    refdate    symbol  open  high   low close average best_bid best_ask  volume traded_contracts transactions_quantity distribution_id
#>    <date>     <chr>  <dbl> <dbl> <dbl> <dbl>   <dbl>    <dbl>    <dbl>   <dbl>            <int>                 <int>           <int>
#>  1 2022-04-29 A1AP34  61.5  61.5  61.5  61.5    61.5     61.5     70.1  44287.              720                     1             110
#>  2 2022-04-29 A1BB34  37.4  37.5  36.9  36.9    36.9     36.9     58.5 185763.             5035                     6             102
#>  3 2022-04-29 A1CR34  59.6  59.6  58.7  58.7    58.7     58.7      0    42918.              731                     2             106
#>  4 2022-04-29 A1DM34 447.  447.  443.  443.    445.       0        0     1779.                4                     4             109
#>  5 2022-04-29 A1EG34  25.5  25.6  25.5  25.6    25.6     25.5     25.6   3175.              124                     3             102
#>  6 2022-04-29 A1ES34 101.  101.  101.  101.    101.     101.       0    66587.              660                     1             110
#>  7 2022-04-29 A1GI34 302.  302.  302.  302.    302.       0      303.     302.                1                     1             109
#>  8 2022-04-29 A1IV34  31.2  31.2  31.2  31.2    31.2     31.2     32.9  10618.              340                     1             106
#>  9 2022-04-29 A1KA34  46.2  46.2  46.2  46.2    46.2     46.2      0    73522.             1590                     1             101
#> 10 2022-04-29 A1LB34 978   978   950.  950.    951.     950.    1061    58005                61                     2             109
#> # ... with 513 more rows
```

Equity options

``` r
cotahist_equity_options_get(ch)
#> # A tibble: 4,794 x 14
#>    refdate    symbol   type  strike maturity_date  open  high   low close average volume traded_contracts transactions_quantity distribution_id
#>    <date>     <chr>    <fct>  <dbl> <date>        <dbl> <dbl> <dbl> <dbl>   <dbl>  <dbl>            <int>                 <int>           <int>
#>  1 2022-04-29 ABEVE135 Call    13.5 2022-05-20     1.46  1.55  1.46  1.48    1.53 323814           210700                    33             125
#>  2 2022-04-29 ABEVE162 Call    16.3 2022-05-20     0.06  0.07  0.05  0.05    0.05    412             7800                     8             125
#>  3 2022-04-29 ABEVE140 Call    14.0 2022-05-20     1.07  1.19  0.92  0.92    1.07  12437            11600                    11             125
#>  4 2022-04-29 ABEVE167 Call    16.8 2022-05-20     0.04  0.04  0.03  0.03    0.03    185             5300                     9             125
#>  5 2022-04-29 ABEVE150 Call    15.0 2022-05-20     0.37  0.46  0.28  0.3     0.37 796102          2102300                   266             125
#>  6 2022-04-29 ABEVE130 Call    13.0 2022-05-20     1.98  1.98  1.84  1.84    1.91   3820             2000                     2             125
#>  7 2022-04-29 ALSOE270 Call    27   2022-05-20     0.1   0.1   0.1   0.1     0.1      30              300                     1             101
#>  8 2022-04-29 ALSOM205 Put     20.5 2023-01-20     1.8   1.8   1.8   1.8     1.8   10980             6100                     1             101
#>  9 2022-04-29 AMERE333 Call    33.3 2022-05-20     0.05  0.05  0.05  0.05    0.05    505            10100                     2             101
#> 10 2022-04-29 AMERE338 Call    33.8 2022-05-20     0.07  0.07  0.07  0.07    0.07      7              100                     1             101
#> # ... with 4,784 more rows
```
