yc_superset(yc_get("2025-02-28"), futures_get("2025-02-28", "DI1")) |> View()

f <- download_marketdata("b3-futures-settlement-prices", refdate = as.Date("2025-03-01"))
df <- read_marketdata(f)

f <- download_marketdata("b3-reference-rates", refdate = as.Date("2025-03-01"), curve_name = "PRE")
df <- read_marketdata(f)

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

f <- download_marketdata("b3-futures-settlement-prices", refdate = as.Date("2025-02-28"))
f <- download_marketdata("b3-cotahist-daily", refdate = as.Date("2025-02-28"))
f <- download_marketdata("b3-cotahist-yearly", year = 1990)
read_marketdata(f)
# f <- download_marketdata("COTAHIST_DAILY", refdate = as.Date("2025-02-28"))
# f <- download_marketdata("COTAHIST_DAILY", refdate = as.Date("2025-02-27"))
# f <- download_marketdata("COTAHIST_MONTHLY", month = "012025")
# f <- download_marketdata("COTAHIST_YEARLY", year = 1990)

# tpl <- template_retrieve("COTAHIST_YEARLY")
# tpl$parts$HistoricalPrices$fields
# df <- readr::read_fwf(f, readr::fwf_widths(
#   tpl$parts$HistoricalPrices$widths,
#   tpl$parts$HistoricalPrices$colnames
# ), skip = 1, col_types = "c")


for (year in 1990:2025) {
  cat(year, "\n")
  m <- download_marketdata("b3-cotahist-yearly", year = year)
  read_marketdata(m)
}

library(tidyverse)

sc <- arrow::schema(
  template = arrow::string(),
  download_checksum = arrow::string(),
  file_checksum = arrow::string(),
  download_args = arrow::string(),
  downloaded = arrow::string(),
  timestamp = arrow::timestamp(),
)

arrow::open_dataset(file.path(cachedir(), "meta"), schema = sc, format = "json") |>
  filter(template == "b3-cotahist-yearly") |>
  select(timestamp, downloaded) |>
  collect()

ds |>
  ggplot(aes(x = refdate, y = close)) +
  geom_line()
