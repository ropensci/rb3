# rb3 0.0.4

* added locale `en` to templates: `COTAHIST_*`
* new templates
  * `NegociosIntraday` intraday listed market trades
  * `NegociosBalcao` intraday OTC (Debentures) trades
  * `NegociosBTB` intraday lending trades
* imports organized (using importFrom in NAMESPACE)
* added option `rb3.cachedir` to set default cache directory in order to use cached files accross multiple sessions


# rb3 0.0.3 

* fixed tests for yc_get().
* updated to bizdays version 0.1.10 (use of load_builtin_calendars - Issue #31).
* changes to ropensci process: added more tests to improve test coverage, functions renamed, codemeta and Contributing.md.
* new templates
  * `GetStockIndex` to get the composition of B3 indexes.
  * `GetTheoricalPortfolio` to get composition and weights of B3 indexes.
  * `GetPortfolioDay` to get composition, weights and segments of B3 indexes.
  * `CenariosCurva` for scenarios of term structures of interest rates.
  * `CenariosPrecoReferencia` for reference prices scenarios.
  * `IndexReport` indexes daily market data.
  * `PriceReport` daily prices and market data.
  * `GetListedSupplementCompany` supplement data for listed companies.
  * `GetDetailsCompany` to get companies details (name, codeCVM, ...).
  * `GetListedCashDividends` to get list of cash dividends.
* new functions for yield curves
  * `yc_ipca_get` and `yc_ipca_mget` for real interest rates
  * `yc_usd_get` and `yc_usd_mget` for USD interest rates in Brazil
* new functions for cotahist
  * `cotahist_get_symbols` to get stocks by a list of symbols
  * `cotahist_etfs_get`, `cotahist_fiis_get`, `cotahist_fidcs_get`, `cotahist_fiagros_get`
  * function `cotahist_funds_get` has been replaced by these ones.
* new functions to get indexes information (composition, weights and positions)
  * `index_comp_get` returns the index composition
  * `index_weights_get` returns the index weights
  * `index_by_segment_get` returns indexes assets grouped by segments
  * `indexes_get` lists the available indexes
  * `indexes_last_update` returns the date when the indexes have been updated
  * `indexreport_get` and `indexreport_mget` download index report data
* Superset datasets
  * `cotahist_equity_options_superset` joins options data, equity data and interest rates for each option - this is useful to run option and volatility models.
  * `yc_superset`, `yc_usd_superset`, `yc_ipca_superset` mark futures maturities in yield curve.

# rb3 0.0.2

* changes for ropensci process, replaced `sapply` with `purrr::map_xxx`.
* improved class Filename, added new methods.
* added argument `destdir = NULL` to `convert_to` function.
* created functions `yc_get` / `yc_mget` and `futures_get` / `futures_mget` (Issue #26).
* improved `fields` creation (Issue #27).
* added downloader/reader for `GetStockIndex`, JSON file with relations between stocks and indexes.

# rb3 0.0.1

* first release