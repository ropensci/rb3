library(rb3)
library(tidyverse)
library(lubridate)

ch <- cotahist_get("yearly")

# ETFs ----

## calcular o volume financeiro das ETFs para o ano de 2024

etfs <- ch |> cotahist_filter_etf() |> filter(year(refdate) == 2024) |> collect()

## fazer um gráfico de barras horizontais com o volume financeiro das ETFs

etfs |>
  group_by(symbol) |>
  summarise(volume = sum(volume)) |>
  arrange(desc(volume)) |>
  head(10) |>
  ggplot(aes(y = reorder(symbol, volume), x = volume)) +
  geom_bar(stat = "identity", fill = "royalblue") +
  scale_x_continuous(labels = scales::label_number(scale = 1e-9, suffix = " B")) +
  labs(
    x = NULL, y = NULL,
    title = "Volume Financeiro das 10 Maiores ETFs",
    subtitle = "Volume Financeiro Negociado nas 10 Maiores ETFs em 2024",
    caption = "Dados obtidos com \U0001F4E6 rb3 - wilsonfreitas"
  )

## fazer um gráfico de barras horizontais com o volume financeiro médio diário das ETFs

etfs |>
  group_by(symbol) |>
  summarise(volume = mean(volume)) |>
  arrange(desc(volume)) |>
  head(10) |>
  ggplot(aes(y = reorder(symbol, volume), x = volume)) +
  geom_bar(stat = "identity", fill = "royalblue") +
  scale_x_continuous(labels = scales::label_number(scale = 1e-6, suffix = " M")) +
  labs(
    x = NULL, y = NULL,
    title = "Volume Financeiro Médio Diário das 10 Maiores ETFs",
    subtitle = "Volume Financeiro Médio Diário Negociado nas 10 Maiores ETFs em 2024",
    caption = "Dados obtidos com \U0001F4E6 rb3 - wilsonfreitas"
  )

## fazer um gráfico de barras com o volume financeiro médio diário das ETFs
## onde o volume das ETFs é proporcional ao volume financeiro médio diário da ETF com
## maior volume financeiro médio diário
etfs |>
  group_by(symbol) |>
  summarise(volume = mean(volume)) |>
  arrange(desc(volume)) |>
  head(10) |>
  mutate(volume_ratio = volume / max(volume)) |>
  ggplot(aes(y = reorder(symbol, volume), x = volume_ratio)) +
  geom_bar(stat = "identity", fill = "royalblue") +
  geom_vline(xintercept = 0.5, linetype = "dashed", color = "red", linewidth = 0.8, alpha = 0.25) +
  scale_x_continuous(
    labels = scales::label_percent(),
    breaks = c(0, 0.2, 0.4, 0.5, 0.6, 0.8, 1.0)
  ) +
  labs(
    x = NULL, y = NULL,
    title = "Volume Financeiro Médio Diário das 10 Maiores ETFs",
    subtitle = "Volume Financeiro Médio Diário Negociado nas 10 Maiores ETFs em 2024",
    caption = "Dados obtidos com \U0001F4E6 rb3 - wilsonfreitas"
  )

# Equities ----

## Equities volume ----

eq <- ch |>
  filter(year(refdate) == 2024) |>
  cotahist_filter_equity() |>
  collect()

## fazer um gráfico de barras horizontais com o volume financeiro das ações

eq |>
  group_by(symbol) |>
  summarise(volume = sum(volume)) |>
  arrange(desc(volume)) |>
  head(10) |>
  ggplot(aes(y = reorder(symbol, volume), x = volume)) +
  geom_bar(stat = "identity", fill = "royalblue") +
  scale_x_continuous(labels = scales::label_number(scale = 1e-9, suffix = " B")) +
  labs(
    x = NULL, y = NULL,
    title = "Volume Financeiro das 10 Maiores Ações",
    subtitle = "Volume Financeiro Negociado nas 10 Maiores Ações em 2024",
    caption = "Dados obtidos com \U0001F4E6 rb3 - wilsonfreitas"
  )

## fazer um gráfico com os dados diários do ADTV das 10 maiores ações

