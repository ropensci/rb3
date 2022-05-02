test_that("transmute", {
  
  expect_true(class(rule_result()) == "rule_result")
  
  expect_true(
    class(transmuter(list(x = 1))) == "Transmuter"
    )
  
  print(transmuter(list(x = 1)))
  
  fct1 <- to_dbl(percent = TRUE)
  fct1 <- to_dbl(percent = FALSE)
  as_dbl(10, percent = TRUE)
  to_int()
  `%or%`(TRUE, FALSE)
  
})

