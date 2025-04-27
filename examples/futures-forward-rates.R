
library(rb3)
library(ggplot2)
library(dplyr)
library(fixedincome)
library(bizdays)

df <- futures_get() |>
  filter(commodity == "DI1", refdate >= "2023-01-01") |>
  collect()

di1_futures <- df |>
  filter(commodity == "DI1") |>
  mutate(
    maturity_date = maturitycode2date(maturity_code),
    fixing = following(maturity_date, "Brazil/ANBIMA"),
    business_days = bizdays(refdate, maturity_date, "Brazil/ANBIMA"),
    adjusted_tax = implied_rate("discrete", business_days / 252, 100000 / price)
  ) |>
  filter(business_days > 0)

di1_futures |>
  filter(symbol %in% c("DI1F26", "DI1F36")) |>
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

# ----

nome_coluna1 <- "DI1F26"
nome_coluna2 <- "DI1F36"

forward_factor <- di1_futures |>
  filter(symbol %in% c(nome_coluna1, nome_coluna2)) |>
  select(symbol, price, refdate) |>
  tidyr::spread(symbol, price) |>
  mutate(forward_factor = .data[[nome_coluna1]] / .data[[nome_coluna2]])

business_days <- di1_futures |>
  filter(symbol %in% c(nome_coluna1, nome_coluna2)) |>
  select(symbol, business_days, refdate) |>
  tidyr::spread(symbol, business_days) |>
  mutate(business_days = .data[[nome_coluna2]] - .data[[nome_coluna1]])

forward_factor[["business_days"]] <- business_days[["business_days"]]

forward_rates <- forward_factor |>
  mutate(
    fwd_rate = implied_rate("discrete", business_days / 252, forward_factor)
  )
