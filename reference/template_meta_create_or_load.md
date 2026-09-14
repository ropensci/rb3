# Create or Load Template Metadata

These functions attempt to create new template metadata objects or load
existing ones.

## Usage

``` r
template_meta_load(template, ...)

template_meta_new(template, ...)

template_meta_create_or_load(template_name, ...)
```

## Arguments

- template:

  An object representing the template. Can be of class `character`
  (template ID) or `template` (template object).

- ...:

  Additional arguments to be passed to the metadata creation process.
  These should include all required arguments specified in the template
  definition.

- template_name:

  Character string specifying the template ID.

## Value

The created or loaded template metadata object

## Details

The `template_meta_load` function checks that all required arguments for
the template are provided. If any required arguments are missing, it
will abort with an error of class "error_template_missing_args". It
raises an error if the template is not found or if the required
arguments are not provided. The error message will indicate which
arguments are missing.

The `template_meta_new` function checks that all required arguments for
the template are provided. If any required arguments are missing, it
will abort with an error of class "error_template_missing_args". It
raises an error if the template already exists in the database.

The `template_meta_create_or_load` function is a safe way to create or
load template metadata. It first attempts to create a new metadata
object using the provided arguments. If that fails (e.g., if the
template already exists), it will attempt to load the existing metadata
object. This is useful for ensuring that you always have access to the
latest metadata for a given template.

## Examples

``` r
if (FALSE) { # \dontrun{
# Create or load metadata for a template
meta <- template_meta_create_or_load("b3-reference-rates", refdate = as.Date("2024-04-05"))
} # }
```
