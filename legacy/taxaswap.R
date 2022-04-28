
load_curves <- function(filePath) {
    widths <- c(6, 3, 2, 8, 2, 5, 15, 5, 5, 1, 14, 1, 5)
    colNames <- c("Identificacao", "Complemento", "TipoRegistro", "Data", "CodCurvaTermo", "CodTaxa", "DescricaoTaxa", "DC", "DU", "SinalTaxa", "Taxa", "CaracteristicaVertice", "CodVertice")

    # taxaSwap <- read.fwf(file=filePath, widths=widths, col.names=colNames)
    taxaSwap <- read_fwf(filePath, widths, col.names = colNames)

    taxaSwap <- within(taxaSwap, {
        DU <- as.integer(DU)
        Data <- as.Date(Data, "%Y%m%d")
        Taxa <- as.numeric(paste0(SinalTaxa, Taxa)) / 10000000
        CodTaxa <- as.factor(gsub(" +", "", CodTaxa))
    })

    obj <- list()
    obj$Data <- taxaSwap
    obj$CodTaxa <- unique(taxaSwap$CodTaxa)

    taxaSwap$SinalTaxa <- NULL

    x <- split(taxaSwap, taxaSwap$CodTaxa)
    obj$dataSplit <- x
    function(curvecode) {
        curve <- obj$dataSplit[[curvecode]][, c("DU", "Taxa")]
        terms <- curve$DU / 252
        rates <- curve$Taxa / 100

        if (sum(!is.na(rates)) < 2) {
            warning("Invalid curve: ", curvecode)
            return(NULL)
        }

        log_price_interpolator <- approxfun(terms, log((1 + rates)^terms), method = "linear")
        function(term) {
            term <- term / 252
            pu <- exp(log_price_interpolator(term))
            pu^(1 / term) - 1
        }
    }
}


curvecodes <- function(curves) {
    e <- environment(curves)
    e$obj$CodTaxa
}


curvedata <- function(cv) {
    e <- environment(cv)
    m <- as.matrix(cbind(e$curve$DU, e$curve$Taxa))
    dimnames(m) <- list(seq(1, dim(e$curve)[1]), c("DU", "Taxa"))
    m
}


curveenv <- function(curves, parent = .GlobalEnv) {
    e <- new.env(parent = parent)
    for (cd in curvecodes(curves)) {
        obj_name <- sprintf("curve_%s", tolower(cd))
        e[[obj_name]] <- curves(cd)
    }
    e
}