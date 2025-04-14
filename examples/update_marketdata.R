
fetch_marketdata("b3-cotahist-yearly", year = c(2024, 2023))

fetch_marketdata("b3-cotahist-daily", refdate = bizseq("2025-01-01", "2025-03-10", "Brazil/B3"))
fetch_marketdata("b3-futures-settlement-prices", refdate = bizseq("2018-01-01", "2025-03-10", "Brazil/B3"))
fetch_marketdata("b3-reference-rates",
  refdate = bizseq("2023-01-01", "2025-03-10", "Brazil/B3"),
  curve_name = c("DIC", "DOC", "PRE")
)
fetch_marketdata("b3-bvbg-086",
  refdate = bizseq("2018-01-01", "2025-03-10", "Brazil/B3")
)
