context('Handle file: PUWEB.txt')

test_that('read file using filename to find template', {
  res <- read_marketdata('../../inst/extdata/PUWEB.TXT')
  expect_is(res, 'list')
  expect_is(res[[1]], 'data.frame')
})

