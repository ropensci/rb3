
CP <- c("CALL", "PUT")
AE <- c("AMERICAN", "EUROPEAN")

premio <- function(file='Premio.txt', split=FALSE) {
  ws <- c(6, 3, 2, 8, 3, 1, 4, 1, 1, 8, 15, 15, 1)
  cn <- c('id_trans', 'cp_trans', 'tp_reg', 'dt_ger', 'cd_mer', 'tp_mer', 'sr', 'tp_opc', 'mod_opc', 'dt_venc',
    'pr_exe', 'pr_ref', 'dec')
  data <- read_fwf(file, ws, col.names=cn)
  data <- within(data, {
    Strike <- as.numeric(pr_exe)/10^as.numeric(dec)
    SpotPrice <- as.numeric(pr_ref)/10^as.numeric(dec)
    ReferenceDate <- as.Date(dt_ger, format="%Y%m%d")
    MaturityDate <- as.Date(dt_venc, format="%Y%m%d")
    Type <- factor(ifelse(tp_opc == "C", CP[1], ifelse(tp_opc == "V", CP[2], NA)), CP)
    InstrumentType <- factor(ifelse(mod_opc == "A", AE[1], ifelse(mod_opc == "E", AE[2], NA)), AE)
    Name <- gsub(" +", "", sr)
  })
  key <- with(data, as.factor(cd_mer))
  data <- data[with(data, order(cd_mer, Type, MaturityDate, Strike)),]
  data <- data[,c('Name', 'ReferenceDate', 'InstrumentType', 'Type', 'MaturityDate', 'Strike', 'SpotPrice')]
  if (split) {
    gs <- split(data, key)
    lapply(gs, function(x) {
      rownames(x) <- seq_len(dim(x)[1])
      x
    })
  } else {
    data
  }
}
