# template_dataset("b3-indexes-historical-data") |>
#   count() |>
#   collect()

# fetch_marketdata("b3-indexes-historical-data", index = c("IBOV", "SMLL", "IBXL", "IBXX", "IBRA", "IDIV"), year = 2000:2025)
fetch_marketdata("b3-indexes-historical-data", index = c("IBOV", "IBXX", "IBXL"), year = 1994:1996)
fetch_marketdata("b3-indexes-historical-data", index = "IBXX", year = 1994:1996)

template_dataset("b3-indexes-historical-data") |>
  collect() |>
  pivot_longer(-c(index, day, year), names_to = "month", values_to = "value") |>
  mutate(
    month = as.integer(str_replace(month, "month", "")),
    refdate = lubridate::make_date(year, month, day),
  ) |>
  select(-c(year, month, day)) |>
  filter(!is.na(value)) |>
  arrange(refdate) |>
  filter(index == "IBXX")

