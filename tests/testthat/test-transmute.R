test_that("it should create a regex match_rule", {
  rule <- match_regex("\\d", as.integer)
  expect_s3_class(rule, "match_rule")
  expect_s3_class(rule, "regex_rule")
})

test_that("it should apply a regex_rule", {
  rule <- match_regex("^\\d+$", as.integer)

  result <- apply_rule(rule, "11")
  expect_s3_class(result, "rule_result")
  expect_true(result$applied)
  expect_equal(result$value, 11)

  result <- apply_rule(rule, 11)
  expect_false(result$applied) # regex_rule only handles character data

  result <- apply_rule(rule, "a")
  expect_false(result$applied)

  result <- apply_rule(rule, "1.1")
  expect_false(result$applied)
})

test_that("it should apply a regex_rule with a group", {
  rule <- match_regex("delta (\\d+)", function(data, match) {
    as.integer(match[, 2])
  })

  res <- apply_rule(rule, c("delta 50", "delta 25"))
  expect_equal(res$value, c(50, 25))

  res <- apply_rule(rule, c("delta 50", NA, "delta 25"))
  expect_equal(res$value, c(50, NA, 25))
})

test_that("it should apply a regex_rule
if at least one element has been matched", {
  rule <- match_regex("\\d+", function(data, match) {
    as.integer(match[, 1])
  }, apply_to = "any")

  res <- apply_rule(rule, c("50", "25", "W"))
  expect_equal(res$value, c(50, 25, NA))
})

test_that("it should apply a regex_rule if all elements match", {
  rule <- match_regex("\\d+", function(data, match) {
    as.integer(match[, 1])
  }, apply_to = "all")

  res <- apply_rule(rule, c("50", "25", "W"))
  expect_false(res$applied)
})

test_that("it should apply a regex_rule if all elements match", {
  rule <- match_regex("\\d+", function(data, match) {
    as.integer(match[, 1])
  }, apply_to = "all")

  res <- apply_rule(rule, c("50", "25", "W"))
  expect_false(res$applied)
})

test_that("it should iterate thru a list of rules ", {
  rules <- list(
    match_regex("NA", identity),
    match_regex("1", identity, priority = 1),
    match_regex("2", identity, priority = 2),
    match_regex("NA2", identity)
  )

  rules <- iter_rules(rules)
  expect_equal(take(rules, "regex"), c("1", "2", "NA", "NA2"))
})

test_that("it should create a check class_rule", {
  rule <- match_class("Date", as.character)
  expect_s3_class(rule, "match_rule")
  expect_s3_class(rule, "class_rule")
})

test_that("it should apply a class_rule", {
  rule <- match_class("Date", as.character)

  result <- apply_rule(rule, "11")
  expect_s3_class(result, "rule_result")
  expect_false(result$applied)

  result <- apply_rule(rule, as.Date("2015-11-21"))
  expect_true(result$applied)
  expect_equal(result$value, "2015-11-21")
})

test_that("it should apply a pred_rule", {
  rule <- match_predicate(is.na, function(x, idx, ...) {
    x[idx] <- 0
    x
  })

  result <- apply_rule(rule, "11")
  expect_s3_class(result, "rule_result")
  expect_false(result$applied)

  result <- apply_rule(rule, NA)
  expect_true(result$applied)
  expect_equal(result$value, 0)

  result <- apply_rule(rule, c(NA, 1))
  expect_equal(result$value, c(0, 1))
})

test_that("it should convert character to date using a handler", {
  h <- to_date("%Y-%m-%d")
  expect_equal(h("2017-01-01"), as.Date("2017-01-01"))
})

test_that("it should convert character to numeric using a handler", {
  h <- to_dbl()
  expect_equal(h("1"), 1)
  expect_type(h("1"), "double")
  h <- to_dbl(dec = ",")
  expect_equal(h("1,5"), 1.5)
  h <- to_dbl(dec = ",", thousands = ".")
  expect_equal(h("1.001,5"), 1001.5)
  h <- to_dbl(dec = ",", thousands = ".")
  expect_equal(h("1.001.001,5"), 1001001.5)
  h <- to_dbl(dec = ",", percent = TRUE)
  expect_equal(h("5,5 %"), 0.055)
  h <- to_dbl(percent = TRUE)
  expect_equal(h("5.5 %"), 0.055)
})

test_that("it should convert character to numeric using functions", {
  expect_equal(as_dbl("1"), 1)
  expect_type(as_dbl("1"), "double")
  expect_equal(as_dbl("1,5", dec = ","), 1.5)
  expect_equal(as_dbl("1.001,5", dec = ",", thousands = "."), 1001.5)
  expect_equal(as_dbl("1.001.001,5", dec = ",", thousands = "."), 1001001.5)
  expect_equal(as_dbl("5,5 %", dec = ",", percent = TRUE), 0.055)
  expect_equal(as_dbl("5.5 %", percent = TRUE), 0.055)
})

test_that("it should create a transmuter using Transmuter constructor", {
  trm <- new("Transmuter", envir = new.env(), rules = list())
  expect_s4_class(trm, "Transmuter")
  expect_equal(parse_text(trm, 1), 1)
  expect_equal(parse_text(trm, "1"), "1")
})

