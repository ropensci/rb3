
local_cachedir <- file.path(tempdir(), "rb3-cache")
withr::defer(unlink(local_cachedir, recursive = TRUE), teardown_env())

op <- options(rb3.cachedir = local_cachedir)
withr::defer(options(op), teardown_env())
