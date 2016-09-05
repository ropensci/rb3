
context('Handle file: BDIN')

test_that('read file using filename to find template', {
  res <- read_marketdata('../../inst/extdata/BDIN')
  expect_is(res, 'list')
  expect_is(res[[1]], 'data.frame')
})

