
library(dplyr)
library(tidyr)
library(ggplot2)

df <- futures_get("2019-01-01", Sys.Date() - 1)

df |> filter(commodity == "DI1") |> distinct(symbol) |> pull(symbol) |> sort()

df_fut <- df |>
  filter(symbol %in% c("DI1F23", "DI1F28", "DI1F33")) |>
  mutate(
    maturity_date = maturity2date(maturity_code) |> following("Brazil/ANBIMA"),
    business_days = bizdays(refdate, maturity_date, "Brazil/ANBIMA")
  )

df_fwd <- df_fut |>
  select(refdate, symbol, price) |>
  spread(symbol, price) |>
  mutate(
    fwd1 = (DI1F23 / DI1F28) ^ (252 / 1257) - 1,
    fwd2 = (DI1F28 / DI1F33) ^ (252 / 1257) - 1,
    spread = fwd2 - fwd1
  )

df_fwd |> ggplot(aes(x = refdate, y = fwd1)) +
  geom_line()

df_fwd |> ggplot(aes(x = refdate, y = fwd2)) +
  geom_line()

df_fwd |> ggplot(aes(x = refdate, y = spread)) +
  geom_line()

# ----

df_fut <- df |>
  filter(symbol %in% c("DI1F21", "DI1F31")) |>
  mutate(
    maturity_date = maturity2date(maturity_code) |> following("Brazil/ANBIMA"),
    business_days = bizdays(refdate, maturity_date, "Brazil/ANBIMA")
  )

df_fwd <- df_fut |>
  select(refdate, symbol, price) |>
  spread(symbol, price) |>
  mutate(
    fwd = (DI1F21 / DI1F31) ^ (252 / 2511) - 1
  )

df_fwd |> ggplot(aes(x = refdate, y = fwd)) +
  geom_line()
