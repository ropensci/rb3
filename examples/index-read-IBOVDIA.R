
library(ggplot2)
library(dplyr)

# ----

# str_pad(1:12, 2, pad = "0")
index_get_from_file <- function(year) {
  index_data <- readxl::read_excel("./examples/IBOVDIA.XLS",
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

ibovespa_index_get <- function(first_date, last_date = as.Date("1997-12-31")) {
  f <- system.file("extdata/IBOV.rds", package = "rb3")
  read_rds(f) |> filter(.data$refdate >= first_date, .data$refdate <= last_date)
}
