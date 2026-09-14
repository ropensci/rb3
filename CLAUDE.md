# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

`rb3` is an R package (rOpenSci, CRAN) that downloads public market data from B3 (Brazilian exchange), parses it, and stores it as Arrow/Parquet datasets in a local cache. Package version 0.1.0 is a full rewrite around a YAML template framework; `legacy/` holds the old code and is excluded from the build.

## Commands

All development goes through `devtools` from the repo root:

```r
devtools::load_all()          # load package for interactive work
devtools::document()          # regenerate NAMESPACE and man/ from roxygen (run after changing exports/docs)
devtools::test()              # run all tests
testthat::test_file("tests/testthat/test-futures.R")   # run one test file
devtools::check()             # full R CMD check; aim for 0 errors/warnings (CI runs this on 5 platforms)
```

Shell equivalents: `Rscript -e 'devtools::test()'`, etc.

Docs and site (`Makefile`):

```sh
make            # README.R -> README.RData -> README.md (README.md is generated; edit README.Rmd)
make site       # pkgdown site
make vignettes  # runs vignettes/save_*.R to build data_*.RData, then renders the .Rmd files
```

### Test setup gotchas

- `.Renviron` sets `NOT_CRAN=true`, so `skip_on_cran()` does not skip locally. Most test files hit the B3 website and are guarded by `skip_if_offline()`. Some use `vcr` cassettes in `tests/fixtures/`.
- `tests/testthat/setup.R` points `rb3.cachedir` at a temp folder, silences `cli`, and loads extra test-only templates from `tests/testthat/testdata/*.yaml` into the same registry as the built-in ones.
- Test helpers: `helper-help.R` (`copy_file_to_temp`) and `helper-vcr.R`.

## Architecture

### Template-driven pipeline

Every data source is a YAML file in `inst/extdata/templates/` (id, downloader, reader, writers, fields). At `library(rb3)` (`.onAttach` in `R/zzz.R`), `load_template_files()` parses each YAML into a `template` object and stores it in the `template_registry` singleton (`R/registry.R`). Function names inside the YAML (`downloader.function`, `reader.function`, `writers.staging.function`) are resolved with `getFromNamespace(..., "rb3")`, so they must be real functions in this package:

- downloaders live in `R/downloaders.R` (`datetime_download`, `sprintf_download`, `curve_download`, `settlement_prices_download`, `stock_indexes_*_download`, ...)
- readers live in `R/readers.R` (`fwf_read_file`, `csv_read_file`, `curve_read`, `settlement_prices_read`, `stock_indexes_json_reader`, `pricereport_reader`)
- staging processors and public `*_get()` accessors live in `R/scraper-*.R` (`process_cotahist`, `process_futures`, `process_yc`, `process_indexes_*`)

If a template has no `reader`, the reader is derived from `filetype` (`<filetype>_read_file`). Field `type` strings such as `date(format="%d/%m/%Y")` are parsed by `type_parse()` against `VALID_TYPES` in `R/types.R`; `R/fields.R` turns fields into readr collectors, Arrow schemas and fixed widths.

**Adding a data source** therefore means: a YAML template, a downloader function, a reader function, optionally a staging `process_*` function, and a `*_get()` accessor. `R/template.R` handles loading, `template_retrieve()`, `template_schema()`, `template_db_folder()` and `template_dataset()`.

### fetch -> download -> read -> staging

`fetch_marketdata(template, ...)` (`R/fetch-marketdata.R`) is the user entry point:

1. `expand.grid(...)` of the arguments gives one `meta` per combination (`create_meta_list`).
2. `download_market_files` calls `download_marketdata(meta)` (`R/download-marketdata.R`) for each meta not yet downloaded (or when `force_download = TRUE`). The file is unzipped if needed, gzipped, and stored as `<cachedir>/raw/<md5>.gz`.
3. `process_input_layer` calls `read_marketdata(meta)` (`R/read-marketdata.R`), which runs the template reader and writes an Arrow dataset to `<cachedir>/db/input/<template-id>/`, partitioned per `writers.input.partition`.
4. If the template has a `writers.staging` block and the input layer changed (or `reprocess = TRUE`), `create_staging_layer` opens the input dataset, applies the staging `process_*` function, and writes `<cachedir>/db/staging/<template-id>/`.

`*_get()` accessors call `template_dataset(template, layer)` and return a lazy `arrow` dataset; callers filter with dplyr and `collect()`.

### meta: the download ticket

`R/meta.R` stores one row per (template, download args, extra_arg) in `<cachedir>/meta.sqlite`. The primary key `download_checksum` is a `digest` of those values. Flags `is_downloaded`, `is_processed`, `is_valid` drive skipping in `fetch_marketdata`. Every `meta_set_*<-` / `meta_add_download<-` call writes through to SQLite immediately. `template_meta_create_or_load()` is the normal way to obtain a meta.

### Cache directory and registries

`rb3_bootstrap()` (`R/rb3-package.R`) reads `getOption("rb3.cachedir")` (falls back to `tempdir()`), creates `raw/` and `db/`, and stores the paths in the `rb3_registry` singleton. It runs at attach time, so users must set `options(rb3.cachedir = ...)` **before** `library(rb3)`. Registries are S3 objects that support `$` / `[[` get and set (`R/registry.R`).

## Conventions

- `DESCRIPTION` has an explicit `Collate:` list. A new `R/*.R` file must be added there or it will not be sourced by `R CMD build`.
- Roxygen with markdown; `NAMESPACE` and `man/` are generated, never hand-edited.
- User-facing messages use `cli`; errors carry classes (`error_download_fail`, `error_meta_not_found`, `error_template_missing_args`, ...) that callers catch with `tryCatch`/`inherits`.
- `examples/`, `legacy/`, `b3-docs/`, `pkgdown/` and the root `*.md` overview files (`PROJECT_OVERVIEW.md`, `ARCHITECTURE_DIAGRAMS.md`, `QUICK_REFERENCE.md`, `DOCUMENTATION_INDEX.md`) are excluded from the package build via `.Rbuildignore`; the overview files are generated summaries, not the source of truth.
- Business-day calendars come from `bizdays` (`"Brazil/ANBIMA"`, `"Brazil/BMF"`, `"Brazil/B3"`); futures maturity codes are decoded by `maturitycode2date()` / `code2month()` in `R/scraper-futures.R`.
