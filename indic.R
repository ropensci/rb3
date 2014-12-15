
load_indic <- function(fname) {

    ws <- c(6, 3, 2, 8, 2, 25, 25, 2, 36)
    cn <- c('id_trans', 'cp_trans', 'tp_reg', 'dt_ger', 'gr_ind', 'cd_ind', 'dc_ind', 'nm_dec', 'fll')
    data <- read_fwf(fname, ws, col.names=cn)
    
    data <- within(data, {
        nm_dec <- as.numeric(nm_dec)
        dc_ind <- as.numeric(dc_ind)/(10^nm_dec)
        dt_ger <- as.Date(dt_ger, format='%Y%m%d')
        cd_ind <- as.factor(str_trim(cd_ind))
    })
    base <- subset(data, dt_ger == max(data$dt_ger))
    base <- split(base$dc_ind, base$cd_ind)
    base <- lapply(base, function(x) x[1])
    
    function(indcode) {
        unlist(base[indcode], use.names=FALSE)
    }
}


