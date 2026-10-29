# Error branches and edge cases of the internal helpers: crosswalk, offence
# map, harmonization in the session, schema, language and release index.

# A small crosswalk: 2019 to 2020 merges 01002 into 01001 and splits 03001
# into 03001 (70 percent of the population) and 03002; 2020 to 2021 keeps
# every district.
toy_crosswalk <- function() {
  row <- function(period, from, to, wp, wa = wp, source = "bbsr") {
    tibble::tibble(
      id = paste(source, period, from, to, sep = "-"), period = as.integer(period),
      from_ags = from, from_name = paste("Kreis", from), to_ags = to, to_name = paste("Kreis", to),
      weight_population = wp, weight_area = wa, source = source, replaces = NA_character_,
      status = "official", reason = NA_character_
    )
  }
  dplyr::bind_rows(
    row(2019, "01001", "01001", 1), row(2019, "01002", "01001", 1),
    row(2019, "03001", "03001", 0.7, 0.6), row(2019, "03001", "03002", 0.3, 0.4),
    row(2019, "11000", "11000", 1),
    row(2020, "01001", "01001", 1), row(2020, "03001", "03001", 1),
    row(2020, "03002", "03002", 1), row(2020, "11000", "11000", 1)
  )
}

# One year as published on the 2019 boundary, total offences only.
toy_published <- function(year = 2019L, keys = "------") {
  codes <- c("01001", "01002", "03001", "11000")
  pop <- c(90000, 30000, 200000, 3600000)
  grid <- expand.grid(i = seq_along(codes), key = keys, stringsAsFactors = FALSE)
  d <- tibble::tibble(
    year = as.integer(year), ags = codes[grid$i], region_name = paste("Kreis", codes[grid$i]),
    offence_key = grid$key, offence_label = "Straftaten insgesamt",
    cases = c(100L, 50L, 200L, 300L)[grid$i], attempts = 1L, hz = NA_real_, cleared = 10L,
    clearance_rate = NA_real_, suspects = 5L, cases_derived = NA_real_, cleared_derived = NA_real_,
    population = NA_real_, source_format = "xlsx", source_file = "toy.xlsx", boundary_year = 2019L,
    harmonized = FALSE, weight_type = "none", estimated = FALSE,
    derived_population = pop[grid$i], population_corrected = 0.98 * pop[grid$i]
  )
  d$hz <- d$cases / d$derived_population * 1e5
  d$clearance_rate <- d$cleared / d$cases * 100
  d[names(canonical_spec)]
}

test_that("broken crosswalks are refused", {
  path <- withr::local_tempfile(fileext = ".csv")
  readr::write_csv(toy_crosswalk()[, -1], path)
  expect_error(read_boundary_map(path), "lacks columns")

  m <- toy_crosswalk()
  m$weight_population[1] <- 0.5
  expect_error(assert_boundary_map(m), "does not sum to 1")
  gap <- toy_crosswalk()
  gap$period[gap$period == 2020] <- 2022L
  expect_error(assert_boundary_map(gap), "have gaps")
  broken <- toy_crosswalk()
  broken <- broken[!(broken$period == 2020 & broken$from_ags == "03002"), ]
  expect_error(assert_boundary_map(broken), "do not chain")

  # A Destatis transfer needs an own row of the giving district
  extra <- toy_crosswalk()[1, ]
  extra$source <- "destatis"
  extra$from_ags <- "09999"
  expect_error(effective_boundary_map(dplyr::bind_rows(toy_crosswalk(), extra)), "no own row")
})

test_that("boundary codes, names and composed crosswalks follow the periods", {
  m <- toy_crosswalk()
  expect_identical(boundary_codes(m, 2019), c("01001", "01002", "03001", "11000"))
  # The last boundary comes from the targets of the last period
  expect_identical(boundary_codes(m, 2021), c("01001", "03001", "03002", "11000"))
  expect_error(boundary_codes(m, 2030), "does not cover")
  # 01001 and 01002 both point at 01001 in 2019; two names for it fail
  twice <- m[m$period == 2019, ]
  twice$to_name[twice$from_ags == "01002"] <- "Another name"
  expect_error(boundary_names(twice, 2020), "several names")

  cw <- compose_crosswalk(m, 2019, 2021, "area")
  expect_equal(cw$weight[cw$from_ags == "03001" & cw$to_ags == "03002"], 0.4)
  expect_error(compose_crosswalk(m, 2021, 2019), "Only forward")
  expect_error(compose_crosswalk(m[m$period == 2019, ], 2019, 2021), "no period 2020-2021")
})

