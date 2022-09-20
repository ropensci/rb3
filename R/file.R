

Filename <- setRefClass("Filename",
  fields = list(name = "character"),
  methods = list(
    initialize = function(name) {
      .self$name <<- str_replace_all(name, "\\\\", "/")
    },
    getExt = function() {
      str_match(.self$name, "\\.[^.]+$")[1]
    },
    getFilenameSansExt = function() {
      str_match(.self$name, "(.*)\\.[^.]+$")[2]
    },
    changeExt = function(ext, destdir = NULL) {
      if (is.null(destdir)) {
        str_replace(.self$name, "\\.[^.]+$", ext)
      } else {
        n <- str_replace(.self$getBasename(), "\\.[^.]+$", ext)
        n <- file.path(destdir, n)
        str_replace_all(n, "\\\\", "/")
      }
    },
    getDirname = function() {
      dirname(.self$name)
    },
    getBasename = function() {
      basename(.self$name)
    },
    exists = function() {
      file.exists(.self$name)
    }
  )
)
