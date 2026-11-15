## Submission

This is a patch release. B3 (the Brazilian exchange) discontinued two web pages used by the
`b3-reference-rates` and `b3-futures-settlement-prices` templates, so these downloads stopped working
in rb3 0.1.0. This version reads the new B3 sources and also fixes a few cache bugs (see NEWS.md).

## R CMD check results

0 errors | 0 warnings | 0 notes

* Local: Ubuntu, R release.
* GitHub Actions: macOS (release), Windows (release), Ubuntu (devel, release, oldrel-1).
* win-builder: R-devel.

## Notes

* Examples that download data from B3 are wrapped in `\dontrun{}`, and the tests that need the
  internet are skipped on CRAN.
