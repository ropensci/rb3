
url <- "https://sistemaswebb3-listados.b3.com.br/listedCompaniesProxy/CompanyCall/GetMaterialFacts/eyJsYW5ndWFnZSI6InB0LWJyIiwiY29kZUNWTSI6IjUwMDI0IiwieWVhciI6MjAxMSwiZGF0ZUluaXRpYWwiOiIyMDExLTAxLTAxIiwiZGF0ZUZpbmFsIjoiMjAxMS0xMi0zMSIsImNhdGVnb3J5Ijo2LCJwYWdlTnVtYmVyIjoxLCJwYWdlU2l6ZSI6NX0="

#       https://sistemaswebb3-listados.b3.com.br/listedCompaniesProxy/CompanyCall/GetMaterialFacts/eyJsYW5ndWFnZSI6InB0LWJyIiwiY29kZUNWTSI6IjEwMjMiLCJ5ZWFyIjoyMDIyLCJkYXRlSW5pdGlhbCI6IjIwMjItMDEtMDEiLCJkYXRlRmluYWwiOiIyMDIyLTEyLTMxIiwiY2F0ZWdvcnkiOjEsInBhZ2VOdW1iZXIiOjEsInBhZ2VTaXplIjo1fQ==
hash <- "eyJsYW5ndWFnZSI6InB0LWJyIiwiY29kZUNWTSI6IjUwMDI0IiwieWVhciI6MjAxMSwiZGF0ZUluaXRpYWwiOiIyMDExLTAxLTAxIiwiZGF0ZUZpbmFsIjoiMjAxMS0xMi0zMSIsImNhdGVnb3J5Ijo2LCJwYWdlTnVtYmVyIjoxLCJwYWdlU2l6ZSI6NX0="

x <- base64enc::base64decode(hash) |>
  rawToChar() |>
  jsonlite::fromJSON()

fix(x)

lx <- list(
  language = "pt-br",
  codeCVM = "50024",
  year = 2010L,
  dateInitial = "2000-01-01",
  dateFinal = "2022-12-31",
  # categoty = 6L,
  pageNumber = 1L,
  pageSize = 9999L
)

hsh1 <- lx |>
  jsonlite::toJSON(auto_unbox = TRUE) |>
  charToRaw() |>
  base64enc::base64encode()

url <- paste0(
  "https://sistemaswebb3-listados.b3.com.br/listedCompaniesProxy/CompanyCall/GetMaterialFacts/",
  hsh1
)

res <- httr::GET(url, httr::verbose())

txt <- httr::content(res, as = "text")

x <- jsonlite::fromJSON(txt)

x$results |> View()

# ----

res <- paste0(
  "https://sistemaswebb3-listados.b3.com.br/listedCompaniesProxy/CompanyCall/GetMaterialFacts/",
  list(
    language = "pt-br",
    codeCVM = "50024",
    year = 2010L,
    dateInitial = "2000-01-01",
    dateFinal = "2022-12-31",
    # categoty = 6L,
    pageNumber = 1L,
    pageSize = 9999L
  ) |>
    jsonlite::toJSON(auto_unbox = TRUE) |>
    charToRaw() |>
    base64enc::base64encode()
) |> httr::GET(httr::verbose())

res

(m <- httr::content(res, as = "text") |> jsonlite::fromJSON())
names(m)
m$results |> str()

httr::content(res, as = "text") |>
  jsonlite::fromJSON(simplifyDataFrame = FALSE) |>
  View()

# ----

hsh <- "eyJpc3N1aW5nQ29tcGFueSI6IkJCQVMiLCJsYW5ndWFnZSI6InB0LWJyIn0="

base64enc::base64decode(hsh) |>
  rawToChar() |>
  jsonlite::fromJSON()

res <- paste0(
  "https://sistemaswebb3-listados.b3.com.br/listedCompaniesProxy/CompanyCall/GetListedSupplementCompany/",
  list(issuingCompany = "LWSA", language = "pt-br") |>
    jsonlite::toJSON(auto_unbox = TRUE) |>
    charToRaw() |>
    base64enc::base64encode()
) |> httr::GET(httr::verbose())

res

(x <- httr::content(res, as = "text") |> jsonlite::fromJSON())
x$cashDividends[[1]]
x$stockDividends[[1]]
x$subscriptions[[1]]
x$stockCapital
x$segment
x$quotedPerSharSince
x$commonSharesForm
x$preferredSharesForm
x$hasCommom
x$hasPreferred
x$code
x$codeCVM
x$totalNumberShares
x$numberCommonShares
x$numberPreferredShares
x$roundLot
x$tradingName
names(x)
View(x)

(y <- httr::content(res, as = "text") |> jsonlite::fromJSON(simplifyDataFrame = FALSE))
View(y)

# ----

# https://sistemaswebb3-listados.b3.com.br/listedCompaniesProxy/CompanyCall/GetDetail/eyJjb2RlQ1ZNIjoiMTAyMyIsImxhbmd1YWdlIjoicHQtYnIifQ==

hsh <- "eyJjb2RlQ1ZNIjoiMTAyMyIsImxhbmd1YWdlIjoicHQtYnIifQ=="

