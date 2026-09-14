# Returns a SQLite Database Connection for the RB3 Package Metadata

This function provides a consistent way to connect to the SQLite
database used for RB3 package metadata. It returns an existing
connection if one is already established and valid, or creates a new
connection if needed.

## Usage

``` r
meta_db_connection()
```

## Value

A SQLite connection object for metadata storage

## Details

The function first checks if a valid connection already exists in the
package registry. If not, it establishes a new connection to a SQLite
database located in the configured database folder and stores this
connection in the package registry.

## Examples

``` r
# Get a connection to the RB3 metadata database
con <- meta_db_connection()
```
