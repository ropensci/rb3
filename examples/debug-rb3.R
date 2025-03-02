# devtools::load_all()

# # debugonce(url_encoded_download)
# single_index_get("IBOV", 1980, cachedir(), TRUE)

# x <- index_get("IBXL", as.Date("1980-01-01"), Sys.Date(), cachedir(), TRUE)
# x <- index_get("IBXX", as.Date("1980-01-01"), Sys.Date(), cachedir(), TRUE)

# library(plotly)
# library(tidyverse)

# x |>
#   # filter(refdate >= as.Date("2024-01-01")) |>
#   ggplot(aes(x = refdate, y = value)) +
#   geom_line()
# # + scale_y_continuous(trans = "log10")

f_txt <- system.file("extdata/BD_Arbit.txt", package = "rb3")
f_txt <- copy_file_to_temp(f_txt)

df <- read_marketdata(f_txt, template = "BD_Arbit")
