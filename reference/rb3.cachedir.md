# `rb3.cachedir` Option

The `rb3.cachedir` option is used to specify the directory where cached
data will be stored when using the `rb3` package. This option allows
users to define a custom directory for caching, which can improve
performance by avoiding repeated downloads or computations.

## Details

### Setting the `rb3.cachedir` Option

To set the `rb3.cachedir` option, use the
[`options()`](https://rdrr.io/r/base/options.html) function and provide
the desired directory path as a string. For example:

    # Set the cache directory to a custom path
    options(rb3.cachedir = "/path/to/your/cache/directory")

Replace `"/path/to/your/cache/directory"` with the actual path where you
want the cached data to be stored.

### Viewing the Current Value of `rb3.cachedir`

To check the current value of the `rb3.cachedir` option, use the
[`getOption()`](https://rdrr.io/r/base/options.html) function:

    # View the current cache directory
    getOption("rb3.cachedir")

This will return the path to the directory currently set for caching, or
`NULL` if the option has not been set.

### Notes

- Ensure that the specified directory exists and is writable.

- If the `rb3.cachedir` option is not set, the package use a temporary
  directory ([`base::tempdir()`](https://rdrr.io/r/base/tempfile.html)).

## Examples

``` r
# Set the cache directory
options(rb3.cachedir = "~/rb3_cache")

# Verify the cache directory
cache_dir <- getOption("rb3.cachedir")
print(cache_dir)
#> [1] "~/rb3_cache"

# In this example, the cache directory is set to `~/rb3_cache`, and the value 
# is then retrieved and printed to confirm the setting.
```
