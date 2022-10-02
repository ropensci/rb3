
devtools::load_all()

l <- list()
date <- as.Date("1990-01-01")
while (date <= as.Date("1999-12-31")) {
  cat(format(date), "\n")
  df <- futures_get(date)
  if (!is.null(df)) {
    l <- append(l, format(date))
  }
  date <- date + 1
}

all_dates <- seq(as.Date("1990-01-01"), as.Date("1999-12-31"), by = "day")

df_dates <- tibble(dates = format(all_dates))

library(lubridate)
library(bizdays)

df <- df_dates |> mutate(
  dates = as.Date(dates),
  is_bizday = dates %in% l,
  is_weekend = wday(dates) %in% c(1, 7),
  is_holiday = (! is_bizday) & (! is_weekend)
)

df |>
  filter(is_holiday) |>
  View()

holidaysBVMF <- c(df$dates, holidays("Brazil/ANBIMA")) |> sort()

create.calendar(
  "Brazil/BMF",
  holidaysBVMF,
  weekdays = c("saturday", "sunday"),
  adjust.from = following,
  adjust.to = preceding,
  financial = TRUE,
)

calendars()[["Brazil/BMF"]]

save_calendar("Brazil/BMF", "Brazil_BMF.json")
