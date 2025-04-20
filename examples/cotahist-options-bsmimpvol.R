library(rb3)
library(tidyverse)
library(bizdays)
library(oplib)
library(RQuantLib)

refdate <- as.Date("2025-04-15")

df <- cotahist_options_by_symbols_get("VALE3") |>
  filter(refdate == !!refdate) |>
  collect()

close_underlying <- df |>
  filter(maturity_date == min(maturity_date)) |>
  pull(close_underlying) |>
  unique()

maturities <- df |>
  filter(!stringr::str_detect(symbol, "W\\d")) |>
  pull(maturity_date) |>
  unique() |>
  sort()

df |>
  filter(maturity_date %in% maturities[1:2]) |>
  ggplot(aes(
    x = strike_price, y = close, linewidth = volume,
    group = maturity_date, color = factor(maturity_date)
  )) +
  geom_vline(
    xintercept = close_underlying, linewidth = 1, color = "red", alpha = 0.25
  ) +
  geom_point(alpha = 0.5) +
  facet_grid(. ~ type)

# ----

bsmimpvol_ql <- Vectorize(function(
    price, type, spot, strike, time, rate, yield) {
  r <- try(EuropeanOptionImpliedVolatility(
    type, price, spot, strike, 0, rate, time, 0.2
  ), silent = TRUE)
  if (inherits(r, "try-error")) {
    return(NA_real_)
  }
  as.numeric(r)
}, vectorize.args = c("price", "type", "spot", "strike", "time", "rate", "yield"))

df_vol <- df |>
  filter(maturity_date %in% maturities[2]) |>
  mutate(
    sigma = bsmimpvol(
      close, type, close_underlying, strike_price, bizdays(refdate, maturity_date, "Brazil/ANBIMA") / 252, log(1 + r_252), 0
    ),
    # sigma = bsmimpvol_ql(
    #   close, type, close_underlying, strike_price, bizdays(refdate, maturity_date, "Brazil/ANBIMA") / 252, log(1 + r_252), 0
    # ),
    moneyness = bsmmoneyness(
      close_underlying, strike_price, bizdays(refdate, maturity_date, "Brazil/ANBIMA") / 252, log(1 + r_252), 0
    ),
    delta = bsmdelta(
      type, close_underlying, strike_price, bizdays(refdate, maturity_date, "Brazil/ANBIMA") / 252, log(1 + r_252), 0, sigma
    ),
  ) |>
  filter(!is.na(sigma))

df_vol |>
  ggplot(aes(x = strike_price, y = sigma, size = volume, color = type)) +
  geom_vline(
    xintercept = close_underlying, size = 1, color = "blue", alpha = 0.25
  ) +
  geom_point(alpha = 0.5)

df_vol |>
  ggplot(aes(x = moneyness, y = sigma, size = volume, color = type)) +
  geom_vline(
    xintercept = 0, size = 1, color = "blue", alpha = 0.25
  ) +
  geom_point(alpha = 0.5)

df_vol |>
  mutate(delta = ifelse(delta < 0, 1 + delta, delta)) |>
  ggplot(aes(x = delta, y = sigma, size = volume, color = type)) +
  geom_vline(
    xintercept = 0.5, size = 1, color = "blue", alpha = 0.25
  ) +
  geom_point(alpha = 0.5)

df_vol |>
  filter(type == "call") |>
  ggplot(aes(x = strike_price, y = delta)) +
  geom_point() +
  geom_vline(
    xintercept = close_underlying, size = 1, color = "blue", alpha = 0.25
  )
