# Napkin Runbook

## Curation Rules
- Re-prioritize on every read.
- Keep recurring, high-value notes only.
- Max 10 items per category.
- Each item includes date + "Do instead".

## Execution & Validation (Highest Priority)
1. **[2026-09-14] Most tests need network; NOT_CRAN=true is set in .Renviron**
   Do instead: run offline-safe files first (`test-template.R`, `test-fields.R`, `test-types.R`, `test-meta.R`, `test-registry.R`); expect `skip_if_offline()` skips elsewhere.
2. **[2026-09-14] New R file is silently ignored unless listed in DESCRIPTION `Collate:`**
   Do instead: add the file to `Collate:` and run `devtools::document()`.

## Shell & Command Reliability
1. **[2026-09-14] Large `cat` of several R files overflows tool output**
   Do instead: `grep -v "^#'"` to strip roxygen, or read one file at a time.

## Domain Behavior Guardrails
1. **[2026-09-14] YAML template `function:` names resolve via `getFromNamespace(..., "rb3")`**
   Do instead: when renaming a downloader/reader/process function, grep `inst/extdata/templates/*.yaml` and `tests/testthat/testdata/*.yaml` too.
2. **[2026-09-14] `rb3.cachedir` is read at attach time**
   Do instead: set `options(rb3.cachedir=...)` before `library(rb3)` or call `rb3_bootstrap()` after changing it.

## User Directives
1. **[2026-09-14] Reply in simple English (C1), explain jargon briefly, note English mistakes lightly**
   Do instead: follow ~/.claude/CLAUDE.md communication style.
