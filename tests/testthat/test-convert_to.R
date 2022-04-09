context('convert_to')

test_that('convert indic to csv', {
  
  f <- system.file('extdata/Indic.txt',
                   package = "rb3")
  
  res <- convert_to(f, output_format='csv')
  expect_true(file.exists(res))
  
  f <- system.file('extdata/Indic-copy.txt',
                   package = "rb3")
  
  res <- convert_to(f, template='Indic', output_format='csv')
  expect_true(file.exists(res))
})

test_that('convert indic to json', {
  
  f <- system.file('extdata/Indic.txt',
                   package = "rb3")
  
  res <- convert_to(f, output_format='json')
  expect_true(file.exists(res))
})

