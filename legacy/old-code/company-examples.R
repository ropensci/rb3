
library(tidyverse)
library(lubridate)

f <- download_marketdata("GetListedSupplementCompany", company_name = "B3SA")
sc <- read_marketdata(f, "GetListedSupplementCompany", TRUE)

sc

res <- paste0(
  "https://sistemaswebb3-listados.b3.com.br/listedCompaniesProxy/CompanyCall/GetListedFinancial/",
  list(codeCVM = sc$Info$codeCVM, language = "pt-br") |>
    jsonlite::toJSON(auto_unbox = TRUE) |>
    charToRaw() |>
    base64enc::base64encode()
) |> httr::GET()

f <- httr::content(res, as = "text") |> jsonlite::fromJSON()
View(f)
names(f)

f <- download_marketdata(
  "GetDetailsCompany",
  code_cvm = sc$Info$codeCVM
)
details <- read_marketdata(f, "GetDetailsCompany", FALSE)

details$OtherCodes

details$Info |> t()

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