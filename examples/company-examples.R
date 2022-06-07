
library(tidyverse)
library(lubridate)

f <- download_marketdata("GetListedSupplementCompany", company_name = "ABEV")
sc <- read_marketdata(f, "GetListedSupplementCompany")

f <- download_marketdata(
  "GetDetailsCompany",
  code_cvm = sc$Info$codeCVM
)
details <- read_marketdata(f, "GetDetailsCompany", TRUE)

f <- download_marketdata(
  "GetListedCashDividends",
  trading_name = sc$Info$tradingName
)
cd <- read_marketdata(f, "GetListedCashDividends", TRUE)

cd |>
  mutate(ano = year(lastDatePriorEx)) |>
  group_by(ano) |>
  summarise(dy = sum(corporateActionPrice)) |>
  arrange(desc(ano)) |>
  View()