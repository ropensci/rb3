# Package index

## rb3 Package

Package overview and core functionality

- [`rb3`](https://ropensci.github.io/rb3/reference/rb3-package.md)
  [`rb3-package`](https://ropensci.github.io/rb3/reference/rb3-package.md)
  : Access and Process B3 Data

- [`rb3_bootstrap()`](https://ropensci.github.io/rb3/reference/rb3_bootstrap.md)
  : Initialize the rb3 package cache folders

- [`rb3.cachedir`](https://ropensci.github.io/rb3/reference/rb3.cachedir.md)
  :

  `rb3.cachedir` Option

- [`meta_db_connection()`](https://ropensci.github.io/rb3/reference/meta_db_connection.md)
  : Returns a SQLite Database Connection for the RB3 Package Metadata

## Marketdata Access

Functions for downloading and reading market data from B3

- [`fetch_marketdata()`](https://ropensci.github.io/rb3/reference/fetch_marketdata.md)
  : Fetch and process market data
- [`download_marketdata()`](https://ropensci.github.io/rb3/reference/download_marketdata.md)
  : Download Raw Market Data Files from B3
- [`read_marketdata()`](https://ropensci.github.io/rb3/reference/read_marketdata.md)
  : Read and parse raw market data files downloaded from the B3 website.
- [`list_templates()`](https://ropensci.github.io/rb3/reference/list_templates.md)
  : List Available Templates
- [`template_retrieve()`](https://ropensci.github.io/rb3/reference/template_retrieve.md)
  : Retrieve a template by its name
- [`template_dataset()`](https://ropensci.github.io/rb3/reference/template_dataset.md)
  : Access a Dataset for a Template
- [`template_meta_load()`](https://ropensci.github.io/rb3/reference/template_meta_create_or_load.md)
  [`template_meta_new()`](https://ropensci.github.io/rb3/reference/template_meta_create_or_load.md)
  [`template_meta_create_or_load()`](https://ropensci.github.io/rb3/reference/template_meta_create_or_load.md)
  : Create or Load Template Metadata

## Equity Data (COTAHIST files)

Functions to access and filter equity historical data (COTAHIST files)

- [`cotahist_filter_equity()`](https://ropensci.github.io/rb3/reference/cotahist-extracts.md)
  [`cotahist_filter_etf()`](https://ropensci.github.io/rb3/reference/cotahist-extracts.md)
  [`cotahist_filter_bdr()`](https://ropensci.github.io/rb3/reference/cotahist-extracts.md)
  [`cotahist_filter_unit()`](https://ropensci.github.io/rb3/reference/cotahist-extracts.md)
  [`cotahist_filter_fii()`](https://ropensci.github.io/rb3/reference/cotahist-extracts.md)
  [`cotahist_filter_fidc()`](https://ropensci.github.io/rb3/reference/cotahist-extracts.md)
  [`cotahist_filter_fiagro()`](https://ropensci.github.io/rb3/reference/cotahist-extracts.md)
  [`cotahist_filter_index()`](https://ropensci.github.io/rb3/reference/cotahist-extracts.md)
  [`cotahist_filter_equity_options()`](https://ropensci.github.io/rb3/reference/cotahist-extracts.md)
  [`cotahist_filter_index_options()`](https://ropensci.github.io/rb3/reference/cotahist-extracts.md)
  [`cotahist_filter_etf_options()`](https://ropensci.github.io/rb3/reference/cotahist-extracts.md)
  [`cotahist_filter_fund_options()`](https://ropensci.github.io/rb3/reference/cotahist-extracts.md)
  : Filtering data from COTAHIST datasets
- [`cotahist_get()`](https://ropensci.github.io/rb3/reference/cotahist_get.md)
  : Access COTAHIST datasets
- [`cotahist_options_by_symbols_get()`](https://ropensci.github.io/rb3/reference/superdataset.md)
  [`yc_brl_with_futures_get()`](https://ropensci.github.io/rb3/reference/superdataset.md)
  [`yc_usd_with_futures_get()`](https://ropensci.github.io/rb3/reference/superdataset.md)
  [`yc_ipca_with_futures_get()`](https://ropensci.github.io/rb3/reference/superdataset.md)
  : Enhanced Dataset Creation

## B3 Indexes Data

Functions to access and filter B3 indexes composition, weights and
historical data

- [`indexes_current_portfolio_get()`](https://ropensci.github.io/rb3/reference/indexes-portfolio.md)
  [`indexes_theoretical_portfolio_get()`](https://ropensci.github.io/rb3/reference/indexes-portfolio.md)
  : Retrieve Portfolio of B3 Indexes
- [`indexes_composition_get()`](https://ropensci.github.io/rb3/reference/indexes_composition_get.md)
  : Retrieve Composition of B3 Indexes
- [`indexes_get()`](https://ropensci.github.io/rb3/reference/indexes_get.md)
  : Get B3 indexes available
- [`indexes_historical_data_get()`](https://ropensci.github.io/rb3/reference/indexes_historical_data_get.md)
  : Get historical data from B3 indexes

## Yield Curves Data

Functions to access yield curve data

- [`cotahist_options_by_symbols_get()`](https://ropensci.github.io/rb3/reference/superdataset.md)
  [`yc_brl_with_futures_get()`](https://ropensci.github.io/rb3/reference/superdataset.md)
  [`yc_usd_with_futures_get()`](https://ropensci.github.io/rb3/reference/superdataset.md)
  [`yc_ipca_with_futures_get()`](https://ropensci.github.io/rb3/reference/superdataset.md)
  : Enhanced Dataset Creation
- [`yc_get()`](https://ropensci.github.io/rb3/reference/yc_xxx_get.md)
  [`yc_brl_get()`](https://ropensci.github.io/rb3/reference/yc_xxx_get.md)
  [`yc_ipca_get()`](https://ropensci.github.io/rb3/reference/yc_xxx_get.md)
  [`yc_usd_get()`](https://ropensci.github.io/rb3/reference/yc_xxx_get.md)
  : Retrieve Yield Curve Data

## Futures Data

Functions for accessing and working with futures data

- [`futures_get()`](https://ropensci.github.io/rb3/reference/futures_get.md)
  : Retrieves B3 Futures Settlement Prices

## Utilities

Helper functions for working with rb3 data

- [`cotahist_options_by_symbols_get()`](https://ropensci.github.io/rb3/reference/superdataset.md)
  [`yc_brl_with_futures_get()`](https://ropensci.github.io/rb3/reference/superdataset.md)
  [`yc_usd_with_futures_get()`](https://ropensci.github.io/rb3/reference/superdataset.md)
  [`yc_ipca_with_futures_get()`](https://ropensci.github.io/rb3/reference/superdataset.md)
  : Enhanced Dataset Creation
- [`maturitycode2date()`](https://ropensci.github.io/rb3/reference/maturitycode2date.md)
  : Convert Maturity Code to Date
- [`code2month()`](https://ropensci.github.io/rb3/reference/code2month.md)
  : Convert Maturity Code to Corresponding Month
