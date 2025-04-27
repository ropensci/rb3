library(rb3)
library(dplyr)
library(tidyr)
library(ggplot2)
library(bizdays)

df <- futures_get() |>
  filter(refdate > "2024-01-01", commodity == "DI1") |>
  collect()

df |>
  distinct(symbol) |>
  pull(symbol) |>
  sort()

fut1 <- "DI1F26"
fut2 <- "DI1F31"
fut3 <- "DI1F36"

df_fut <- df |>
  filter(symbol %in% c(fut1, fut2, fut3)) |>
  mutate(
    maturity_date = maturitycode2date(maturity_code) |> following("Brazil/ANBIMA"),
    business_days = bizdays(refdate, maturity_date, "Brazil/ANBIMA")
  )

df_du <- df_fut |>
  select(refdate, symbol, business_days) |>
  pivot_wider(names_from = symbol, values_from = business_days) |>
  mutate(
    du1 = .data[[fut2]] - .data[[fut1]],
    du2 = .data[[fut3]] - .data[[fut2]]
  ) |>
  select(refdate, du1, du2)

df_fwd <- df_fut |>
  select(refdate, symbol, price) |>
  pivot_wider(names_from = symbol, values_from = price) |>
  inner_join(df_du, by = "refdate") |>
  mutate(
    fwd_f1f2 = (.data[[fut1]] / .data[[fut2]])^(252 / du1) - 1,
    fwd_f2f3 = (.data[[fut2]] / .data[[fut3]])^(252 / du2) - 1,
    fwd_f1f3 = (.data[[fut1]] / .data[[fut3]])^(252 / (du2 + du1)) - 1,
    butterfly = fwd_f2f3 - fwd_f1f2
  ) |>
  select(refdate, fwd_f1f2, fwd_f2f3, fwd_f1f3, butterfly) |>
  filter(!is.na(butterfly)) |>
  pivot_longer(!refdate, names_to = "tenor", values_to = "forward_rates")

df_fwd |>
  filter(tenor == "butterfly") |>
  ggplot(aes(x = refdate, y = forward_rates, group = tenor, color = tenor)) +
  geom_line() +
  labs(
    x = "Data", y = "Taxas a Termo",
    title = "Histórico de Taxas a Termo nos Futuros de DI1",
    caption = "Fonte B3 - package rb3"
  ) +
  theme(legend.position = "bottom", legend.title = element_blank())

