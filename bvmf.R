
.get_curve_url <- function(refDate, item='PRE') {
    url <- 'http://www2.bmf.com.br/pages/portal/bmfbovespa/boletim1/TxRef1.asp?Data=%s&Data1=%s&slcTaxa=%s'
    sprintf(url,
        format(as.Date(refDate), '%d/%m/%Y'),
        format(Sys.Date(), '%Y%m%d'),
        item)
}

get_curve <- function (refDate, item='PRE') {
    refDate <- as.Date(refDate)
    url <- .get_curve_url(refDate, item)
    doc <- htmlTreeParse(url, useInternalNodes=TRUE)

    tit <- xpathSApply(doc, "//td[contains(@class, 'tabelaTitulo')]", xmlValue)

    num <- xpathSApply(doc, "//td[contains(@class, 'tabelaConteudo')]",
        function(x) gsub('[\r\n \t]+', '', xmlValue(x)))

    num <- sapply(num, function(x) {
        as.numeric(gsub(',', '.', x))
    }, USE.NAMES=FALSE)

    terms <- bizdays(refDate, refDate + num[c(TRUE, FALSE, FALSE)])/252
    rates <- num[c(FALSE, TRUE, FALSE)]/100

    log_price_interpolator <- approxfun(terms, log((1 + rates)^terms), method='linear')
    function (term) {
        pu <- exp(log_price_interpolator(term))
        pu^(1/term) - 1
    }
}