base64enc::base64decode(hsh) |>
  rawToChar() |>
  jsonlite::fromJSON()

res <- paste0(
  "https://sistemaswebb3-listados.b3.com.br/listedCompaniesProxy/CompanyCall/GetDetail/",
  list(codeCVM = x$codeCVM, language = "pt-br") |>
    jsonlite::toJSON(auto_unbox = TRUE) |>
    charToRaw() |>
    base64enc::base64encode()
) |> httr::GET(httr::verbose())

res

(g <- httr::content(res, as = "text") |> jsonlite::fromJSON())
names(g)
View(g)

# https://sistemaswebb3-listados.b3.com.br/listedCompaniesProxy/CompanyCall/GetListedFinancial/eyJjb2RlQ1ZNIjoiNDE3MCIsImxhbmd1YWdlIjoicHQtYnIifQ==

hsh <- "eyJjb2RlQ1ZNIjoiNDE3MCIsImxhbmd1YWdlIjoicHQtYnIifQ=="

base64enc::base64decode(hsh) |>
  rawToChar() |>
  jsonlite::fromJSON()

res <- paste0(
  "https://sistemaswebb3-listados.b3.com.br/listedCompaniesProxy/CompanyCall/GetListedFinancial/",
  list(codeCVM = x$codeCVM, language = "pt-br") |>
    jsonlite::toJSON(auto_unbox = TRUE) |>
    charToRaw() |>
    base64enc::base64encode()
) |> httr::GET(httr::verbose())

res

f <- httr::content(res, as = "text") |> jsonlite::fromJSON(simplifyDataFrame = FALSE)
names(f)
View(f)
f$titleInitial
f$consolidated |> as_tibble()
f$unconsolidated |> as_tibble()
f$freeFloatResult

# https://sistemaswebb3-listados.b3.com.br/listedCompaniesProxy/CompanyCall/GetListedCashDividends/eyJsYW5ndWFnZSI6InB0LWJyIiwicGFnZU51bWJlciI6MSwicGFnZVNpemUiOjIwLCJ0cmFkaW5nTmFtZSI6IlRBRVNBIn0=

hsh <- "eyJsYW5ndWFnZSI6InB0LWJyIiwicGFnZU51bWJlciI6MSwicGFnZVNpemUiOjIwLCJ0cmFkaW5nTmFtZSI6IlRBRVNBIn0="

base64enc::base64decode(hsh) |>
  rawToChar() |>
  jsonlite::fromJSON()

res <- paste0(
  "https://sistemaswebb3-listados.b3.com.br/listedCompaniesProxy/CompanyCall/GetListedCashDividends/",
  list(
    tradingName = stringr::str_trim(x$tradingName),
    language = "pt-br",
    pageNumber = 1,
    pageSize = 9999
  ) |>
    jsonlite::toJSON(auto_unbox = TRUE) |>
    charToRaw() |>
    base64enc::base64encode()
) |> httr::GET(httr::verbose())

res

d <- httr::content(res, as = "text") |> jsonlite::fromJSON(simplifyDataFrame = FALSE)
View(d)
names(d)
d$results

# https://sistemaswebb3-listados.b3.com.br/listedCompaniesProxy/CompanyCall/GetDetail/eyJjb2RlQ1ZNIjoiMTAyMyIsImxhbmd1YWdlIjoicHQtYnIifQ==
# https://sistemaswebb3-listados.b3.com.br/listedCompaniesProxy/CompanyCall/GetListedFinancial/eyJjb2RlQ1ZNIjoiNDE3MCIsImxhbmd1YWdlIjoicHQtYnIifQ==
# https://sistemaswebb3-listados.b3.com.br/listedCompaniesProxy/CompanyCall/GetMaterialFacts/eyJsYW5ndWFnZSI6InB0LWJyIiwiY29kZUNWTSI6IjUwMDI0IiwieWVhciI6MjAxMSwiZGF0ZUluaXRpYWwiOiIyMDExLTAxLTAxIiwiZGF0ZUZpbmFsIjoiMjAxMS0xMi0zMSIsImNhdGVnb3J5Ijo2LCJwYWdlTnVtYmVyIjoxLCJwYWdlU2l6ZSI6NX0="
# https://sistemaswebb3-listados.b3.com.br/listedCompaniesProxy/CompanyCall/GetListedSupplementCompany/

# https://sistemaswebb3-listados.b3.com.br/listedCompaniesProxy/CompanyCall/GetListedCashDividends/eyJsYW5ndWFnZSI6InB0LWJyIiwicGFnZU51bWJlciI6MSwicGFnZVNpemUiOjIwLCJ0cmFkaW5nTmFtZSI6IkFNQkVWU0EifQ==

base64enc::base64decode("eyJsYW5ndWFnZSI6InB0LWJyIiwicGFnZU51bWJlciI6MSwicGFnZVNpemUiOjIwLCJ0cmFkaW5nTmFtZSI6IkFNQkVWU0EifQ==") |>
  rawToChar() |>
  jsonlite::fromJSON()