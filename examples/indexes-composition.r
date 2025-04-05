
meta <- download_marketdata("b3-indexes-composition")
read_marketdata(meta)

template_dataset("b3-indexes-theorical-portfolio") |> collect()
template_dataset("b3-indexes-current-portfolio") |> collect()

max_date <- template_dataset("b3-indexes-composition") |>
  summarise(update_date = max(update_date)) |>
  collect() |>
  pull(update_date)

index <- c("IBOV", "SMLL", "IDIV")
x <- lapply(index, function(index) {
  template_dataset("b3-indexes-composition") |>
    filter(update_date == max_date, str_detect(indexes, index)) |>
    select(symbol) |>
    collect() |>
    pull(symbol)
})
stats::setNames(x, index)

symbols <- "ABEV3"
template_dataset("b3-indexes-composition") |>
  filter(update_date == max_date, symbol %in% symbols) |>
  select(indexes) |>
  collect() |>
  pull(indexes) |> str_split(",") |> unlist()


template_dataset("b3-indexes-composition") |>
  filter(update_date == max_date) |>
  select(indexes) |>
  collect() |>
  pull(indexes) |>
  str_split(",") |>
  unlist() |>
  unique() |>
  sort()

indexes_assets_by_indexes <- function(indexes) {
  max_date <- template_dataset("b3-indexes-composition") |>
    summarise(update_date = max(update_date)) |>
    collect() |>
    pull(update_date)

  x <- lapply(indexes, function(index) {
    template_dataset("b3-indexes-composition") |>
      filter(update_date == max_date, str_detect(indexes, index)) |>
      select(symbol) |>
      collect() |>
      pull(symbol)
  })
  stats::setNames(x, index)
}

indexes_indexes_by_assets <- function(symbols) {
  max_date <- template_dataset("b3-indexes-composition") |>
    summarise(update_date = max(update_date)) |>
    collect() |>
    pull(update_date)

  template_dataset("b3-indexes-composition") |>
    filter(update_date == max_date, symbol %in% symbols) |>
    select(indexes) |>
    collect() |>
    pull(indexes) |>
    str_split(",") |>
    unlist()
}



library(httr)

params <- jsonlite::toJSON(list(
  pageNumber = 1,
  pageSize = 9999
), auto_unbox = TRUE)


params_enc <- base64enc::base64encode(charToRaw(params))

url <- str_glue("https://sistemaswebb3-listados.b3.com.br/indexProxy/indexCall/GetStockIndex/{params_enc}")

up <- httr::parse_url("https://sistemaswebb3-listados.b3.com.br/indexProxy/indexCall/GetStockIndex/")

up$path <- paste0(up$path, "/", params_enc)

res <- GET(url)

status_code(res)

x <- content(res, as = "text") |> jsonlite::fromJSON()

x$header
x$results |> head()

"https://sistemaswebb3-listados.b3.com.br/indexPage/assets/i18n/pt-br.json"

# carteira teórica

url <- "https://sistemaswebb3-listados.b3.com.br/indexProxy/indexCall/GetTheoricalPortfolio/eyJwYWdlTnVtYmVyIjoxLCJwYWdlU2l6ZSI6MjAsImxhbmd1YWdlIjoicHQtYnIiLCJpbmRleCI6IklCT1YifQ=="

res <- GET(url)

content(res, as = "text") |> jsonlite::fromJSON()

k <- "eyJwYWdlTnVtYmVyIjoxLCJwYWdlU2l6ZSI6MjAsImxhbmd1YWdlIjoicHQtYnIiLCJpbmRleCI6IklCT1YifQ=="

base64enc::base64decode(k) |> rawToChar()
#> "{\"pageNumber\":1,\"pageSize\":20,\"language\":\"pt-br\",\"index\":\"IBOV\"}"

# por setor de atuação

"https://sistemaswebb3-listados.b3.com.br/indexProxy/indexCall/GetPortfolioDay/eyJsYW5ndWFnZSI6InB0LWJyIiwicGFnZU51bWJlciI6MSwicGFnZVNpemUiOjIwLCJpbmRleCI6IklCT1YiLCJzZWdtZW50IjoiMSJ9"

k <- "eyJsYW5ndWFnZSI6InB0LWJyIiwicGFnZU51bWJlciI6MSwicGFnZVNpemUiOjIwLCJpbmRleCI6IklCT1YiLCJzZWdtZW50IjoiMSJ9"

base64enc::base64decode(k) |> rawToChar()

"https://sistemaswebb3-listados.b3.com.br/indexProxy/indexCall/GetPortfolioDay/eyJsYW5ndWFnZSI6InB0LWJyIiwicGFnZU51bWJlciI6MSwicGFnZVNpemUiOjIwLCJpbmRleCI6IklCT1YiLCJzZWdtZW50IjoiMiJ9"

k <- "eyJsYW5ndWFnZSI6InB0LWJyIiwicGFnZU51bWJlciI6MSwicGFnZVNpemUiOjIwLCJpbmRleCI6IklCT1YiLCJzZWdtZW50IjoiMiJ9"

base64enc::base64decode(k) |> rawToChar()
#> "{\"language\":\"pt-br\",\"pageNumber\":1,\"pageSize\":20,\"index\":\"IBOV\",\"segment\":\"2\"}"

# por código

"https://sistemaswebb3-listados.b3.com.br/indexProxy/indexCall/GetPortfolioDay/eyJsYW5ndWFnZSI6InB0LWJyIiwicGFnZU51bWJlciI6MSwicGFnZVNpemUiOjIwLCJpbmRleCI6IklCT1YiLCJzZWdtZW50IjoiMSJ9"

k <- "eyJsYW5ndWFnZSI6InB0LWJyIiwicGFnZU51bWJlciI6MSwicGFnZVNpemUiOjIwLCJpbmRleCI6IklCT1YiLCJzZWdtZW50IjoiMSJ9"

base64enc::base64decode(k) |> rawToChar()
#> "{\"language\":\"pt-br\",\"pageNumber\":1,\"pageSize\":20,\"index\":\"IBOV\",\"segment\":\"1\"}"

# IBrX100

"https://sistemaswebb3-listados.b3.com.br/indexProxy/indexCall/GetPortfolioDay/eyJsYW5ndWFnZSI6InB0LWJyIiwicGFnZU51bWJlciI6MSwicGFnZVNpemUiOjIwLCJpbmRleCI6IklCWFgiLCJzZWdtZW50IjoiMSJ9"

k <- "eyJsYW5ndWFnZSI6InB0LWJyIiwicGFnZU51bWJlciI6MSwicGFnZVNpemUiOjIwLCJpbmRleCI6IklCWFgiLCJzZWdtZW50IjoiMSJ9"

base64enc::base64decode(k) |> rawToChar()
#> "{\"language\":\"pt-br\",\"pageNumber\":1,\"pageSize\":20,\"index\":\"IBXX\",\"segment\":\"1\"}"

f <- download_marketdata("GetStockIndex")
df <- read_marketdata(f, "GetStockIndex", FALSE)
str(df)
df <- read_marketdata(f, "GetStockIndex", TRUE)
str(df)