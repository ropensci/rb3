
ch <- cotahist_get(Sys.Date() - 1, "daily")

ch$HistoricalPrices |>
  filter(tipo_mercado %in% c(70, 80)) |>
  distinct(nome_empresa) |>
  mutate(FM = str_detect(nome_empresa, "\\bFM\\b"))

ch$HistoricalPrices |>
  filter(tipo_mercado %in% c(70, 80)) |>
  head()

f <- download_marketdata("COTAHIST_DAILY", refdate = Sys.Date() - 1)
ch <- read_marketdata(f, "COTAHIST_DAILY", parse_fields = TRUE)