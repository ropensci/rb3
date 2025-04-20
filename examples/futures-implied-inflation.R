
library(rb3)
library(ggplot2)
library(dplyr)
library(fixedincome)
library(bizdays)

df <- futures_get() |>
  filter(commodity %in% c("DI1", "DAP"), refdate >= "2023-01-01") |>
  collect()

di1_futures <- df |>
  filter(commodity == "DI1") |>
  mutate(
    maturity_date = maturity2date(maturity_code),
    fixing = following(maturity_date, "Brazil/ANBIMA"),
    business_days = bizdays(refdate, maturity_date, "Brazil/ANBIMA"),
    adjusted_tax = implied_rate("discrete", business_days / 252, 100000 / price)
  ) |>
  filter(business_days > 0)

di1_futures |>
  filter(symbol == "DI1F35") |>
  ggplot(aes(x = refdate, y = adjusted_tax, color = symbol, group = symbol)) +
  geom_line() +
  geom_point() +
  labs(
    title = "DI1 Future Rates - Nominal Interest Rates",
    caption = stringr::str_glue("Data imported using rb3 at {Sys.Date()}"),
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
    adjusted_tax = implied_rate("discrete", business_days / 252, 100000 / price)
  ) |>
  filter(business_days > 0)

dap_futures |>
  filter(symbol %in% c("DAPK25", "DAPK35")) |>
  ggplot(aes(x = refdate, y = adjusted_tax, group = symbol, color = symbol)) +
  geom_line() +
  geom_point() +
  labs(
    title = "DAP Future Rates - Real Interest Rates",
    caption = stringr::str_glue("Data imported using rb3 at {Sys.Date()}"),
    x = "Date",
    y = "Interest Rates",
    color = "Symbol"
  ) +
  scale_y_continuous(labels = scales::percent)

# ----

col_di1 <- "DI1F35"
col_dap <- "DAPK35"

infl_futures <- df |>
  filter(symbol %in% c(col_di1, col_dap)) |>
  mutate(
    maturity_date = if_else(commodity == "DI1",
      maturity2date(maturity_code), maturity2date(maturity_code, "15th day")
    ),
    fixing = following(maturity_date, "Brazil/ANBIMA"),
    business_days = bizdays(refdate, maturity_date, "Brazil/ANBIMA"),
    adjusted_tax = implied_rate("discrete", business_days / 252, 100000 / price)
  ) |>
  arrange(refdate)

infl_expec <- infl_futures |>
  select(symbol, price, refdate) |>
  tidyr::spread(symbol, price) |>
  mutate(inflation = .data[[col_dap]] / .data[[col_di1]] - 1)

infl_expec |>
  ggplot(aes(x = refdate, y = inflation)) +
  geom_line() +
  geom_point()
