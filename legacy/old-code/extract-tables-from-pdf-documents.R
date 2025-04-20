
# Sys.setenv(JAVA_HOME = "C:\\Program Files (x86)\\Java\\jre1.8.0_333")

url_pdf <- "https://www.b3.com.br/data/files/48/56/93/D5/96E615107623A41592D828A8/SERIE-RETROATIVA-DO-IBOV-METODOLOGIA-VALIDA-A-PARTIR-09-2013.pdf"

pdf_tables <- tabulizer::extract_tables(url_pdf, pages = seq(62, 77))

library(tidyverse)
library(janitor)

pdf_tables[[1]] %>%
  as_tibble(.name_repair = "unique") %>%
  row_to_names(1) %>%
  clean_names() %>%
  pivot_longer(tidyselect::contains("_20"),
    names_to = c("mes")
  )