
library(fOptions)

look_up_letters <- list('á'='a', 'Á'='A', 'ç'='c', 'Ç'='C')

lookup_names <- list("ACUCAR"="ACF", "BOI-GORDO"="BGI", "CAFE-ARABICA"="ICF", "DOLAR"="DOL", "DOLAR-COM-AJU"="DOA",
  "ETANOL"="ETH", "IBOVESPA"="IND", "MILHO-FINANCEIRO"="CCM", "OURO"="OZ1", "SOJA-ESALQ"="SFI")

supvol <- function(file='SupVol.txt') {
  data <- read.table(file, sep=';', skip=1, strip.white=TRUE,
    col.names=c('cd_mer_delta', 'tx_desc', 'dc_du', 'dc_dc', 'dc_vola'))
    
  data <- within(data, {
    BusinessDays <- as.integer(dc_du)
    CurrentDays <- as.integer(dc_dc)
    Volatility <- as.numeric(dc_vola)/10000000
    Delta <- as.integer(gsub("^.* ([0-9]+)$", "\\1", tx_desc))
    cd_ativo <- gsub("^VOL (.+) DELTA [0-9]+$", "\\1", tx_desc, ignore.case=TRUE)
    cd_ativo <- gsub(" +", "-", cd_ativo)
    cd_ativo <- gsub("Ç", "C", cd_ativo)
    cd_ativo <- toupper(cd_ativo)
    # cd_ativo <- unlist(lookup_names[cd_ativo], use.names=FALSE)
    cd_ativo <- sapply(cd_ativo, function(x) {
      name <- lookup_names[[x]]
      if (is.null(name)) x else name
    })
  })
  
  data <- data[with(data, order(BusinessDays, Delta)),]
  cd_ativo <- with(data, as.factor(cd_ativo))
  
  lapply(split(data[,c('Delta', 'BusinessDays', 'CurrentDays', 'Volatility')], cd_ativo), function(x) {
    rownames(x) <- seq_len(dim(x)[1])
    x
  })
}

