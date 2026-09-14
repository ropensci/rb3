# Napkin Runbook

## Curation Rules
- Re-prioritize on every read.
- Keep recurring, high-value notes only.
- Max 10 items per category.
- Each item includes date + "Do instead".

## Execution & Validation (Highest Priority)
1. **[2026-09-14] `devtools::load_all()` fails if `vcr` is missing (helper-vcr.R does `library(vcr)`)**
   Do instead: `pkgload::load_all(helpers = FALSE)` for ad-hoc scripts; `install.packages("vcr")` before `devtools::test()`.
2. **[2026-09-14] Most tests need network; NOT_CRAN=true is set in .Renviron**
   Do instead: run offline-safe files first (`test-readers.R`, `test-template.R`, `test-fields.R`, `test-types.R`, `test-meta.R`, `test-registry.R`); `devtools::test(filter = "yc|futures")` for the rest. `setup.R` redirects the cache to a temp dir, the real `~/R/rb3-cache` is untouched.
3. **[2026-09-14] New R file is silently ignored unless listed in DESCRIPTION `Collate:`**
   Do instead: add the file to `Collate:` and run `devtools::document()`.
4. **[2026-09-14] `devtools::document()` bumps `RoxygenNote` in DESCRIPTION and regenerates unrelated Rd/NAMESPACE entries**
   Do instead: `git checkout DESCRIPTION` after documenting unless the bump is wanted; review `git status` for stray man/ changes.

## Shell & Command Reliability
1. **[2026-09-14] R sources use CRLF line endings; python/sed edits must preserve them**
   Do instead: read with `newline=''`, detect `\r\n`, normalise, edit, restore before writing.
2. **[2026-09-14] `gh` and the GitHub MCP fail on ropensci/rb3 (org rejects the long-lived fine-grained token)**
   Do instead: `curl -s https://api.github.com/repos/ropensci/rb3/issues/<n>` (unauthenticated) to read issues/comments.
3. **[2026-09-14] Large `cat` of several R files overflows tool output**
   Do instead: `grep -v "^#'"` to strip roxygen, or read one file at a time.

## Domain Behavior Guardrails
1. **[2026-09-14] B3 killed the www2.bmf.com.br pages (taxas referenciais, ajustes do pregão)**
   Do instead: reference rates = `pesquisapregao/download?filelist=TS%y%m%d.ex_` (zip > self-extracting `.ex_` > `TaxaSwap.txt`, fixed width, history since 2005); settlement prices = BDM `POST arquivos.b3.com.br/bdi/table/export/csv?lang=en-us` with JSON `{Name:"ConsolidatedTradesDerivatives",Date,FinalDate}` (only ~21 last sessions; `b3-bvbg-086` PR files since 2020 for backfill).
2. **[2026-09-14] B3 returns HTTP 200 with an empty zip (22 bytes) or "No results found" CSV on non-trading days**
   Do instead: expect `is_downloaded = FALSE` (empty zip) or `is_valid = FALSE` (empty CSV); never treat 200 as "data exists".
3. **[2026-09-14] YAML template `function:` names resolve via `getFromNamespace(..., "rb3")`**
   Do instead: when renaming a downloader/reader/process function, grep `inst/extdata/templates/*.yaml` and `tests/testthat/testdata/*.yaml` too.
4. **[2026-09-14] Arrow `write_dataset` refuses > 1024 partitions; a misparsed partition column explodes silently into thousands**
   Do instead: check `length(unique(col))` of the partition column before blaming arrow; it is usually a reader alignment bug.
5. **[2026-09-14] `rb3.cachedir` is read at attach time**
   Do instead: set `options(rb3.cachedir=...)` before `library(rb3)` or call `rb3_bootstrap()` after changing it.

## User Directives
1. **[2026-09-14] Reply in simple English (C1), explain jargon briefly, note English mistakes lightly**
   Do instead: follow ~/.claude/CLAUDE.md communication style.
