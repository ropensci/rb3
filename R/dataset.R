dbdir <- function() {
  file.path(cachedir(), "db")
}

dataset_get <- function(dataset_name) {
  path <- file.path(dbdir(), dataset_name)
  arrow::open_dataset(path)
}