library(rb3)

indexes_get_ <- indexes_get()
ibov_weights_get_ <- index_weights_get("IBOV")
ibxx_weights_get_ <- index_weights_get("IBXX")
smll_weights_get_ <- index_weights_get("SMLL")
smll_comp_get_ <- index_comp_get("SMLL")
ibov_by_segment_get_ <- index_by_segment_get("IBOV")
ibov_data_1 <- index_get("IBOV", as.Date("2019-01-01"))
ibov_data_2 <- index_get("IBOV", as.Date("1968-01-01"))
smll_data <- index_get("SMLL", as.Date("2010-01-01"))

save(
  indexes_get_,
  ibov_weights_get_,
  ibxx_weights_get_,
  smll_weights_get_,
  smll_comp_get_,
  ibov_by_segment_get_,
  ibov_data_1,
  ibov_data_2,
  smll_data,
  file = "vignettes/indexes_data.rda"
)

ch <- cotahist_get("yearly") |>
  filter(year(refdate) == 2024, instrument_market == 10) |>
  collect()
save(
  ch,
  file = "vignettes/cotahist_data.rda"
)
