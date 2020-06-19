context('Handle file: Indic.txt')

test_that('read file using filename to find template', {
  res <- read_marketdata('../../inst/extdata/Indic.txt')
  expect_is(res, 'data.frame')
})

test_that('read file by template name', {
  res <- read_marketdata('../../inst/extdata/Indic-copy.txt', template='Indic')
  classes <- c("character", "character", "character", "Date", "character",
  "character", "numeric", "numeric", "character")
  expect_is(res, 'data.frame')
})

