# Download Raw Market Data Files from B3

Downloads and caches financial market datasets from B3 (Brazilian Stock
Exchange) based on predefined templates. Handles file downloading and
caching.

## Usage

``` r
download_marketdata(meta)
```

## Arguments

- meta:

  A metadata object.

## Value

Returns a meta object containing the downloaded file's metadata:

- template - Name of the template used

- download_checksum - Unique hash code for the download

- download_args - Arguments used for the download

- downloaded - Path to the downloaded file

- created - Timestamp of file creation

- is_downloaded - Whether the file was successfully downloaded

- is_processed - Whether the file was successfully processed

- is_valid - Whether the file is valid

The `meta` object can be interpreted as a ticket for the download
process. It contains all the necessary information to identify the data,
if it has been downloaded, if it has been processed, and ince it is
processed, if the downloaded file is valid.

## Details

The function follows this workflow:

1.  Checks if requested data exists in cache

2.  Downloads data if needed (based on template specifications)

3.  Manages file compression and storage

4.  Maintains metadata for tracking and verification

Files are organized in the `rb3.cachedir` as follows:

- Data: Gzipped files in 'raw/' directory, named by file's checksum

Templates are YAML documents that define:

- Download parameters and methods

- Data reading instructions

- Dataset structure (columns, types)

Templates can be found using
[`list_templates()`](https://ropensci.github.io/rb3/reference/list_templates.md)
and retrieved with
[`template_retrieve()`](https://ropensci.github.io/rb3/reference/template_retrieve.md).

## See also

- [`template_meta_create_or_load`](https://ropensci.github.io/rb3/reference/template_meta_create_or_load.md)
  for creating a metadata object

- [`list_templates`](https://ropensci.github.io/rb3/reference/list_templates.md)
  for listing available data templates

- [`template_retrieve`](https://ropensci.github.io/rb3/reference/template_retrieve.md)
  for retrieving specific template details

[`read_marketdata`](https://ropensci.github.io/rb3/reference/read_marketdata.md),
[`rb3.cachedir`](https://ropensci.github.io/rb3/reference/rb3.cachedir.md)

## Examples

``` r
if (FALSE) { # \dontrun{
# Create metadata for daily market data
meta <- template_meta_create_or_load("b3-cotahist-daily",
  refdate = as.Date("2024-04-05")
)
# Download using the metadata
meta <- download_marketdata(meta)

# For reference rates
meta <- template_meta_create_or_load("b3-reference-rates", refdate = as.Date("2024-04-05"))
# Download using the metadata
meta <- download_marketdata(meta)
} # }
```
