
f <- download_marketdata("b3-futures-settlement-prices", refdate = as.Date("2025-01-03"))
df <- read_marketdata(f)

fetch_marketdata("b3-cotahist-daily",
  refdate = bizseq("2025-01-01", "2025-03-10", "Brazil/B3")
)
fetch_marketdata("b3-futures-settlement-prices",
  refdate = bizseq("2025-01-01", "2025-03-10", "Brazil/B3")
)
fetch_marketdata("b3-reference-rates",
  refdate = bizseq("2025-01-01", "2025-03-10", "Brazil/B3"), curve_name = c("DIC", "DOC", "PRE")
)

args_to_df <- function(...) {
  df <- expand.grid(...)
  return(df)
}

args_to_df(refdate = bizseq("2025-01-01", "2025-03-10", "Brazil/B3"), curve_name = c("DIC", "DOC"))

purrr::pmap(x, function(...) {
  row <- list(...)
  # cat(class(row), "\n")
  print(paste("a:", row[["a"]], "d:", row[["d"]]))
})


library(purrr)
library(cli)

# Example data frame
df <- data.frame(a = 1:5, b = letters[1:5])

# Create a progress bar and store its ID
pb <- cli_progress_bar("Processing rows", total = nrow(df))

# Use pmap() with progress updates
result <- df %>%
  pmap(~ {
    # Simulate some work
    Sys.sleep(0.5)
    
    # Update progress
    cli_progress_update(id = pb)
    
    # Example operation
    paste("Processed", ..1, "and", ..2)
  })

# Close the progress bar
cli_progress_done(id = pb)

# Print results
print(result)