test_that("it should create a transmuter with one rule", {
  trm <- new("Transmuter",
    envir = new.env(),
    rules = list(
      match_regex("^\\d+$", as.integer)
    )
  )
  expect_true(is(trm, "Transmuter"))
  expect_equal(parse_text(trm, "1"), 1)
  expect_equal(parse_text(trm, "a"), "a")
  expect_equal(parse_text(trm, "1.1"), "1.1")
})

test_that("it should create a transmuter with one rule using the constructor", {
  trm <- transmuter(
    match_regex("^\\d+$", as.integer)
  )
  expect_true(is(trm, "Transmuter"))
  expect_equal(parse_text(trm, "1"), 1)
  expect_equal(parse_text(trm, "a"), "a")
  expect_equal(parse_text(trm, "1.1"), "1.1")
})

test_that("it should transform a data.frame", {
  trm <- transmuter(
    match_regex("^(A|E)$", function(text, match) {
      factor(text, levels = c("A", "E"), labels = c("American", "European"))
    }),
    match_regex("^\\d+$", as.integer),
    match_regex("^\\d{8}$", function(text, match) {
      as.Date(text, format = "%Y%m%d")
    }, priority = 1)
  )

  df <- data.frame(
    type = c("A", "E"),
    `strike price` = c("12", "20"),
    spot = c(12.2, 19.8),
    series = c("ABC1", "ABC2"),
    maturity = c("20160229", "20160215"),
    stringsAsFactors = FALSE,
    check.names = FALSE
  )
  .names <- names(df)
  df <- parse_text(trm, df)
  expect_equal(
    unname(vapply(df, class, "")),
    c("factor", "integer", "numeric", "character", "Date")
  )
  expect_equal(names(df), .names)
})

test_that("it should parse values considering priority", {
  trm <- transmuter(
    match_regex("\\d+", as.integer),
    match_regex("\\d{8}", function(text, match) {
      as.Date(text, format = "%Y%m%d")
    }, priority = 1)
  )
  expect_equal(parse_text(trm, "1"), 1)
  expect_equal(parse_text(trm, "20100101"), as.Date("2010-01-01"))
})

test_that("it should inherit parser", {
  trm1 <- transmuter(
    match_regex("^\\d+$", function(text, match) as.integer(text))
  )

  expect_true(is.character(parse_text(trm1, "E")))
  expect_true(is.integer(parse_text(trm1, "10")))
  expect_true(parse_text(trm1, "10") == 10)

  trm2 <- transmuter(
    match_regex("^A|E$", function(text, match) {
      factor(text, levels = c("A", "E"), labels = c("American", "European"))
    }),
    trm1
  )

  expect_true(is.factor(parse_text(trm2, "E")))
  expect_equal(as.character(parse_text(trm2, "E")), "European")
  expect_true(is.integer(parse_text(trm2, "10")))
  expect_true(parse_text(trm2, "10") == 10)
})

test_that("it should parse sign", {
  trm <- transmuter(
    match_regex("\\+|-", function(text, match) {
      idx <- text == "-"
      x <- rep(1, length(text))
      x[idx] <- -1
      x
    })
  )
  expect_equal(parse_text(trm, "+"), 1)
  expect_equal(parse_text(trm, "-"), -1)
  expect_equal(parse_text(trm, c("-", "+")), c(-1, 1))
})

test_that("it should create a transmuter with a match_class rule", {
  trm <- transmuter(
    match_class("Date", as.character)
  )
  expect_equal(parse_text(trm, "1"), "1")
  expect_equal(parse_text(trm, as.Date("2015-11-21")), "2015-11-21")
})


test_that("it should create a transmuter with a match_predicate rule", {
  trm <- transmuter(
    match_predicate(is.na, function(x, idx, ...) {
      x[idx] <- 0
      x
    })
  )
  expect_equal(parse_text(trm, "1"), "1")
  expect_equal(parse_text(trm, NA), 0)
  expect_equal(parse_text(trm, c(NA, 1)), c(0, 1))

  df <- data.frame(
    var = c(NA, 1)
  )
  df <- parse_text(trm, df)
  expect_equal(df$var, c(0, 1))
})

test_that("it should parse_text data with parse_text function", {
  trm <- transmuter(
    match_regex("^\\d+$", as.integer)
  )
  expect_equal(parse_text(trm, "1"), 1)
  expect_equal(parse_text(trm, "a"), "a")
  expect_equal(parse_text(trm, "1.1"), "1.1")
})

test_that("it should parse_text data with direct transmute_regex function", {
  expect_equal(transmute_regex("1", "^\\d+$", as.integer), 1)
  expect_type(transmute_regex("1", "^\\d+$", as.integer), "integer")
  expect_equal(transmute_regex("a", "^\\d+$", as.integer), "a")
  expect_equal(transmute_regex("1.1", "^\\d+$", as.integer), "1.1")
})

test_that("convert all data.frame columns to character", {
  df <- data.frame(
    type = c("A", "E"),
    strike = c("12", "20"),
    spot = c(12.2, 19.8),
    series = c("ABC1", "ABC2"),
    stringsAsFactors = FALSE
  )
  expect_true(all(vapply(unformat(df), class, "") == "character"))
})

test_that("convert all data.frame factors to character", {
  df <- data.frame(
    type = c("A", "E"),
    strike = c("12", "20"),
    spot = c(12.2, 19.8),
    series = c("ABC1", "ABC2")
  )
  expect_equal(
    unname(vapply(unfactor(df), class, "")),
    c("character", "character", "numeric", "character")
  )
})