test_that("harmonization in the session refuses inconsistent data", {
  m <- toy_crosswalk()
  d <- toy_published(keys = c("------", "220000"))
  d$population[d$ags == "01001" & d$offence_key == "220000"] <- 1
  expect_error(district_population(d), "published population differs")
  d <- toy_published(keys = c("------", "220000"))
  d$population_corrected[d$ags == "01001" & d$offence_key == "220000"] <- 1
  expect_error(district_population(d), "corrected population differs")

  two <- toy_published()
  two$boundary_year[1] <- 2020L
  expect_error(harmonize_space(two, m, 2021), "one boundary year")

  # Unknown codes are reported and their rows counted, never dropped silently
  unknown <- dplyr::bind_rows(toy_published(), transform(toy_published()[1, ], ags = "09999"))
  expect_warning(expect_message(h <- harmonize_space(unknown, m, 2021), "Removed 1 row"), "not in the crosswalk")
  expect_false("09999" %in% h$ags)

  before <- toy_published()
  after <- harmonize_space(before, m, 2021)
  expect_true(check_conservation(before, after))
  changed <- after
  changed$cases[1] <- changed$cases[1] + 1
  expect_error(check_conservation(before, changed), "changed national totals")
  other_key <- after
  other_key$offence_key <- "220000"
  expect_error(check_conservation(before, other_key), "offence keys differ")
  moved <- after
  moved$population_corrected <- moved$population_corrected * 2
  expect_error(check_conservation(before, moved), "changed national totals")
})

test_that("the offence map is read strictly and computed keys are built", {
  path <- withr::local_tempfile(fileext = ".csv")
  readr::write_csv(data.frame(offence_key_harmonized = "------"), path)
  expect_error(read_offence_map(path), "lacks columns")

  map <- tibble::tibble(
    offence_key_harmonized = c("------", "725000", "890000"), label_de = c("Insgesamt", "Ausl", "Ohne"),
    label_en = c("Total", "Imm", "Excl"), parent_key = NA_character_, valid_from = "2019", valid_to = "2019",
    source_keys = c("------@2019", "725000@2019", "------ minus 725000@2019"), status = "reviewed", notes = NA_character_
  )
  expect_error(offence_spec(transform(map, source_keys = "------")), "lacks @YEARS")
  expect_error(offence_spec(transform(map, source_keys = "a minus b minus c@2019")), "KEY or KEY minus KEY")

  d <- harmonize_space(toy_published(keys = c("------", "725000")), toy_crosswalk(), 2021)
  d$suspects <- 5
  h <- harmonize_offences(d, map)
  total <- h[h$offence_key == "------", ]
  imm <- h[h$offence_key == "725000", ]
  excl <- h[h$offence_key == "890000", ]
  expect_equal(excl$cases, total$cases - imm$cases)
  expect_true(all(is.na(excl$suspects)))
  expect_identical(unique(excl$offence_key_published), "------ minus 725000")
  expect_identical(unique(excl$offence_label), "Ohne")

  expect_error(harmonize_offences(d[d$offence_key == "------", ], map), "expects key")
  other <- d
  other$offence_key[other$offence_key == "725000"] <- "111000"
  expect_error(harmonize_offences(other, map), "not in the offence map")
  expect_message(published_rows(toy_published(), "890000", map), "only computed when harmonizing")
})

test_that("harmonizing in the session checks the target boundary", {
  m <- toy_crosswalk()
  map <- tibble::tibble(
    offence_key_harmonized = "------", label_de = "Insgesamt", label_en = "Total", parent_key = NA_character_,
    valid_from = "2019", valid_to = "2020", source_keys = "------@2019-2020", status = "reviewed", notes = NA_character_
  )
  expect_error(harmonize_published(toy_published(), m, map, 2030, "population"), "can harmonize to boundary years")
  later <- toy_published()
  later$boundary_year <- 2021L
  expect_error(harmonize_published(later, m, map, 2020, "population"), "Only forward harmonization")
})

test_that("release files with other columns or types are refused", {
  path <- withr::local_tempfile(fileext = ".csv")
  readr::write_csv(data.frame(year = 2020, extra = 1), path)
  expect_error(read_release_csv(path, canonical_spec), "expected columns")
  d <- as_harmonized(data.frame(year = 2020L, ags = "01001"))
  expect_identical(names(d), names(harmonized_spec))
  expect_true(is.na(d$population_corrected))
  expect_invisible(assert_schema(d, harmonized_spec, "harmonized"))
  expect_error(assert_schema(d[, 1:3], harmonized_spec, "harmonized"), "Columns differ")
  d$cases <- as.character(d$cases)
  expect_error(assert_schema(d, harmonized_spec, "harmonized"), "Wrong column types")
})

