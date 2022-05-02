test_that("cache fcts", {
  
  this_cachedir <- 	cachedir()
  expect_true(class(this_cachedir) == 'character')
  
  clearcache() 
  
  # if passed clearcache(), set true
  expect_true(TRUE)
  
})
