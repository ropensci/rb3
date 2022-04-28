
library(dplyr)
library(tidyr)
library(ggplot2)

df <- futures_get("2019-01-01", Sys.Date() - 1)

df |>
  filter(commodity == "DI1") |>
  distinct(symbol) |>
  pull(symbol) |>
  sort()

df_fut <- df |>
  filter(symbol %in% c("DI1F23", "DI1F28", "DI1F33")) |>
  mutate(
    maturity_date = maturity2date(maturity_code) |> following("Brazil/ANBIMA"),
    business_days = bizdays(refdate, maturity_date, "Brazil/ANBIMA")
  )

df_du <- df_fut |>
  select(refdate, symbol, business_days) |>
  pivot_wider(names_from = symbol, values_from = business_days) |>
  mutate(
    du1 = DI1F28 - DI1F23,
    du2 = DI1F33 - DI1F28
  ) |>
  select(refdate, du1, du2)

df_fwd <- df_fut |>
  select(refdate, symbol, price) |>
  pivot_wider(names_from = symbol, values_from = price) |>
  inner_join(df_du, by = "refdate") |>
  mutate(
    fwd_F23F28 = (DI1F23 / DI1F28)^(252 / du1) - 1,
    fwd_F28F33 = (DI1F28 / DI1F33)^(252 / du2) - 1,
    fwd_F23F33 = (DI1F23 / DI1F33)^(252 / (du2 + du1)) - 1
  ) |>
  select(refdate, fwd_F23F28, fwd_F28F33, fwd_F23F33) |>
  filter(!is.na(fwd_F23F33)) |>
  pivot_longer(!refdate, names_to = "tenor", values_to = "forward_rates")

df_fwd |>
  ggplot(aes(x = refdate, y = forward_rates, group = tenor, color = tenor)) +
  geom_line() +
  labs(
    x = "Data", y = "Taxas a Termo",
    title = "Histórico de Taxas a Termo nos Futuros de DI1",
    caption = "Fonte B3 - package rb3"
  ) +
  theme(legend.position = "bottom", legend.title = element_blank())

# ----

df_fut <- df |>
  filter(symbol %in% c("DI1F23", "DI1F33")) |>
  mutate(
    maturity_date = maturity2date(maturity_code) |> following("Brazil/ANBIMA"),
    business_days = bizdays(refdate, maturity_date, "Brazil/ANBIMA")
  )

df_du <- df_fut |>
  select(refdate, symbol, business_days) |>
  pivot_wider(names_from = symbol, values_from = business_days) |>
  mutate(
    du = DI1F33 - DI1F23
  ) |>
  select(refdate, du)

df_fwd <- df_fut |>
  select(refdate, symbol, price) |>
  pivot_wider(names_from = symbol, values_from = price) |>
  inner_join(df_du, by = "refdate") |>
  mutate(
    fwd = (DI1F23 / DI1F33)^(252 / du) - 1
  ) |>
  select(refdate, fwd) |> na.omit()

df_fwd |>
  ggplot(aes(x = refdate, y = fwd)) +
  geom_line() +
  labs(
    x = "Data", y = "Taxas a Termo",
    title = "Histórico de Taxas a Termo 10Y - F23:F33",
    caption = "Fonte B3 - package rb3"
  )