test_that("helpers report lost rows and bad year ranges", {
  expect_message(log_rows_removed(5, 3, "test"), "Removed 2 rows")
  expect_silent(log_rows_removed(5, 5, "test"))
  x <- data.frame(k = c("a", "b"))
  expect_error(join_checked(x, data.frame(k = "a", v = 1), by = "k", what = "test"), "loses 1 row")
  expect_identical(parse_years("2003-2005,2010"), c(2003L, 2004L, 2005L, 2010L))
  expect_error(parse_years("2003-2004-2005"), "Invalid year range")
  expect_error(suppressWarnings(parse_years("x")), "Invalid year range")
})

test_that("the session language follows LANGUAGE and falls back to the text", {
  withr::local_options(pksR.lang = NULL)
  withr::local_envvar(LANGUAGE = "de_DE")
  expect_identical(pks_lang(), "de")
  expect_identical(tr("A text without translation"), "A text without translation")
  withr::local_envvar(LANGUAGE = "fr")
  expect_identical(pks_lang(), "en")
  expect_identical(N_("kept"), "kept")
  po <- withr::local_tempfile(fileext = ".po")
  writeLines(c('msgid "a"', 'msgid "b"'), po)
  expect_error(read_po(po), "every msgid needs a msgstr")
})

test_that("pks_get checks its cache argument and the validation needs a data frame", {
  expect_error(pks_get(cache = NA), "must be")
  expect_error(pks_validate(list()), "must be a data frame")
  # Panels without the columns a check needs fail that check, never crash
  v <- suppressMessages(pks_validate(data.frame(x = 1)))
  expect_true(all(c("uniqueness", "city_states", "population") %in% v$check))
  expect_identical(v$status[v$check == "population"], "warn")
  expect_identical(v$status[v$check == "uniqueness"], "fail")
})

test_that("the release index pages, uses a token and falls back to the cache", {
  log <- local_fake_release()
  withr::local_envvar(GITHUB_PAT = "test-token")
  seen <- new.env()
  httr2::local_mocked_responses(function(req) {
    seen$auth <- req$headers$Authorization
    page <- as.integer(sub(".*page=([0-9]+).*", "\\1", req$url))
    tags <- if (page == 1) sprintf("v2026.%d", seq_len(100)) else "v2025.1"
    httr2::response_json(body = lapply(tags, function(t) list(tag_name = t, draft = FALSE, prerelease = FALSE,
      published_at = "2026-10-28T12:00:00Z", html_url = "u", assets = list())))
  })
  index <- release_index(refresh = TRUE)
  expect_identical(nrow(index), 101L)
  expect_false(is.null(seen$auth))

  # No published release at all
  rm(list = ls(pksR:::the), envir = pksR:::the)
  httr2::local_mocked_responses(function(req) httr2::response_json(body = list()))
  expect_error(resolve_version("latest"), "no published data release")
})

test_that("offline, a cached version is used and a wrong manifest is removed", {
  local_fake_release()
  suppressMessages(pks_get(years = 2019, offence = "total"))
  rm(list = ls(pksR:::the), envir = pksR:::the)
  httr2::local_mocked_responses(function(req) stop("Could not resolve host (offline test)"))
  expect_identical(resolve_version("2026.1"), "2026.1")
  expect_error(resolve_version("2025.1"), "not cached")

  path <- file.path(cache_dir("2026.1"), "manifest.json")
  m <- jsonlite::read_json(path)
  m$data_version <- "2025.9"
  jsonlite::write_json(m, path, auto_unbox = TRUE)
  expect_error(read_manifest("2026.1"), "names version")
  expect_false(file.exists(path))
  expect_error(release_file("2026.1", "missing.csv", list(files = list())), "has no file")
  expect_true(is.na(retrieved_at("2026.1", "never-downloaded.csv", cache = TRUE)))
})

test_that("the last uncovered branches behave", {
  # Without LANGUAGE the collation locale decides
  withr::local_options(pksR.lang = NULL)
  withr::local_envvar(LANGUAGE = "")
  expect_true(pks_lang() %in% c("de", "en"))
  # The question wrapper asks utils::askYesNo()
  local_mocked_bindings(askYesNo = function(question) TRUE, .package = "utils")
  expect_true(ask_yes_no("Delete?"))
  # A computed key needs the subtracted key in every district
  spec_row <- tibble::tibble(offence_key_harmonized = "890000", year = 2019L, plus_key = "------", minus_key = "725000")
  d <- toy_published(keys = c("------", "725000"))
  d <- d[!(d$offence_key == "725000" & d$ags == "01001"), ]
  expect_error(difference_rows(d, spec_row, tibble::tibble()), "missing for some districts")
})
