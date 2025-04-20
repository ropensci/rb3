
library(rb3)
library(dplyr)
library(stringr)

ch <- cotahist_get() |>
  filter(refdate == "2025-04-15") |>
  collect()

ch_fm <- ch |>
  filter(instrument_market %in% c(70, 80)) |>
  mutate(FM = str_detect(corporation_name, "\\bFM\\b"))

ch_fm |>
  filter(FM)
