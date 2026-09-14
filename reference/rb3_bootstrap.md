# Initialize the rb3 package cache folders

This function sets up the necessary directory structure for caching rb3
data. It creates a main cache folder and three subfolders: 'raw',
'meta', and 'db'. The folder paths are stored in the rb3 registry for
later use.

## Usage

``` r
rb3_bootstrap()
```

## Details

The function first checks if the 'rb3.cachedir' option is set. If not,
it uses a subfolder in the temporary directory. It creates the main
cache folder and the three subfolders if they don't already exist, then
stores their paths in the rb3 registry.

The cache structure includes:

- raw folder - for storing raw downloaded data

- db folder - for database files

## Examples

``` r
if (FALSE) { # \dontrun{
options(rb3.cachedir = "~/rb3-cache")
rb3_bootstrap()
} # }
```