eq |>
  group_by(symbol) |>
  summarise(volume = mean(volume)) |>
  arrange(desc(volume)) |>
  head(10) |>
  ggplot(aes(y = reorder(symbol, volume), x = volume)) +
  geom_bar(stat = "identity", fill = "royalblue") +
  scale_x_continuous(labels = scales::label_number(scale = 1e-6, suffix = " M")) +
  labs(
    x = NULL, y = NULL,
    title = "Volume Financeiro Médio Diário das 10 Maiores Ações",
    subtitle = "Volume Financeiro Médio Diário Negociado nas 10 Maiores Ações em 2024",
    caption = "Dados obtidos com \U0001F4E6 rb3 - wilsonfreitas"
  )

symbols_eq <- eq |>
  group_by(symbol) |>
  summarise(volume = sum(volume)) |>
  arrange(desc(volume)) |>
  head(10) |>
  pull(symbol)

eq |>
  filter(symbol %in% symbols_eq) |>
  select (symbol, refdate, volume) |>
  arrange(symbol, refdate) |>
  collect() |>
  ggplot(aes(x = refdate, y = volume, colour = symbol)) +
  geom_line() +
  scale_y_continuous(labels = scales::label_number(scale = 1e-6, suffix = " M")) +
  labs(
    x = NULL, y = NULL,
    title = "Volume Financeiro das 10 Maiores Ações",
    subtitle = "Volume Financeiro Negociado nas 10 Maiores Ações em 2024",
    caption = "Dados obtidos com \U0001F4E6 rb3 - wilsonfreitas"
  )

## calcular o ADTV para um período de 20 dias

eq |>
  filter(symbol %in% symbols_eq) |>
  select(symbol, refdate, volume) |>
  arrange(symbol, refdate) |>
  collect() |>
  group_by(symbol) |>
  mutate(adtv = TTR::SMA(volume, n = 20)) |>
  ungroup() |>
  ggplot(aes(x = refdate, y = adtv, colour = symbol)) +
  geom_line() +
  scale_y_continuous(labels = scales::label_number(scale = 1e-6, suffix = " M")) +
  labs(
    x = NULL, y = NULL,
    title = "ADTV das 10 Maiores Ações",
    subtitle = "ADTV Negociado nas 10 Maiores Ações em 2024",
    caption = "Dados obtidos com \U0001F4E6 rb3 - wilsonfreitas"
  )

eq_monthly <- eq |>
  filter(symbol %in% symbols_eq) |>
  mutate(month = floor_date(refdate, "month")) |>
  group_by(month, symbol) |>
  summarise(volume = sum(volume)) |>
  collect()

# fazer um gráfico com os dados mensais do volume financeiro das 10 maiores ações
# onde o volume das ações está empilhado por mês
eq_monthly |>
  ggplot(aes(x = month, y = volume, group = symbol, fill = symbol)) +
  geom_bar(stat = "identity", position = "stack") +
  scale_fill_brewer(palette = "BrBG") +  # Using a more subdued/earthy palette
  scale_y_continuous(labels = scales::label_number(scale = 1e-9, suffix = " B")) +
  labs(
    x = NULL, y = NULL,
    title = "Volume Financeiro das 10 Maiores Ações",
    subtitle = "Volume Financeiro Negociado nas 10 Maiores Ações em 2024",
    caption = "Dados obtidos com \U0001F4E6 rb3 - wilsonfreitas"
  )

# fazer um gráfico semelhante ao anterior, mas de linha com área empilhada, ao invés de barras empilhadas
eq_monthly |>
  ggplot(aes(x = month, y = volume, group = symbol, fill = symbol)) +
  geom_area(position = "stack") +
  scale_fill_brewer(palette = "BrBG") +
  scale_y_continuous(labels = scales::label_number(scale = 1e-9, suffix = " B")) +
  labs(
    x = NULL, y = NULL,
    title = "Volume Financeiro das 10 Maiores Ações",
    subtitle = "Volume Financeiro Negociado nas 10 Maiores Ações em 2024",
    caption = "Dados obtidos com \U0001F4E6 rb3 - wilsonfreitas"
  )
