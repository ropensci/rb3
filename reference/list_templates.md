# List Available Templates

Retrieves all templates registered in the template registry and returns
their properties as a tibble.

## Usage

``` r
list_templates()
```

## Value

A tibble with the following columns:

- Description:

  The description of the template

- Template:

  The template identifier

## Examples

``` r
list_templates()
#> # A tibble: 11 × 2
#>    Template                          Description                                
#>    <chr>                             <chr>                                      
#>  1 b3-bdi-derivatives-trades         Negócios consolidados do pregão - Derivati…
#>  2 b3-bvbg-086                       Arquivo de Preços de Mercado - BVBG-086    
#>  3 b3-cotahist-daily                 Cotações Históricas do Pregão de Ações - A…
#>  4 b3-cotahist-yearly                Cotações Históricas do Pregão de Ações - A…
#>  5 b3-futures-settlement-prices      Preços de Ajustes Diários de Contratos Fut…
#>  6 b3-indexes-composition            Composição dos índices da B3               
#>  7 b3-indexes-current-portfolio      Carteira teórica corrente dos índices da B…
#>  8 b3-indexes-historical-data        Dados históricos e estatísticas dos índice…
#>  9 b3-indexes-theoretical-portfolio  Carteira Teórica dos índices da B3 com pes…
#> 10 b3-reference-rates                Taxas referenciais (Mercado de Derivativos…
#> 11 b3-trade-information-consolidated Negócios consolidados do pregão (TradeInfo…
```
