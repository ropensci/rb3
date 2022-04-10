
flatten_names <- function(nx) {
  for (ix in seq_along(nx)) {
    if (nx[ix] != "") {
      last_name <- nx[ix]
    }
    nx[ix] <- last_name
  }
  x <- nx |> stringr::str_match("^...")
  as.vector(x)
}

code2month <- function(x) {
  m <- c(
    F = 1, G = 2, H = 3, J = 4, K = 5, M = 6,
    N = 7, Q = 8, U = 9, V = 10, X = 11, Z = 12
  )
  m[x]
}

maturity2date <- function(x, expr = "first day") {
  year <- as.integer(stringr::str_sub(x, 2)) + 2000
  month <- code2month(stringr::str_sub(x, 1, 1))
  month <- stringr::str_pad(month, 2, pad = "0")
  bizdays::getdate(expr, paste0(year, "-", month), "Brazil/ANBIMA")
}

#' Get futures prices from trading session settlements page
#'
#' Scrape page <https://www.b3.com.br/en_us/market-data-and-indices/data-services/market-data/historical-data/derivatives/trading-session-settlements/>
#' to get futures prices.
#'
#' @param refdate reference date used to obtain futures prices.
#'
#' If `refdate` is not provided the last available date is returned, otherwise
#' the provided date is used to fetch data.
#'
#' @return `data.frame` with futures prices.
#'
#' @examples
#' df <- futures_get()
#' @export
futures_get <- function(refdate = NULL) {
  url <- "https://www2.bmf.com.br/pages/portal/bmfbovespa/lumis/lum-ajustes-do-pregao-ptBR.asp"

  if (is.null(refdate)) {
    res <- httr::GET(url)
  } else {
    strdate <- format(as.Date(refdate), "%d/%m/%Y")
    res <- httr::POST(url, body = list(dData1 = strdate), encode = "form")
  }

  html <- httr::content(res, as = "text", encoding = "latin1")
  mtx <- stringr::str_match(html, "Atualizado em: (\\d{2}/\\d{2}/\\d{4})")
  refdate <- as.Date(mtx[1, 2], "%d/%m/%Y")
  doc <- xml2::read_html(html, encoding = "latin1")
  tbl <- xml2::xml_find_all(doc, "//table[contains(@id, 'tblDadosAjustes')]")

  if (length(tbl) == 0) {
    return(NULL)
  }

  txt <- xml2::xml_text(xml2::xml_find_all(tbl[[1]], "//td"))
  txt <- stringr::str_trim(txt)

  tibble(
    refdate = as.Date(refdate),
    commodity = flatten_names(txt[c(T, F, F, F, F, F)]),
    maturity_code = txt[c(F, T, F, F, F, F)],
    price_previous = as_dbl(txt[c(F, F, T, F, F, F)], ",", "."),
    price = as_dbl(txt[c(F, F, F, T, F, F)], ",", "."),
    change = as_dbl(txt[c(F, F, F, F, T, F)], ",", ".")
  ) |>
    mutate(
      symbol = paste0(commodity, maturity_code)
    ) |>
    select(
      refdate, symbol, maturity_code,
      price_previous, price, change
    )
}