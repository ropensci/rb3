
library(rbcb)
library(tidyverse)

ser <- get_series(c(
  IPCA = 433, IGPM = 189, INPC = 188, IGPDI = 190, INCC = 192
))

ser$INCC |>
  inner_join(ser$IGPDI, by = "date") |>
  arrange(date) |>
  mutate(
    IGPDI = cumprod(1 + IGPDI / 100),
    INCC = cumprod(1 + INCC / 100)
  ) |>
  ggplot() +
  geom_line(aes(x = date, y = IGPDI, colour = "IGPDI")) +
  geom_line(aes(x = date, y = INCC, colour = "INCC")) +
  labs(colour = NULL) +
  scale_y_log10(labels = scales::number_format())
# scale_y_continuous(labels = scales::number_format())