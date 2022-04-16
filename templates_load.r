
devtools::load_all()
library(yaml)


tpl <- yaml.load_file("./inst/extdata/templates/COTAHIST.yaml")
obj <- new_template(tpl)
obj$ls()
df <- read_marketdata("./inst/extdata/COTAHIST_D04012016.TXT", template = "COTAHIST")

df$Header

show_templates()