library(httr)
library(XML)
library(functional)

get_curve_url <- function(refDate, item='PRE') {
    url <- 'http://www2.bmf.com.br/pages/portal/bmfbovespa/boletim1/TxRef1.asp?Data=%s&Data1=%s&slcTaxa=%s'
    sprintf(url,
        format(as.Date(refDate), '%d/%m/%Y'),
        format(Sys.Date(), '%Y%m%d'),
        item)
}

clean_spaces <- function(x) gsub('[\r\n \t]+', '', x)

period2dot <- function(x) gsub(',', '.', x)

extract_int <- function(x) sub("^(\\d+).*$", "\\1", x)

clean_numeric <- Compose(
  XML::xmlValue,
  clean_spaces,
  period2dot,
  as.numeric
)

clean_integer <- Compose(
  XML::xmlValue,
  clean_spaces,
  extract_int,
  as.integer
)


clean_text <- Compose(
  XML::xmlValue,
  clean_spaces
)


download_data <- function(url, dest) {
    req <- GET(url)
    text <- content(req, as='text')
    writeLines(text, dest)
    NULL
}


parse_data <- function (file) {
    doc <- XML::htmlTreeParse(file, useInternalNodes=TRUE)
    itm <- XML::xpathSApply(doc, "//td[contains(@class, 'tabelaItem')]", clean_text)
    num <- XML::xpathSApply(doc, "//td[contains(@class, 'tabelaConteudo')]", clean_numeric)
    list(columns=length(itm) + 1, data=num)
}


get_curve_data <- function(refDate, item='PRE', dest=tempfile()) {
    refDate <- as.Date(refDate)
    url <- get_curve_url(refDate, item)
    download_data(url, dest)
    list(file=dest, refDate=refDate, item=item)
}


get_curve <- function(curve_data) {
    data <- parse_data(curve_data$file)
    data <- matrix(data$data, nrow=data$columns)
    list(curve=curve_data$item, terms=curve_data$refDate + data[1,] , rates=data[2,]/100)
}


gen_log_price_interpolator <- function(rates, terms) approxfun(terms, log((1 + rates)^terms), method='linear')


gen_flat_forward_interpolator <- function(price_interp) {
    function (term) {
        pu <- exp(price_interp(term))
        pu^(1/term) - 1
    }
}

# log_price_interpolator <- gen_log_price_interpolator(rates, terms)
# gen_flat_forward_interpolator(log_price_interpolator)
