
library(ggplot2)
library(dplyr)


year <- 1998:2022
index_name <- "IBOV"
index_data <- index_get(index_name, as.Date("2020-01-01"))
index_data <- index_get(index_name, as.Date("1997-01-01"))
index_data <- index_get(index_name, as.Date("1997-01-01"), as.Date("1999-01-01"))
index_data <- index_get(index_name, as.Date("1990-01-01"), as.Date("1997-12-31"))

index_data |>
  ggplot(aes(x = refdate, y = value)) +
  geom_line()

View(index_data)

year <- 2022
index_name <- "IBXX"
index_data <- index_get(index_name, year)

indexes_get()

index_data |>
  ggplot(aes(x = refdate, y = value)) +
  geom_line()

View(index_data)

# ----

index_get_from_file <- function(year) {
  index_data <- read_excel("./examples/IBOVDIA.XLS",
    sheet = as.character(year), skip = 1, range = "A3:M33",
    col_names = c("day", 1:12),
  )

  pivot_longer(index_data, "1":"12", names_to = "month") |>
    mutate(
      month = as.integer(.data$month),
      year = year,
      refdate = ISOdate(.data$year, .data$month, .data$day) |> as.Date(),
      index_name = "IBOV"
    ) |>
    filter(!is.na(.data$value)) |>
    arrange("refdate") |>
    select("refdate", "index_name", "value")
}

# str_pad(1:12, 2, pad = "0")
index_get_from_file <- function(year) {
  index_data <- read_excel("./examples/IBOVDIA.XLS",
    sheet = as.character(year), skip = 1, range = "A3:M33",
    col_names = c("day", 1:12),
  )

  tidyr::pivot_longer(index_data, "1":"12", names_to = "month") |>
    mutate(
      month = as.integer(month),
      year = year,
      refdate = ISOdate(year, month, day) |> as.Date(),
      index_name = "IBOV"
    ) |>
    filter(!is.na(value)) |>
    arrange(refdate) |>
    select(refdate, index_name, value)
}

year <- 1968
index_get_from_file(year)

ibov_hist_prices <- map_dfr(1968:1997, index_get_from_file)

save(ibov_hist_prices, file = "./inst/extdata/IBOV.RData")

readr::write_rds(ibov_hist_prices, file = "./inst/extdata/IBOV.rds")

index_data |>
  ggplot(aes(x = refdate, y = value)) +
  geom_line()

index_data |>
  mutate(returns = log(value) - log(dplyr::lag(value))) |>
  ggplot(aes(x = refdate, y = returns)) +
  geom_line()

index_data |>
  filter(refdate <= as.Date("1980-01-01")) |>
  ggplot(aes(x = refdate, y = value)) +
  geom_line()
