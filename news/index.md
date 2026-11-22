# Changelog

## rb3 (development version)

- New function
  [`rb3_doctor()`](https://ropensci.github.io/rb3/reference/rb3_doctor.md)
  checks the health of the cache
  ([\#77](https://github.com/ropensci/rb3/issues/77)). With a template,
  it finds the gaps in the time series of a dataset layer (`input` or
  `staging`): the business days with no data, each with a reason (never
  fetched, download failed, not read, no data, or read but not in the
  layer), so missing dates can be fetched with
  [`fetch_marketdata()`](https://ropensci.github.io/rb3/reference/fetch_marketdata.md).
  It also reports stale download records (such as the old
  `b3-reference-rates` records with `curve_name`), records whose raw
  file is missing, and raw files that no record uses. It only reports
  and never changes the cache. See the new vignette “Checking the
  Cache”.

- Reading the download records is much faster
  ([`dget()`](https://rdrr.io/r/base/dput.html) on a text connection
  replaced by [`parse()`](https://rdrr.io/r/base/parse.html)).

- [`?yc_get`](https://ropensci.github.io/rb3/reference/yc_xxx_get.md)
  explains what to do with caches created before rb3 0.1.1, which still
  hold the old “Taxas Referenciais” HTML files of `b3-reference-rates`:
  they are no longer read, and the dates can be fetched again from the
  swap rates file ([\#144](https://github.com/ropensci/rb3/issues/144)).

- [`fetch_marketdata()`](https://ropensci.github.io/rb3/reference/fetch_marketdata.md)
  ends with a summary: how many files have data, and the arguments of
  every file whose download failed, that was not read, or that had no
  data ([\#86](https://github.com/ropensci/rb3/issues/86)). It now
  returns (invisibly) a tibble with `template`, `download_args` and
  `status` for each combination of arguments, instead of `NULL`.

- New template `b3-trade-information-consolidated`
  ([\#126](https://github.com/ropensci/rb3/issues/126)): B3’s
  TradeInformationConsolidated file, with every instrument of every
  segment (stocks, options, futures, forwards, …) and every column of
  the file (low, high, average and last price, oscillation, settlement
  price and rate, reference price, number of trades, contracts,
  financial volume). B3 keeps only the last ~360 sessions (about 17
  months): older dates get an empty file and are reported as failed
  downloads.

- [`fetch_marketdata()`](https://ropensci.github.io/rb3/reference/fetch_marketdata.md)
  now downloads again a file that had no usable data (reported as
  invalid) when it was downloaded less than 7 days after its `refdate`
  ([\#142](https://github.com/ropensci/rb3/issues/142)). For example,
  settlement prices downloaded before B3 published them are fetched
  again by the next call, instead of being lost. Files downloaded later
  are final and are not retried.

- [`fetch_marketdata()`](https://ropensci.github.io/rb3/reference/fetch_marketdata.md)
  now downloads again the current year’s file of `b3-cotahist-yearly`
  and `b3-indexes-historical-data` when the cached copy is from an
  earlier day ([\#143](https://github.com/ropensci/rb3/issues/143)). B3
  updates these files every session, so before this change the data
  stopped at the day of the first download. Past years are still
  downloaded only once. Templates opt in with
  `downloader.refresh-current-year: true`.

- An empty HTTP response (no `Content-Type` header) no longer stops
  [`fetch_marketdata()`](https://ropensci.github.io/rb3/reference/fetch_marketdata.md)
  with “Unknown error”; it is saved as an empty file and reported as a
  failed download.

## rb3 0.1.1

CRAN release: 2026-11-15

- `b3-reference-rates` now downloads B3’s “Taxas de Mercado para Swaps”
  file (`TS<yymmdd>.ex_` on the “Pesquisa por pregão” page) because the
  “Taxas Referenciais” page was discontinued
  ([\#125](https://github.com/ropensci/rb3/issues/125)). The
  `curve_name` argument is gone: one file holds every curve (about 120).
  The input layer schema changed (`refdate`, `curve_name`, `cur_days`,
  `biz_days`, `rate`, partitioned by `refdate`), so delete
  `<cachedir>/db/input/b3-reference-rates` and
  `<cachedir>/db/staging/b3-reference-rates` before fetching again.
  [`yc_brl_get()`](https://ropensci.github.io/rb3/reference/yc_xxx_get.md)
  now returns `NA` for `r_360`.
- `b3-futures-settlement-prices` now reads the “Consolidated trades of
  the session” table of the Daily Market Bulletin
  (<https://arquivos.b3.com.br/bdi/>) because the “Ajustes do pregão”
  page was discontinued
  ([\#125](https://github.com/ropensci/rb3/issues/125)). The bulletin
  keeps only about the last 21 sessions. Raw files of the old “Ajustes
  do pregão” HTML page already in the cache are still read, so
  `reprocess = TRUE` keeps the history back to 2000.
- New template `b3-bdi-derivatives-trades`: the same Daily Market
  Bulletin table used by `b3-futures-settlement-prices`, with every
  column (open, high, low, close, average and settlement prices, number
  of trades, contracts, financial volume, best bid/ask, …) and every
  instrument, options included. Like its source, it covers only about
  the last 21 sessions; use `b3-bvbg-086` for older dates.
  `b3-futures-settlement-prices` is unchanged.
- A download that returns an HTML page (B3 sends maintenance/error pages
  with status 200) is now a failed download when the template does not
  expect HTML, so the next
  [`fetch_marketdata()`](https://ropensci.github.io/rb3/reference/fetch_marketdata.md)
  tries that date again. Before, the page was saved, the meta was marked
  invalid and the date was never downloaded again.
- Zip archives are detected by content, so nested self-extracting
  archives such as B3’s `.ex_` files are unpacked; an empty archive is
  now reported as a failed download instead of stopping
  [`fetch_marketdata()`](https://ropensci.github.io/rb3/reference/fetch_marketdata.md).
- New function
  [`rb3_clear_cache()`](https://ropensci.github.io/rb3/reference/rb3_clear_cache.md)
  deletes all downloaded files, datasets and metadata in the cache
  folder, keeping the folders and the empty metadata table
  ([\#129](https://github.com/ropensci/rb3/issues/129)).
- [`rb3_bootstrap()`](https://ropensci.github.io/rb3/reference/rb3_bootstrap.md)
  closes the open metadata connection, so changing `rb3.cachedir` and
  calling it again uses the database of the new cache folder
  ([\#103](https://github.com/ropensci/rb3/issues/103)).
- Raw files are named by the md5 of their content, so several downloads
  can share one file. Cleaning a meta or downloading a file again no
  longer deletes a raw file that another meta still uses
  ([\#134](https://github.com/ropensci/rb3/issues/134),
  [\#140](https://github.com/ropensci/rb3/issues/140)).
- The documentation now says how far back each template’s source goes
  and how to keep the cache complete (table in the “Getting started”
  vignette and a “Data availability” section in each `*_get()` help
  page).

## rb3 0.1.0

CRAN release: 2025-07-07

- Introduced a new template framework that no longer uses `proto` and is
  fully adapted to downloader and reader functions.
- Added functionality to download and process futures settlement prices
  using the templates.
- Heavily refactored the codebase to improve readability and
  maintainability.
- Enhanced error handling and logging throughout the package.
- Improved the caching mechanism to ensure that files are stored in a
  structured manner within the cache directory.
  - The caching system now organizes files by template, making it easier
    to manage and retrieve cached data.
  - Uses `arrow` for efficient data storage and retrieval.
- Removed dependencies on `rvest`, `proto`, `ascii`, `readxl` and other
  packages that aren’t heavy used.
- Fixed test cases to align with the new template framework.
- Fixed issues with the `glue` environment list requiring explicit
  passing as an environment.
- Implemented registry as a singleton pattern.
- Removed the filename text match to find the templates.

## rb3 0.0.12

CRAN release: 2025-02-18

- Fix for glue / envir list having to be passed as environment
- Make vignettes fail gracefully

## rb3 0.0.11

CRAN release: 2024-07-13

- Check empty files download.

## rb3 0.0.10

CRAN release: 2023-04-14

- Improved error handling in `read_marketdata`.
- Improved checks in `test-company.R` with exception handling for empty
  downloaded files.
- Removed tidyselect warnings in `scraper-company.R`.

## rb3 0.0.9

CRAN release: 2023-03-24

- Corrected BUG: function `company_cash_dividends_get` does not return
  all cash dividends
- Implemented new option in templates: `verifyssl`. It defaults to TRUE,
  always use ssl, but when it is FALSE an option is set in httr to skip
  ssl verification.
- Corrected `futures_get` and `futures_mget` to handle equity futures

## rb3 0.0.8

CRAN release: 2023-03-05

- functions `company_cash_dividends_get`, `company_info_get`,
  `company_stock_dividends_get`, `company_subscriptions_get` to get
  company’s informations

## rb3 0.0.7

CRAN release: 2022-12-14

- function `index_get` to download historical data from B3 indexes
  (Issue [\#39](https://github.com/ropensci/rb3/issues/39))
- added option `rb3.silent` (defaults to `FALSE`) hide alert messages
  and progress bar
- added option `rb3.clear.cache` (defaults to `FALSE`) remove files with
  invalid content from cache folder
- new templates
  - `GetPortfolioDay_IndexStatistics` historical time series for B3
    indexes
- new vignette: B3 Indexes
- changed `futures_get` and `maturity2date` to use calendar `Brazil/BMF`
- `maturity2date` has a new argument refdate, it must be passed when
  converting old maturities like JAN0, FEV0, …

## rb3 0.0.6

CRAN release: 2022-08-19

- updated documentation
- functions `code2month` and `maturity2date` now accept old 4 characters
  maturity code, before 2006
- new function `cotahist_options_by_symbol_superset` joins options data,
  equity data and interest rates for each option for a given symbol
  (Issue [\#50](https://github.com/ropensci/rb3/issues/50))
- corrected BUG in cache system, avoid caching NULL returns (Issue
  [\#52](https://github.com/ropensci/rb3/issues/52))
- corrected BUG cdi_get and idi_get use do_cache = FALSE (Issue
  [\#51](https://github.com/ropensci/rb3/issues/51))

## rb3 0.0.5

CRAN release: 2022-07-16

- updated documentation
- the cache creates a folder with the template to organize files inside
  the cache folder.
- `read_marketdata` lost the argument `cachedir`, the RDS file with
  parsed data is saved in the directory of the given file.
  - Pass `do_cache = FALSE` to not save the RDS file, it defaults to
    `TRUE`.
- corrected BUG in `COTAHIST_YEARLY`, it uses cache wrongly (Issue
  [\#44](https://github.com/ropensci/rb3/issues/44))
- corrected BUG due to change in fixedincome - function `rates` was
  renamed to `implied_rate`

## rb3 0.0.4

CRAN release: 2022-06-22

- added locale `en` to templates: `COTAHIST_*`
- new templates
  - `NegociosIntraday` intraday listed market trades
  - `NegociosBalcao` intraday OTC (Debentures) trades
  - `NegociosBTB` intraday lending trades
- imports organized (using importFrom in NAMESPACE)
- added option `rb3.cachedir` to set default cache directory in order to
  use cached files across multiple sessions

## rb3 0.0.3

CRAN release: 2022-05-29

- fixed tests for yc_get().
- updated to bizdays version 0.1.10 (use of load_builtin_calendars -
  Issue [\#31](https://github.com/ropensci/rb3/issues/31)).
- changes to ropensci process: added more tests to improve test
  coverage, functions renamed, codemeta and Contributing.md.
- new templates
  - `GetStockIndex` to get the composition of B3 indexes.
  - `GetTheoricalPortfolio` to get composition and weights of B3
    indexes.
  - `GetPortfolioDay` to get composition, weights and segments of B3
    indexes.
  - `CenariosCurva` for scenarios of term structures of interest rates.
  - `CenariosPrecoReferencia` for reference prices scenarios.
  - `IndexReport` indexes daily market data.
  - `PriceReport` daily prices and market data.
  - `GetListedSupplementCompany` supplement data for listed companies.
  - `GetDetailsCompany` to get companies details (name, codeCVM, …).
  - `GetListedCashDividends` to get list of cash dividends.
- new functions for yield curves
  - `yc_ipca_get` and `yc_ipca_mget` for real interest rates
  - `yc_usd_get` and `yc_usd_mget` for USD interest rates in Brazil
- new functions for cotahist
  - `cotahist_get_symbols` to get stocks by a list of symbols
  - `cotahist_etfs_get`, `cotahist_fiis_get`, `cotahist_fidcs_get`,
    `cotahist_fiagros_get`
  - function `cotahist_funds_get` has been replaced by these ones.
- new functions to get indexes information (composition, weights and
  positions)
  - `index_comp_get` returns the index composition
  - `index_weights_get` returns the index weights
  - `index_by_segment_get` returns indexes assets grouped by segments
  - `indexes_get` lists the available indexes
  - `indexes_last_update` returns the date when the indexes have been
    updated
  - `indexreport_get` and `indexreport_mget` download index report data
- Superset datasets
  - `cotahist_equity_options_superset` joins options data, equity data
    and interest rates for each option - this is useful to run option
    and volatility models.
  - `yc_superset`, `yc_usd_superset`, `yc_ipca_superset` mark futures
    maturities in yield curve.

## rb3 0.0.2

CRAN release: 2022-05-10

- changes for ropensci process, replaced `sapply` with `purrr::map_xxx`.
- improved class Filename, added new methods.
- added argument `destdir = NULL` to `convert_to` function.
- created functions `yc_get` / `yc_mget` and `futures_get` /
  `futures_mget` (Issue
  [\#26](https://github.com/ropensci/rb3/issues/26)).
- improved `fields` creation (Issue
  [\#27](https://github.com/ropensci/rb3/issues/27)).
- added downloader/reader for `GetStockIndex`, JSON file with relations
  between stocks and indexes.

## rb3 0.0.1

CRAN release: 2022-05-05

- first release
