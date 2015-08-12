


# indic <- function() {
#     that <- list(
#         filename='Indic.txt',
#         format='fwf',
#         widths=c(6, 3, 2, 8, 2, 25, 25, 2, 36),
#         colnames=c('id_trans', 'comp_trans', 'tp_reg', 'dt_ger', 'grupo_ind',
#             'cd_ind', 'dc_ind', 'nm_dec', 'filler')
#     )
#     structure(that, class=c('indic', 'template'))
# }
#
# read_file.indic <- function(template, filename) {
#     read_fwf(filename, template$widths, colnames=template$colnames)
# }
#
# format_data.indic <- function(df) {
#     within(df, {
#         nm_dec <- as.numeric(nm_dec)
#         dc_ind <- as.numeric(dc_ind)/(10^nm_dec)
#         dt_ger <- as.Date(dt_ger, format='%Y%m%d')
#         cd_ind <- str_trim(cd_ind)
#     })
# }
#
# # ----
#