supvol1 <- function(file='SupVol.txt') {
    supVol <- read.table(file, sep=';', skip=1, strip.white=TRUE,
        col.names=c('cd_mer_delta', 'tx_desc', 'dc_du', 'dc_dc', 'dc_vola'))
    
    supVol <- within(supVol, {
        DU <- as.numeric(dc_du)
        DC <- as.numeric(dc_dc)
        Vol <- as.numeric(dc_vola)/10000000
        CodAtivo <- as.factor(substr(cd_mer_delta, 1, 2))
        CodDelta <- as.factor(substr(cd_mer_delta, 3, 3))
        Ativo <- gsub("^VOL (.+) DELTA [0-9]+$", "\\1", tx_desc, ignore.case=TRUE)
        Delta <- as.numeric(gsub("^.* ([0-9]+)$", "\\1", tx_desc))
    })
    
    supVolLite <- subset(supVol, select=c('DU', 'Delta', 'Vol'))
    surfs <- split(supVolLite, supVol$CodAtivo)
    
    # DOL surface
    surfs[['DOL']] <- within(surfs[['DL']], {
        RiskFreeRate <- log(1 + curve_pre(DU))
        CouponRate <- log(1 + curve_dol(DU))
        T <- DU/252
        Underlying <- indix('DOL-T1')*exp((RiskFreeRate - CouponRate)*T)
        v <- Vol/100
        d <- Delta/100
        Strike <- Underlying*exp(-qnorm(d*exp(CouponRate*T))*v*sqrt(T) + v*v*T/2)
        rm(T, v, d)
    })
    
    # IBV surface
    surfs[['IBV']] <- within(surfs[['IN']], {
        RiskFreeRate <- log(1 + curve_pre(DU))
        CouponRate <- log(1 + curve_cyi(DU))
        T <- DU/252
        Underlying <- indix('IBV-PF')*exp((RiskFreeRate - CouponRate)*T)
        v <- Vol/100
        d <- Delta/100
        Strike <- Underlying*exp(-qnorm(d*exp(CouponRate*T))*v*sqrt(T) + v*v*T/2)
        rm(T, v, d)
    })
    
    # IBV surface
    surfs[['IBX']] <- within(surfs[['IN']], {
        RiskFreeRate <- log(1 + curve_pre(DU))
        CouponRate <- log(1 + curve_cyi(DU))
        T <- DU/252
        Underlying <- indix('IBX-PF')*exp((RiskFreeRate - CouponRate)*T)
        v <- Vol/100
        d <- Delta/100
        Strike <- Underlying*exp(-qnorm(d*exp(CouponRate*T))*v*sqrt(T) + v*v*T/2)
        rm(T, v, d)
    })
    
    # IDI surface
    surfs[['IDI']] <- within(surfs[['TS']], {
        RiskFreeRate <- log(1 + curve_pre(DU))
        T <- DU/252
        Underlying <- indix('IDI-09')*exp(RiskFreeRate*T)
        v <- Vol/100
        d <- Delta/100
        Strike <- Underlying*exp(-qnorm(d*exp(RiskFreeRate*T))*v*sqrt(T) + v*v*T/2)
        rm(T, v, d)
    })
    
    # ISE surface
    surfs[['ISE']] <- within(surfs[['TS']], {
        RiskFreeRate <- log(1 + curve_pre(DU))
        T <- DU/252
        Underlying <- indix('ISE-05')*exp(RiskFreeRate*T)
        v <- Vol/100
        d <- Delta/100
        Strike <- Underlying*exp(-qnorm(d*exp(RiskFreeRate*T))*v*sqrt(T) + v*v*T/2)
        rm(T, v, d)
    })
    
    # IBV surface
    surfs[['BOV']] <- within(surfs[['IN']], {
        RiskFreeRate <- log(1 + curve_pre(DU))
        T <- DU/252
        Underlying <- indix('BOV-PF')*exp(RiskFreeRate*T)
        v <- Vol/100
        d <- Delta/100
        Strike <- Underlying*exp(-qnorm(d)*v*sqrt(T) + v*v*T/2)
        rm(T, v, d)
    })
    
    surfcodes <- c('DOL', 'IBV', 'IBX', 'IDI', 'ISE', 'BOV')
    
    function(surfcode) {
        surf <- surfs[[surfcode]]
        surf <- surf[with(surf, order(DU, Delta)),]
        # surf <- surf[!is.na(surf$Strike),c('DU', 'Strike', 'Vol')]
        surf <- surf[!is.na(surf$Strike)|!is.nan(surf$Strike),c('DU', 'Strike', 'Vol')]
        strikes <- sort(unique(surf$Strike))
        surf <- split(surf, surf$DU)
        surf <- lapply(surf, function(x) with(x, {
            cr <- approx(Strike, Vol, xout=strikes, method='linear')
            vol <- cr$y
            m <- which.min(is.na(vol))
            if (m > 1)
                vol[1:(m-1)] <- vol[m]
            m <- which.max(is.na(vol))
            if (m > 1)
                vol[m:length(vol)] <- vol[m-1]
            f <- approxfun(strikes, vol, method='linear')
            function (k) {
                ifelse(k >= max(strikes), max(strikes),
                    ifelse(k <= min(strikes), min(strikes), f(k)))
            }
        }))
        
        function(terms, strikes) {
            if (length(terms) > 1) {
                tss <- sapply(surf, function(f) f(strikes))
                .terms <- as.numeric(colnames(tss))
                apply(cbind(terms, tss), 1, function(x) {
                    if (sum(!is.na(x)) <= 2 || is.na(x[1])) return(NA)
                    approx(.terms, x[-1], x[1])$y
                })
            } else {
                ts <- lapply(surf, function(f) f(strikes))
                ts[sapply(ts, is.na)] <- NULL
                approx(as.numeric(names(ts)), unlist(ts), terms)$y
            }
        }
    }
}

surfcodes <- function(surfs) {
    e <- environment(surfs)
    e$surfcodes
}

surfenv <- function(surfs, envir=parent.frame()) {
    for (cd in surfcodes(surfs)) {
        obj_name <- sprintf('surf_%s', tolower(cd))
        assign(obj_name, surfs(cd), envir=envir)
    }
}

