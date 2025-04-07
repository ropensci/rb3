# Script to save data for the "Analyzing B3 Index Data with rb3" vignette
library(rb3)
library(dplyr)
library(ggplot2)
library(tidyr)
library(lubridate)
library(stringr)

# Generate example index historical data
set.seed(123)
start_date <- as.Date("2018-01-01")
end_date <- as.Date("2023-12-31")
dates <- seq(start_date, end_date, by = "day")
business_days <- dates[!weekdays(dates) %in% c("Saturday", "Sunday")]

# Parameters for synthetic data
ibov_start <- 85000
smll_start <- 2000
idiv_start <- 5000

# Create a trend and add noise
generate_index_series <- function(start_value, dates, annual_return = 0.08, annual_vol = 0.20) {
  n <- length(dates)
  daily_return <- annual_return / 252
  daily_vol <- annual_vol / sqrt(252)
  
  # Generate returns
  returns <- rnorm(n, mean = daily_return, sd = daily_vol)
  
  # Calculate cumulative returns
  cum_returns <- cumprod(1 + returns)
  
  # Apply to starting value
  values <- start_value * cum_returns
  
  data.frame(
    refdate = dates,
    value = values
  )
}

# Generate synthetic data for each index
ibov_data <- generate_index_series(ibov_start, business_days, annual_return = 0.09, annual_vol = 0.24)
ibov_data$symbol <- "IBOV"

smll_data <- generate_index_series(smll_start, business_days, annual_return = 0.07, annual_vol = 0.28)
smll_data$symbol <- "SMLL"

idiv_data <- generate_index_series(idiv_start, business_days, annual_return = 0.11, annual_vol = 0.20)
idiv_data$symbol <- "IDIV"

# Combine all index data
index_history <- bind_rows(ibov_data, smll_data, idiv_data)

# Sample stocks for each index with some overlap
all_stocks <- c(
  "PETR4", "VALE3", "ITUB4", "BBDC4", "ABEV3", "B3SA3", "RENT3", "WEGE3", "RADL3", "RAIL3",
  "MGLU3", "VVAR3", "LREN3", "NTCO3", "EGIE3", "ENBR3", "EQTL3", "TAEE11", "CSAN3", "TOTS3",
  "BBAS3", "BBSE3", "BRDT3", "BRFS3", "BRKM5", "CCRO3", "CMIG4", "CPLE6", "CRFB3", "CSNA3",
  "CVCB3", "CYRE3", "ECOR3", "ELET3", "EMBR3", "GGBR4", "GOAU4", "GOLL4", "HYPE3", "IGTA3",
  "IRBR3", "ITSA4", "JBSS3", "KLBN11", "COGN3", "SBSP3", "SANB11", "PSSA3", "UGPA3", "VIVT3"
)

set.seed(123)
ibov_stocks <- sample(all_stocks, 30)
smll_stocks <- sample(setdiff(all_stocks, ibov_stocks[1:20]), 25)
idiv_stocks <- c(sample(ibov_stocks, 15), sample(smll_stocks, 10))

# Add some common stocks to create overlaps
common_all <- c("TAEE11", "CSAN3", "WEGE3")
ibov_stocks <- c(ibov_stocks, common_all)
smll_stocks <- c(smll_stocks, common_all)
idiv_stocks <- c(idiv_stocks, common_all)

# Create composition data structure
create_composition_entry <- function(symbol, index_list, date) {
  data.frame(
    symbol = symbol,
    indexes = paste(index_list, collapse = ","),
    update_date = date
  )
}

# Create composition data
latest_date <- as.Date("2023-12-29")
composition_entries <- list()

for (symbol in ibov_stocks) {
  indices <- "IBOV"
  if (symbol %in% smll_stocks) indices <- c(indices, "SMLL")
  if (symbol %in% idiv_stocks) indices <- c(indices, "IDIV")
  composition_entries[[symbol]] <- create_composition_entry(symbol, indices, latest_date)
}

for (symbol in setdiff(smll_stocks, ibov_stocks)) {
  indices <- "SMLL"
  if (symbol %in% idiv_stocks) indices <- c(indices, "IDIV")
  composition_entries[[symbol]] <- create_composition_entry(symbol, indices, latest_date)
}

for (symbol in setdiff(idiv_stocks, c(ibov_stocks, smll_stocks))) {
  composition_entries[[symbol]] <- create_composition_entry(symbol, "IDIV", latest_date)
}

composition <- bind_rows(composition_entries)

# Add more data for completeness
composition$corporation_name <- paste0("Company ", composition$symbol)
composition$refdate <- latest_date
composition$start_month <- 1
composition$end_month <- 12
composition$year <- 2023
composition$specification_code <- paste0("S", composition$symbol)

# Create theoretical portfolio data
generate_weights <- function(symbols, total = 1) {
  n <- length(symbols)
  # Create a power-law distribution for weights
  raw_weights <- 1 / (1:n)^1.2
  normalized_weights <- raw_weights / sum(raw_weights)
  
  data.frame(
    symbol = symbols,
    weight = normalized_weights,
    theoretical_quantity = round(normalized_weights * 1e9, 0)
  )
}

# Generate weights for each index
ibov_weights <- generate_weights(ibov_stocks)
ibov_weights$index <- "IBOV"

smll_weights <- generate_weights(smll_stocks)
smll_weights$index <- "SMLL"

idiv_weights <- generate_weights(idiv_stocks)
idiv_weights$index <- "IDIV"

# Combine all theoretical portfolio data
theoretical <- bind_rows(ibov_weights, smll_weights, idiv_weights)
theoretical$refdate <- latest_date
theoretical$total_theoretical_quantity <- 1e9
theoretical$reductor <- 1

# Create current portfolio data with sectors
sectors <- c(
  "Financeiro", "Materiais Básicos", "Petróleo, Gás e Biocombustíveis",
  "Consumo Cíclico", "Utilidade Pública", "Bens Industriais",
  "Consumo Não Cíclico", "Saúde", "Tecnologia da Informação", "Comunicações"
)

current <- theoretical
current$portfolio_date <- latest_date

# Assign sectors randomly but with some consistency
set.seed(123)
sector_mapping <- data.frame(
  symbol = all_stocks,
  sector = sample(sectors, length(all_stocks), replace = TRUE)
)

current <- current %>%
  left_join(sector_mapping, by = "symbol")

# Create indexes list
indexes <- c("IBOV", "SMLL", "IDIV", "IBXX", "IBXL", "IBRA", "ICON", "IEEX", "IFNC", "IMOB", "IMAT", "UTIL")

# Stock/index overlap data
stocks_by_index <- list(
  IBOV = ibov_stocks,
  SMLL = smll_stocks,
  IDIV = idiv_stocks
)

# Calculate overlaps
petr4_indices <- c("IBOV", "IBXX", "IBXL", "IBRA", "IMAT")

theoretical <- indexes_theoretical_portfolio_get() |>
  collect()

# Get the latest date for each index
latest_dates <- theoretical |>
  group_by(index) |>
  summarise(latest = max(refdate))

current <- indexes_current_portfolio_get() |>
  collect()

# Get the latest date for each index
current_latest <- current |>
  group_by(index) |>
  summarise(latest = max(refdate))

# Save all data
save(
  index_history, 
  composition, 
  theoretical, 
  current, 
  indexes, 
  stocks_by_index, 
  petr4_indices,
  latest_date,
  latest_dates,
  current_latest,
  file = "vignettes/indexes_data.rda"
)