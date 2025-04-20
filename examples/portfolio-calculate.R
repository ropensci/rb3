
library(rb3)
library(tidyverse)

# ----

symbols <- c(
  "ABEV3", "BBAS3", "B3SA3", "CIEL3", "EGIE3", "EZTC3", "INTB3", "ITSA4",
  "LREN3", "OIBR3", "PSSA3", "SBFG3", "WEGE3"
)

ch <- cotahist_get() |>
  filter(refdate >= "2021-12-01", refdate <= "2021-12-31", symbol %in% !!symbols) |>
  cotahist_filter_equity() |>
  collect()

pos <- c(1202, 400, 1500, 1000, 800, 800, 299, 1050, 776, 5000, 930, 200, 100)
names(pos) <- symbols
max_date <- max(ch$refdate)
symbols_ <- ch |>
  filter(refdate == max_date) |>
  pull(symbol)
closing <- ch |>
  filter(refdate == max_date) |>
  pull(close)
names(closing) <- symbols_

c1 <- (closing[symbols] * pos[symbols])
cbind(c1, pos)