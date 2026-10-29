test_that("the example panel has the harmonized schema", {
  d <- pks_example()
  expect_identical(names(d), names(pksR:::harmonized_spec))
  expect_equal(nrow(d), 70)
  expect_identical(attr(d, "data_version"), "example")
})

test_that("rates recomputed from the counts match the published HZ", {
  d <- pks_example()
  r <- pks_rates(d)
  expect_equal(r$hz, d$hz, tolerance = 1e-9)
  # The BKA prints the clearance rate with one decimal
  expect_lt(max(abs(r$clearance_rate - d$clearance_rate)), 0.05 + 1e-9)
  expect_equal(pks_rates(d, per = 1000)$rate, d$hz / 100, tolerance = 1e-9)
})

test_that("an external population replaces the one of the data", {
  d <- pks_example()
  pop <- unique(data.frame(year = d$year, ags = d$ags, population = 1e5))
  r <- pks_rates(d, population = pop)
  expect_equal(r$hz, d$cases)
  expect_error(pks_rates(d, population = pop[-1, ]), "No population")
  expect_error(pks_rates(d, population = rbind(pop, pop[1, ] |> transform(population = 2))), "several values")
  expect_error(pks_rates(d, population = data.frame(x = 1)), "columns")
  expect_error(pks_rates(mtcars), "missing column")
  expect_error(pks_rates(d, per = -1), "positive")
})

test_that("the census-corrected population puts all years on one base", {
  d <- pks_example()
  expect_false(anyNA(d$population_corrected))
  r <- pks_rates(d, population = "corrected")
  expect_equal(r$rate_population, d$population_corrected)
  cases <- dplyr::coalesce(d$cases, d$cases_derived)
  expect_equal(r$hz, cases / d$population_corrected * 1e5)
  # Counts and the published rates stay as they are
  expect_identical(r$cases, d$cases)
  d$population_corrected[1] <- NA
  expect_error(pks_rates(d, population = "corrected"), "census-corrected population")
  d$population_corrected <- NULL
  expect_error(pks_rates(d, population = "corrected"), "census-corrected population")
  expect_error(pks_rates(pks_example(), population = "registers"), "must be")
})

test_that("zero cases give a clearance rate of 0, as in the BKA tables", {
  d <- pks_example()[1:2, ]
  d$cases <- c(0, 10)
  d$cleared <- c(3, 5)
  expect_equal(pks_rates(d)$clearance_rate, c(0, 50))
})

test_that("validation passes on the example and catches broken panels", {
  d <- pks_example()
  expect_true(all(suppressMessages(pks_validate(d))$status == "pass"))
  status <- function(x) {
    v <- suppressMessages(pks_validate(x))
    stats::setNames(v$status, v$check)
  }
  expect_identical(status(rbind(d, d[1, ]))[["uniqueness"]], "fail")
  expect_identical(status(d[d$ags != "11000", ])[["city_states"]], "fail")
  expect_identical(status(d[!(d$ags == "01001" & d$year == 2020), ])[["coverage"]], "fail")
  neg <- d
  neg$cases[1] <- -1
  expect_identical(status(neg)[["counts"]], "fail")
  att <- d
  att$attempts[1] <- att$cases[1] + 1
  expect_identical(status(att)[["counts"]], "fail")
  small <- d
  small$population <- 3500
  expect_identical(status(small)[["population"]], "warn")
  expect_identical(status(d[, -3])[["schema"]], "fail")
})

test_that("offences can be searched by key and label in both languages", {
  expect_identical(pks_offences("435*00")$offence_key, "435*00")
  expect_true(all(grepl("diebstahl", pks_offences("Diebstahl", lang = "de")$label, ignore.case = TRUE)))
  en <- pks_offences(lang = "en")
  expect_equal(nrow(en), nrow(pks_offences(lang = "de")))
  expect_true("Total offences" %in% en$label)
  expect_error(pks_offences(c("a", "b")), "one string")
})

test_that("known breaks are listed", {
  b <- pks_breaks()
  expect_s3_class(b, "tbl_df")
  expect_true(all(c("break_id", "first_year", "comparable") %in% names(b)))
  expect_true(all(b$comparable %in% c("yes", "likely", "unknown", "no")))
})

test_that("the citation names the package, the release and the three sources", {
  local_fake_release()
  ci <- pks_cite()
  expect_s3_class(ci, "bibentry")
  expect_length(ci, 5)
  text <- paste(format(ci, "text"), collapse = " ")
  expect_match(text, "Data version 2026.1")
  expect_match(text, "dl-de/by-2-0", fixed = TRUE)
  expect_match(text, "Bundeskriminalamt")
  expect_match(text, "BBSR")
  expect_match(text, "Destatis")
})

test_that("offline, the citation leaves out the data release", {
  local_fake_release(offline = TRUE)
  expect_warning(ci <- pks_cite(), "not cited")
  expect_length(ci, 4)
})
