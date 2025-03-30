
library(rb3)
library(tidyverse)


## check for missing points ----

date_range <- bdrs |>
  summarise(min = min(refdate), max = max(refdate)) |>
  collect()

chck_dts <- bizseq(date_range$min, date_range$max, "Brazil/B3")

chck_dts <- tibble(refdate = chck_dts)

bdrs |>
  filter(symbol == "AAPL34") |>
  full_join(chck_dts) |>
  arrange(refdate) |>
  pull(close, as_vector = TRUE) |>
  anyNA()

## check for missing points ----

date_range <- equities |>
  summarise(min = min(refdate), max = max(refdate)) |>
  collect()

chck_dts <- bizseq(date_range$min, date_range$max, "Brazil/B3")

chck_dts <- tibble(refdate = chck_dts)

equities |>
  filter(symbol == symbol_) |>
  full_join(chck_dts) |>
  arrange(refdate) |>
  pull(close, as_vector = TRUE) |>
  anyNA()
