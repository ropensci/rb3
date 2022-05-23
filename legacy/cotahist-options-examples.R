
library(tidyverse)

refdate <- Sys.Date() - 2

ch <- cotahist_get(refdate, "daily")
yc <- yc_get(refdate)

df <- cotahist_equity_options_superset(ch, yc)

close_underlying <- df |>
  filter(symbol.underlying == "PETR4", maturity_date == min(maturity_date)) |>
  pull(close.underlying)

maturities <- df |>
  filter(symbol.underlying == "PETR4") |>
  pull(maturity_date) |>
  unique() |>
  sort()

df |>
  filter(symbol.underlying == "PETR4", maturity_date %in% maturities[1:2]) |>
  ggplot(aes(
    x = strike, y = close, size = volume,
    group = maturity_date, color = factor(maturity_date)
  )) +
  geom_vline(
    xintercept = close_underlying[1], size = 1, color = "red", alpha = 0.25
  ) +
  geom_point(alpha = 0.5) +
  facet_grid(. ~ type)

# ----

g <- function(sigma, premium, type, spot, strike, time, rate, yield) {
  bsmprice(type, spot, strike, time, rate, yield, sigma) - premium
}

m1 <- df |>
  filter(
    symbol.underlying == "PETR4",
    maturity_date == maturities[1]
  ) |>
  arrange(strike)

time <- bizdays(m1$refdate, m1$maturity_date, "Brazil/ANBIMA") / 252
rate <- log(1 + m1$r_252)

ix <- g(
  1e-8, m1$close, m1$type, m1$close.underlying,
  m1$strike, time, rate, 0
) < 0

m1 <- m1[ix, ]

time <- bizdays(m1$refdate, m1$maturity_date, "Brazil/ANBIMA") / 252
rate <- log(1 + m1$r_252)

m1$sigma <- multiroot(
  g, c(1e-8, 10),
  m1$close, m1$type, m1$close.underlying, m1$strike, time, rate, 0
)$root

m1$delta <- ifelse(
  m1$type == "Call",
  bsmdelta(
    "call", m1$close.underlying, m1$strike, time, rate, 0, m1$sigma
  ),
  1 + bsmdelta(
    "put", m1$close.underlying, m1$strike, time, rate, 0, m1$sigma
  )
)

m1 |>
  ggplot(aes(x = strike, y = sigma, size = volume, color = type)) +
  geom_vline(
    xintercept = close_underlying[1], size = 1, color = "blue", alpha = 0.25
  ) +
  geom_point(alpha = 0.5)

m1 |>
  ggplot(aes(x = delta, y = sigma, size = volume, color = type)) +
  geom_point(alpha = 0.5)