# Access a Dataset for a Template

This function provides access to a dataset associated with a specific
template. It retrieves the dataset stored in the database folder for the
given template and layer, using the schema defined in the template
configuration.

## Usage

``` r
template_dataset(template, layer = NULL)
```

## Arguments

- template:

  The template identifier or template object. This specifies the dataset
  to retrieve.

- layer:

  The layer of the dataset to access (e.g., "input" or "staging"). If
  `NULL`, the layer `"input` is used.

## Value

An Arrow dataset object representing the data for the specified template
and layer.

## Details

The `template_dataset()` function is a generic function that dispatches
to specific methods based on the type of the `template` argument. It
retrieves the dataset by resolving the template using
[`template_retrieve()`](https://ropensci.github.io/rb3/reference/template_retrieve.md)
if the input is a template identifier.

## Examples

``` r
if (FALSE) { # \dontrun{
# Access the dataset for the "b3-reference-rates" template
ds <- template_dataset("b3-reference-rates")

# Access the dataset for the "b3-reference-rates" template in the staging layer
ds <- template_dataset("b3-reference-rates", layer = "staging")

# Query the dataset
ds |>
  dplyr::filter(refdate > as.Date("2023-01-01")) |>
  dplyr::collect()
} # }
```
