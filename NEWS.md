# rb3 0.0.10

* Check empty files download.

# rb3 0.0.10

* Improved error handling in `read_marketdata`.
* Improved checks in `test-company.R` with exception handling for empty downloaded files.
* Removed tidyselect warnings in `scraper-company.R`.

# rb3 0.0.9

* Corrected BUG: function `company_cash_dividends_get` does not return all cash dividends
* Implemented new option in templates: `verifyssl`. It defaults to TRUE, always use ssl, but when it is FALSE an option is set in httr to skip ssl verification.
* Corrected `futures_get` and `futures_mget` to handle equity futures

# rb3 0.0.8

* functions `company_cash_dividends_get`, `company_info_get`, `company_stock_dividends_get`, `company_subscriptions_get` to get company's informations


# rb3 0.0.7

* function `index_get` to download historical data from B3 indexes (Issue #39)
* added option `rb3.silent` (defaults to `FALSE`) hide alert messages and progress bar
* added option `rb3.clear.cache` (defaults to `FALSE`) remove files with invalid content from cache folder
* new templates
  * `GetPortfolioDay_IndexStatistics` historical time series for B3 indexes
* new vignette: B3 Indexes
* changed `futures_get` and `maturity2date` to use calendar `Brazil/BMF`
* `maturity2date` has a new argument refdate, it must be passed when converting old maturities like JAN0, FEV0, ...

# rb3 0.0.6

* updated documentation
* functions `code2month` and `maturity2date` now accept old 4 characters maturity code, before 2006
* new function `cotahist_options_by_symbol_superset` joins options data, equity data and interest rates for each option for a given symbol (Issue #50)
* corrected BUG in cache system, avoid caching NULL returns (Issue #52)
* corrected BUG cdi_get and idi_get use do_cache = FALSE (Issue #51)

# rb3 0.0.5

* updated documentation
* the cache creates a folder with the template to organize files inside the cache folder.
* `read_marketdata` lost the argument `cachedir`, the RDS file with parsed data is saved in the directory of the given file.
  * Pass `do_cache = FALSE` to not save the RDS file, it defaults to `TRUE`.
* corrected BUG in `COTAHIST_YEARLY`, it uses cache wrongly (Issue #44)
* corrected BUG due to change in fixedincome - function `rates` was renamed to `implied_rate`

# rb3 0.0.4

* added locale `en` to templates: `COTAHIST_*`
* new templates
  * `NegociosIntraday` intraday listed market trades
  * `NegociosBalcao` intraday OTC (Debentures) trades
  * `NegociosBTB` intraday lending trades
* imports organized (using importFrom in NAMESPACE)
* added option `rb3.cachedir` to set default cache directory in order to use cached files across multiple sessions


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