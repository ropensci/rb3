context('convert_to')

test_that('convert indic to csv', {
  res <- convert_to('../../inst/extdata/Indic.txt', output_format='csv')
  expect_true(file.exists(res))
  res <- convert_to('../../inst/extdata/Indic-copy.txt', template='Indic', output_format='csv')
  expect_true(file.exists(res))
})

test_that('convert indic to json', {
  res <- convert_to('../../inst/extdata/Indic.txt', output_format='json')
  expect_true(file.exists(res))
})

