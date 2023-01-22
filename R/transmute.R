.apply_to <- function(x) {
  switch(x,
    all = all,
    any = any,
    majority = function(x) {
      .len <- length(x)
      .sum <- sum(x)
      .sum / .len > 0.5
    }
  )
}

rule_result <- function(applied = FALSE, value = NULL) {
  structure(list(applied = applied, value = value), class = "rule_result")
}

match_regex <- function(regex, handler, priority = NA,
                        apply_to = c("any", "all"), na.rm = TRUE) {
  apply_to <- .apply_to(match.arg(apply_to))
  structure(
    list(
      regex = regex, handler = handler, priority = priority,
      apply_to = apply_to, na.rm = na.rm
    ),
    class = c("match_rule", "regex_rule")
  )
}

match_class <- function(class, handler, priority = NA, na.rm = TRUE) {
  structure(
    list(class = class, handler = handler, priority = priority, na.rm = na.rm),
    class = c("match_rule", "class_rule")
  )
}

match_predicate <- function(predicate, handler, priority = NA, na.rm = TRUE) {
  structure(
    list(
      predicate = predicate, handler = handler, priority = priority,
      na.rm = na.rm
    ),
    class = c("match_rule", "predicate_rule")
  )
}

apply_rule <- function(rule, .data) {
  UseMethod("apply_rule")
}

apply_rule.class_rule <- function(rule, .data) {
  if (!is(.data, rule$class)) {
    return(rule_result())
  }
  result <- rule$handler(.data)
  rule_result(TRUE, result)
}

apply_rule.predicate_rule <- function(rule, .data) {
  idx <- rule$predicate(.data)
  if (length(which(idx)) == 0) {
    return(rule_result())
  }
  result <- rule$handler(.data, idx)
  rule_result(TRUE, result)
}

apply_rule.regex_rule <- function(rule, .data) {
  if (!is(.data, "character")) {
    return(rule_result())
  }
  detect <- str_detect(.data, rule$regex)
  apply_to <- rule$apply_to(detect, na.rm = rule$na.rm)
  result <- if (apply_to) {
    rule$handler(
      .data,
      str_match(.data, rule$regex)
    )
  }
  rule_result(apply_to, result)
}

iter_rules <- function(rules) {
  idx <- take(rules, "priority")
  idx <- order(idx)
  rules[idx]
}

composite <- function(...) {
  fs <- list(...)
  function(...) Reduce(function(x, f) f(x), fs, ...)
}

to_date <- function(format = "%Y-%m-%d") {
  function(x, ...) as.Date(strptime(x, format))
}

to_datetime <- function(format = "%Y-%m-%d %H:%M:%S") {
  function(x, ...) as.POSIXct(strptime(x, format))
}

to_dbl <- function(dec = NULL, thousands = NULL, percent = FALSE) {
  .func <- identity
  .mult <- 1
  if (percent) {
    .func <- composite(function(x) sub("\\s*%", "", x), .func)
    .mult <- 0.01
  }
  if (!is.null(dec)) {
    .func <- composite(function(x) sub(dec, ".", x, fixed = TRUE), .func)
  }
  if (!is.null(thousands)) {
    .func <- composite(function(x) gsub(thousands, "", x, fixed = TRUE), .func)
  }
  function(x, ...) as.numeric(.func(x)) * .mult
}

to_int <- function() {
  as.integer
}

as_dbl <- function(x, dec = NULL, thousands = NULL, percent = FALSE) {
  .func <- to_dbl(dec, thousands, percent)
  .func(x)
}

`%or%` <- function(value, other) {
  if (!is.null(value)) value else other
}

setClass(
  "Transmuter",
  representation(envir = "environment", rules = "list"),
  prototype(envir = NULL, rules = NULL)
)

setGeneric("parse_text", function(x, data, ...) standardGeneric("parse_text"))

setGeneric("apply_rules", function(x, data, ...) standardGeneric("apply_rules"))

setMethod(
  "apply_rules",
  signature("Transmuter", "ANY"),
  function(x, data, ...) {
    res <- rule_result()
    for (.rule in iter_rules(x@rules)) {
      res <- apply_rule(.rule, data)
      if (res$applied) {
        return(res$value)
      }
    }
    data
  }
)

setMethod(
  "parse_text",
  signature("Transmuter", "data.frame"),
  function(x, data, ...) {
    rules_res <- lapply(data, function(.data) apply_rules(x, .data))
    do.call("data.frame", c(rules_res,
      stringsAsFactors = FALSE,
      check.names = FALSE
    ))
  }
)

setMethod(
  "parse_text",
  signature("Transmuter", "ANY"),
  function(x, data, ...) apply_rules(x, data)
)

setMethod(
  "print",
  signature(x = "Transmuter"),
  function(x, ...) {
    pl <- take(x@rules, "priority")
    l <- list()
    i <- 1
    for (.po in order(pl)) {
      .names <- names(x@rules)
      .parser <- x@rules[[.po]]
      l[[i]] <- c(
        "name" = .names[.po], "regex" = .parser[[1]],
        "priority" = .parser[["priority"]]
      )
      i <- i + 1
    }
    print.data.frame(as.data.frame(do.call(rbind, l)),
      row.names = FALSE,
      right = FALSE, na.print = "-"
    )
    invisible(x)
  }
)

transmuter <- function(...) {
  objs <- list(...)

  idx <- map_lgl(objs, function(x) is(x, "match_rule"))
  rules <- objs[idx]

  idx <- map_lgl(objs, function(x) is(x, "Transmuter"))
  parents <- objs[idx]
  for (parent in parents) {
    rules <- append(rules, slot(parent, "rules"))
  }

  new("Transmuter", envir = new.env(), rules = rules)
}

transmute_regex <- function(.x, .r, .f, apply_to = c("any", "all")) {
  trm <- transmuter(match_regex(.r, .f, apply_to = apply_to))
  parse_text(trm, .x)
}


.unformat <- function(x, f) {
  x <- lapply(x, f)
  as.data.frame(x, stringsAsFactors = FALSE)
}

unformat <- function(x) .unformat(x, as.character)

unfactor <- function(x) {
  .unformat(x, function(x) {
    if (is.factor(x)) {
      as.character(x)
    } else {
      x
    }
  })
}

take <- function(x, ...) {
  UseMethod("take", x)
}

take.list <- function(x, k, ...) {
  map_chr(x, function(x) {
    v <- x[[k]]
    if (is.null(v)) {
      NA
    } else {
      as.character(v)
    }
  })
}
