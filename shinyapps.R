
library(devtools)
devtools::install_github('rstudio/shinyapps')

shinyapps::setAccountInfo(name='quant-br', token='4276BE10F0B4A629C23F76219EEED085', secret='voXmb5K5Urfn85F0H1DSfyghDyXutLtkzxdIwMsa')

library(shinyapps)
shinyapps::deployApp('path/to/your/app')