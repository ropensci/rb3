# Read and parse raw market data files downloaded from the B3 website.

B3 provides various files containing valuable information about traded
assets on the exchange and over-the-counter (OTC) market. These files
include historical market data, trading data, and asset registration
data for stocks, derivatives, and indices. This function reads these
files and parses their content according to the specifications defined
in a template.

## Usage

``` r
read_marketdata(meta)
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

This function reads the downloaded file and parses its content according
to the specifications and schema defined in the template associated with
the `meta` object. The template specifies the file format, column
definitions, and data types.

The parsed data is then written to a partitioned dataset in Parquet
format, stored in a directory structure based on the template name and
data layer. This directory is located within the `db` subdirectory of
the `rb3.cachedir` directory. The partitioning scheme is also defined in
the template, allowing for efficient querying of the data using the
`arrow` package.

If an error occurs during file processing, the function issues a
warning, removes the downloaded file and its metadata, and returns
`NULL`.

## See also

[`list_templates`](https://ropensci.github.io/rb3/reference/list_templates.md)

[`rb3.cachedir`](https://ropensci.github.io/rb3/reference/rb3.cachedir.md)

[`download_marketdata`](https://ropensci.github.io/rb3/reference/download_marketdata.md)

## Examples

``` r
if (FALSE) { # \dontrun{
# Create metadata for daily market data
meta <- template_meta_create_or_load("b3-cotahist-daily",
  refdate = as.Date("2024-04-05")
)
# Download using the metadata
meta <- download_marketdata(meta)
meta <- read_marketdata(meta)

# For reference rates
meta <- template_meta_create_or_load("b3-reference-rates", refdate = as.Date("2024-04-05"))
# Download using the metadata
meta <- download_marketdata(meta)
meta <- read_marketdata(meta)
} # }
```
