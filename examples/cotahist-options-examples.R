library(tidyverse)
library(bizdays)
library(oplib)

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
    x = strike, y = close, linewidth = volume,
    group = maturity_date, color = factor(maturity_date)
  )) +
  geom_vline(
    xintercept = close_underlying[1], linewidth = 1, color = "red", alpha = 0.25
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



cotahist_get_options_by_symbols <- function(symbols) {
  ch <- cotahist_get()
  yc <- yc_brl_get() |> select("refdate", "forward_date", "r_252")

  eqs <- ch |>
    filter(.data$symbol %in% symbols) |>
    select("refdate", "symbol", "close", "isin")

  eqs_opts <- ch |>
    filter(.data$instrument_market %in% c(70, 80)) |>
    select("refdate", "symbol", "strike_price", "maturity_date", "close", "volume", "isin", "instrument_market")

  eq <- inner_join(eqs_opts, eqs,
    by = c("refdate", "isin"), suffix = c("", "_underlying"), relationship = "many-to-one"
  )
  ds <- inner_join(eq, yc, by = c("refdate" = "refdate", "maturity_date" = "forward_date"))

  ds |>
    mutate(type = ifelse(.data$instrument_market == 80, "call", "put")) |>
    select(
      "refdate",
      "symbol_underlying",
      "close_underlying",
      "symbol",
      "type",
      "strike_price",
      "maturity_date",
      "close",
      "volume",
      "r_252",
    )
}

cotahist_get_options_by_symbols("PETR4") |>
  filter(refdate == "2024-01-02") |>
  collect()

cotahist_get_instrument_by_symbol <- function(symbol) {
  .symbol <- symbol
  ch <- cotahist_get()

  im <- ch |>
    filter(.data$symbol == .symbol) |>
    dplyr::distinct(instrument_market) |>
    collect() |>
    dplyr::pull()

  if (length(im) == 0) {
    stop("Can't find given instrument")
  }
  ds <- if (im %in% c(70, 80)) {
    ch |>
      filter(.data$symbol == .symbol) |>
      mutate(type = ifelse(.data$instrument_market == 80, "call", "put")) |>
      select("refdate", "symbol", "type", "strike_price", "maturity_date", "close", "volume", "isin")
  } else {
    ch |>
      filter(.data$symbol == .symbol) |>
      select("refdate", "symbol", "close", "isin")
  }
  ds |> arrange(.data$refdate)
}

cotahist_get_instrument_by_symbol("PETRM217") |> collect()
