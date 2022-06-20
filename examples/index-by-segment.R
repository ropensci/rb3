
library(rb3)
library(tidyverse)
library(bizdays)

df <- index_by_segment_get("SMLL")
df |>
  distinct(segment, segment_weight) |>
  ggplot(aes(x = reorder(segment, segment_weight), y = segment_weight)) +
  geom_bar(stat = "identity") +
  coord_flip() +
  labs(x = NULL, y = "%") +
  scale_y_continuous(labels = scales::percent)