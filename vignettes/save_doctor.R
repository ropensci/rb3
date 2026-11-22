
options(rb3.cachedir = file.path(tempdir(), "rb3-doctor-vignette"))
library(bizdays)
devtools::load_all()

# capture what rb3_doctor() prints, to show it in the vignette
doctor_output <- function(...) {
  msgs <- character()
  res <- withCallingHandlers(rb3_doctor(...), message = function(m) {
    msgs <<- c(msgs, sub("\n$", "", conditionMessage(m)))
    invokeRestart("muffleMessage")
  })
  list(result = res, output = msgs)
}

# January 2024, skipping 15 to 17 on purpose
dates <- bizseq("2024-01-02", "2024-01-31", "Brazil/ANBIMA")
dates <- dates[!dates %in% as.Date(c("2024-01-15", "2024-01-16", "2024-01-17"))]
fetch_marketdata("b3-reference-rates", refdate = dates)

doc_input <- doctor_output("b3-reference-rates")
doc_to <- doctor_output("b3-reference-rates", calendar = "Brazil/B3", to = "2024-02-09")
doc_staging <- doctor_output("b3-reference-rates", layer = "staging", calendar = "Brazil/B3")

# Christmas week 2024: B3 was closed on Dec 24, the Brazil/ANBIMA calendar is open
fetch_marketdata("b3-reference-rates", refdate = bizseq("2024-12-23", "2024-12-27", "Brazil/ANBIMA"))
doc_xmas_anbima <- doctor_output("b3-reference-rates", from = "2024-12-23", to = "2024-12-27")
doc_xmas_b3 <- doctor_output("b3-reference-rates", from = "2024-12-23", to = "2024-12-27", calendar = "Brazil/B3")

doc_health <- doctor_output()

save(doc_health, doc_input, doc_to, doc_staging, doc_xmas_anbima, doc_xmas_b3, file = "vignettes/data_doctor.RData")
