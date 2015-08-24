

Filename <- setRefClass("Filename",
  fields=list(name="character"),
  methods=list(
    getExt=function() {
      str_match(.self$name, '\\.[^.]+$')[1]
    },
    getBasename=function() {
      str_match(.self$name, '(.*)\\.[^.]+$')[2]
    },
    changeExt=function(ext) {
      str_replace(.self$name, '\\.[^.]+$', paste0('.', ext))
    }
  )
)

# CSVFile <- setRefClass("CSVFile",
#   methods=list(
#     write=function(filename, dialect) {
#       if (dialect == 'en-US') {
#
#       } else if (dialect == 'pt-BR') {
#
#       } else
#         stop(paste('Invalid dialect:', dialect))
#     }
#   )
# )