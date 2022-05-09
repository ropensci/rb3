# rb3 0.0.1.9000

* changes for ropensci process, replaced `sapply` with `purrr::map_xxx`.
* improved class Filename, added new methods.
* added argument `destdir = NULL` to `convert_to` function.
* created functions `yc_get` / `yc_mget` and `futures_get` / `futures_mget` (Issue #26).
* improved `fields` creation (Issue #27).
* added downloader/reader for `GetStockIndex`, JSON file with relations between stocks and indexes.

# rb3 0.0.1

* first release