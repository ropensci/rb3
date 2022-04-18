
library(rvest)

url <- "https://www2.bmf.com.br/pages/portal/bmfbovespa/lumis/lum-ajustes-do-pregao-ptBR.asp"

read_html(url) |> html_table()

refdate <- "2022-04-01"
strdate <- format(as.Date(refdate), "%d/%m/%Y")
res <- httr::POST(url, body = list(dData1 = strdate), encode = "form")

doc <- read_html(httr::content(res, as = "text", encoding = "latin1"))
html_element(doc, xpath = "//table[contains(@id, 'tblDadosAjustes')]") |>
  html_table()
