test_that("population and area weights are put side by side", {
  local_fake_release()
  pop <- suppressMessages(pks_get(years = 2019:2021, offence = "total"))
  expect_message(w <- pks_compare_weights(pop), "differ between population and area weights")
  expect_named(w, c("year", "ags", "region_name", "offence_key", "estimated", "cases_population",
                    "cases_area", "difference", "relative_difference", "hz_population", "hz_area"))
  expect_identical(nrow(w), nrow(pop))
  # The comparison downloads the area panel of the same request
  area <- suppressMessages(pks_get(years = 2019:2021, offence = "total", weights = "area"))
  i <- match(paste(w$year, w$ags), paste(area$year, area$ags))
  expect_equal(w$cases_area, area$cases[i])
  expect_equal(w$difference, w$cases_area - w$cases_population)
  # Only split districts differ: the Wartburgkreis gives a share to 16064 in
  # 2024. (The fixture holds five districts, without 16064, so national
  # totals cannot be checked here; pksR-data checks their conservation.)
  differs <- abs(w$difference) > 1e-6
  expect_true(any(differs))
  expect_true(all(w$estimated[differs]))
  expect_identical(unique(w$ags[differs]), "16063")
})

test_that("starting from area weights gives the same comparison", {
  local_fake_release()
  pop <- suppressMessages(pks_get(years = 2020, offence = "total"))
  area <- suppressMessages(pks_get(years = 2020, offence = "total", weights = "area"))
  a <- suppressMessages(pks_compare_weights(pop, other = area))
  b <- suppressMessages(pks_compare_weights(area, other = pop))
  expect_identical(a, b)
})

test_that("identical panels are reported as identical", {
  d <- pks_example()
  other <- d
  attr(other, "weights") <- "area"
  expect_message(w <- pks_compare_weights(d, other = other), "same values")
  expect_true(all(w$difference == 0, na.rm = TRUE))
})

test_that("wrong inputs are refused", {
  d <- pks_example()
  published <- d
  attr(published, "weights") <- NA_character_
  expect_error(pks_compare_weights(published), "population or area weights")
  expect_error(pks_compare_weights(d, other = d), "must have area weights")
  other <- d[-1, ]
  attr(other, "weights") <- "area"
  expect_error(pks_compare_weights(d, other = other), "same years, districts")
  expect_error(pks_compare_weights(mtcars), "must be a tibble")
})
