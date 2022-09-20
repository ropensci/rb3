library(stringr)
library(proto)

copy_file_to_temp <- function(f_name) {
  folder <- tempdir()
  f_dest <- file.path(folder, basename(f_name))
  if (file.copy(f_name, f_dest, overwrite = TRUE)) {
    f_dest
  } else {
    stop("Can't copy file to tempdir")
  }
}
