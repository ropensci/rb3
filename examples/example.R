
library(fExoticOptions)
library(functional)
library(stringr)
library(bizdays)
library(ggplot2)
library(reshape)

cenv <- curveenv(load_curves("TaxaSwap.txt"))
assign('indix', load_ind('Indic.txt'), envir=cenv)
environment(load_surfaces) <- cenv
surfs <- load_surfaces('SupVol.txt')
surf <- surfs('IDI')

surf_data <- environment(surfs)$surfs$IDI

ggplot(data=subset(surf_data, DU == 14), aes(x=Delta, y=Vol)) + geom_point()

# bizdays('2014-12-15', adjust.next('2015-01-01'))

# print(surf())

# surfcodes <- function(surfs) {
#     e <- environment(surfs)
#     as.character(unique(e$supVol$CodAtivo))
# }

ws <- c(6, 3, 2, 8, 3, 1, 4, 1, 1, 8, 15, 15, 1)
cn <- c('id_trans', 'cp_trans', 'tp_reg', 'dt_ger', 'cd_mer', 'tp_mer', 'sr', 'tp_opc', 'mod_opc', 'dt_venc', 'pr_exe',
  'pr_ref', 'dec')
data <- read_fwf('Premio.txt', ws, col.names=cn)

data <- within(data, {
  pr_exe <- as.numeric(pr_exe)/10^as.numeric(dec)
  pr_ref <- as.numeric(pr_ref)/10^as.numeric(dec)
  dt_venc <- as.Date(dt_venc, format="%Y%m%d")
  Strike <- pr_exe
  Premium <- pr_ref
  SpotPrice <- pr_ref
  BusinessDays <- bizdays('2014-12-12', dt_venc)
  Rate <- log(1 + cenv$curve_pre(BusinessDays))
  Underlying <- cenv$indix('IDI-09')*exp(Rate*BusinessDays/252)
  TheoPrice <- ifelse(Strike>Underlying, Strike-Underlying, 0)
})

idi_smp <- subset(data, cd_mer == 'IDI' & dt_venc == '2015-01-02')

prices <- melt(idi_smp[,c('Strike', 'SpotPrice', 'TheoPrice')], id=c('Strike'))

ggplot(data=prices, aes(x=Strike, y=value, colour=variable)) + geom_point() +
  geom_vline(xintercept=idi_smp$Underlying[1], colour='red')

idi_smp <- within(idi_smp, {
  Strike <- pr_exe
  BusinessDays <- bizdays('2014-12-12', '2015-01-02')
  Rate <- log(1 + cenv$curve_pre(BusinessDays))
  Underlying <- cenv$indix('IDI-09')*exp(Rate*BusinessDays/252)
})

surf_data_smp <- subset(surf_data, DU == 14)

ggplot(data=surf_data_smp, aes(x=Delta, y=Vol)) + geom_point()
ggplot(data=surf_data_smp, aes(x=Strike, y=Vol)) + geom_point(colour='red') +
  geom_point(data=idi_smp, aes(x=Strike, y=0.006))

surf_data_smp <- surf_data_smp[order(surf_data_smp$Strike),]

smile <- approxfun(surf_data_smp$Strike, surf_data_smp$Vol)
idi_smp$Strike <= 174755.0
idi_smp$Strike >= 174770.4

plot(surf_data_smp$Strike, surf_data_smp$Vol)
points(surf_data_smp$Strike, col='red')

surf_data_smp <- within(surf_data_smp, {
  Underlying <- 174763.3
  Premium <- Black76Option('c', Underlying, Strike, (DU-1)/252, RiskFreeRate, Vol)@price
})

ggplot(data=surf_data_smp, aes(x=Strike, y=Premium)) + geom_point()


