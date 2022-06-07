
devtools::load_all()
library(ggplot2)
library(stringr)
library(dplyr)
library(fixedincome)

df <- futures_get(
  first_date = "2021-01-01",
  last_date = Sys.Date(),
  by = 5,
  cache_folder = cache_folder
)

di1_futures <- df |>
  filter(commodity == "DI1") |>
  mutate(
    maturity_date = maturity2date(maturity_code),
    fixing = following(maturity_date, "Brazil/ANBIMA"),
    business_days = bizdays(refdate, maturity_date, "Brazil/ANBIMA"),
    adjusted_tax = rates("discrete", business_days / 252, 100000 / price)
  ) |>
  filter(business_days > 0)

di1_futures |>
  filter(symbol %in% c("DI1F23", "DI1F33")) |>
  ggplot(aes(x = refdate, y = adjusted_tax, color = symbol, group = symbol)) +
  geom_line() +
  geom_point() +
  labs(
    title = "DI1 Future Rates - Nominal Interest Rates",
    caption = str_glue("Data imported using rb3 at {Sys.Date()}"),
    x = "Date",
    y = "Interest Rates",
    color = "Symbol"
  ) +
  scale_y_continuous(labels = scales::percent)

dap_futures <- df |>
  filter(commodity == "DAP") |>
  mutate(
    maturity_date = maturity2date(maturity_code, "15th day"),
    fixing = following(maturity_date, "Brazil/ANBIMA"),
    business_days = bizdays(refdate, maturity_date, "Brazil/ANBIMA"),
    adjusted_tax = rates("discrete", business_days / 252, 100000 / price)
  ) |>
  filter(business_days > 0)

dap_futures |>
  filter(symbol %in% c("DAPF23", "DAPK35")) |>
  ggplot(aes(x = refdate, y = adjusted_tax, group = symbol, color = symbol)) +
  geom_line() +
  geom_point() +
  labs(
    title = "DAP Future Rates - Real Interest Rates",
    caption = str_glue("Data imported using rb3 at {Sys.Date()}"),
    x = "Date",
    y = "Interest Rates",
    color = "Symbol"
  ) +
  scale_y_continuous(labels = scales::percent)

# ----

forward_factor <- di1_futures |>
  filter(symbol %in% c("DI1F23", "DI1F33")) |>
  select(symbol, price, refdate) |>
  tidyr::spread(symbol, price) |>
  mutate(forward_factor = DI1F23 / DI1F33)

business_days <- di1_futures |>
  filter(symbol %in% c("DI1F23", "DI1F33")) |>
  select(symbol, business_days, refdate) |>
  tidyr::spread(symbol, business_days) |>
  mutate(business_days = DI1F33 - DI1F23)

forward_factor[["business_days"]] <- business_days[["business_days"]]

forward_rates <- forward_factor |>
  mutate(
    fwd_rate = rates("discrete", business_days / 252, forward_factor)
  )

# ----

infl_futures <- df |>
  filter(symbol %in% c("DI1F35", "DAPK35")) |>
  mutate(
    maturity_date = if_else(commodity == "DI1",
      maturity2date(maturity_code), maturity2date(maturity_code, "15th day")
    ),
    fixing = following(maturity_date, "Brazil/ANBIMA"),
    business_days = bizdays(refdate, maturity_date, "Brazil/ANBIMA"),
    adjusted_tax = rates("discrete", business_days / 252, 100000 / price)
  ) |>
  arrange(refdate)

infl_expec <- infl_futures |>
  select(symbol, price, refdate) |>
  tidyr::spread(symbol, price) |>
  mutate(inflation = DAPK35 / DI1F35 - 1)

infl_expec |>
  ggplot(aes(x = refdate, y = inflation)) +
  geom_line() +
  geom_point()