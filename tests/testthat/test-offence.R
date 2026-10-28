map <- pksR:::offence_map_snapshot

test_that("names are compared without capitals, spaces and umlauts", {
  expect_identical(pksR:::normalize_name("K\u00f6rperverletzung"), "koerperverletzung")
  expect_identical(pksR:::normalize_name("  Total Offences "), "total_offences")
  expect_identical(pksR:::normalize_name("Stra\u00dfenkriminalit\u00e4t"), "strassenkriminalitaet")
})

test_that("an offence is found by key, alias or full label in both languages", {
  r <- function(x) suppressMessages(pksR:::resolve_offences(x, map))
  expect_identical(r("435*00"), "435*00")
  expect_identical(r("residential_burglary"), "435*00")
  expect_identical(r("wohnungseinbruch"), "435*00")
  expect_identical(r("Total offences"), "------")
  expect_identical(r("Straftaten insgesamt"), "------")
  expect_identical(r("K\u00f6rperverletzung"), "220000")
  expect_identical(r(c("total", "fraud", "total")), c("------", "510000"))
})

test_that("a part of a label selects every matching key and says which", {
  expect_message(keys <- pksR:::resolve_offences("einbruch", map), "matches 2")
  expect_identical(keys, c("435*00", "436*00"))
  # An exact name wins over a part: "Diebstahl" is the alias of theft, total
  expect_identical(pksR:::resolve_offences("Diebstahl", map), "****00")
  expect_error(pksR:::resolve_offences("nothing like this", map), "No offence matches")
  expect_error(pksR:::resolve_offences(NA_character_, map), "character vector")
})

test_that("a release without alias columns gets the aliases of the snapshot", {
  old <- map[, setdiff(names(map), c("alias_en", "alias_de"))]
  expect_identical(suppressMessages(pksR:::resolve_offences("residential_burglary", old)), "435*00")
})

test_that("every key has one alias per language, unique and in ASCII", {
  for (col in c("alias_en", "alias_de")) {
    expect_false(anyNA(map[[col]]))
    expect_false(anyDuplicated(map[[col]]) > 0)
    expect_true(all(grepl("^[a-z0-9_]+$", map[[col]])))
  }
})

test_that("pks_get() selects by name, and published keys follow the harmonized key", {
  local_fake_release()
  d <- pks_get(years = 2019:2021, offence = c("total", "wohnungseinbruch"))
  expect_setequal(unique(d$offence_key), c("------", "435*00"))
  p <- pks_get(years = 2019:2021, offence = "residential_burglary", harmonize_to = NULL)
  expect_identical(unique(p$offence_key), "435*00")
  expect_setequal(unique(p$year), 2019:2021)
})

test_that("pks_offences() searches keys, names and labels of both languages", {
  expect_identical(pks_offences("burglary", lang = "en")$offence_key, c("435*00", "436*00"))
  de <- pks_offences("Einbruch", lang = "de")
  expect_true(all(c("435*00", "436*00") %in% de$offence_key))
  expect_identical(pks_offences("435*00", lang = "de")$name, "wohnungseinbruch")
  expect_true("name" %in% names(pks_offences()))
})
