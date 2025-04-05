library(rb3)
library(tidyverse)
library(bizdays)

fetch_marketdata("b3-indexes-current-portfolio", index = indexes_get())
process_marketdata("b3-indexes-current-portfolio", index = indexes_get())

template_dataset("b3-indexes-current-portfolio", layer = 2) |>
  filter(index == "SMLL", refdate == "2025-01-04") |>
  collect()

template_dataset("b3-indexes-current-portfolio", layer = 2) |>
  filter(index == "SMLL", refdate == "2025-01-04") |>
  collect() |>
  group_by(sector) |>
  summarise(weight = sum(weight, na.rm = TRUE)) |>
  arrange(sector) |>
  ggplot(aes(x = reorder(sector, weight), y = weight)) +
  geom_bar(stat = "identity") +
  coord_flip() +
  labs(x = NULL, y = "%") +
  scale_y_continuous(labels = scales::percent)

process_marketdata("b3-indexes-theorical-portfolio", index = indexes_get())

template_dataset("b3-indexes-theorical-portfolio", layer = 1) |>
  collect()
